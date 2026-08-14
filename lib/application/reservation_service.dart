import 'package:uuid/uuid.dart';

import '../core/utils/date_utils.dart';
import '../data/repositories/reservation_repository.dart';
import '../data/repositories/rule_repository.dart';
import '../domain/models/reservation.dart';
import '../domain/models/recurrence.dart';
import '../domain/models/schedule.dart';
import '../domain/models/schedule_spec.dart';
import '../domain/services/conflict_validator.dart';
import '../domain/services/recurrence_generator.dart';
import '../domain/services/schedule_generator.dart';
import '../notifications/notification_manager.dart';

/// 일정 등록/삭제의 핵심 흐름을 조율한다(계획서 20장 아키텍처, 26장 사용 흐름).
///
/// UI → ReservationService → (RuleEngine/ScheduleGenerator/ConflictValidator)
///     → Repository → SQLite → NotificationManager
class ReservationService {
  ReservationService({
    required ReservationRepository reservationRepository,
    required RuleRepository ruleRepository,
    required NotificationManager notificationManager,
    ScheduleGenerator scheduleGenerator = const ScheduleGenerator(),
    ConflictValidator conflictValidator = const ConflictValidator(),
    RecurrenceGenerator recurrenceGenerator = const RecurrenceGenerator(),
    Uuid uuid = const Uuid(),
  })  : _reservations = reservationRepository,
        _rules = ruleRepository,
        _notifications = notificationManager,
        _scheduleGen = scheduleGenerator,
        _conflict = conflictValidator,
        _recurrence = recurrenceGenerator,
        _uuid = uuid;

  final ReservationRepository _reservations;
  final RuleRepository _rules;
  final NotificationManager _notifications;
  final ScheduleGenerator _scheduleGen;
  final ConflictValidator _conflict;
  final RecurrenceGenerator _recurrence;
  final Uuid _uuid;

  /// 단일 일정 등록. 충돌이 있으면 저장하지 않고 충돌 정보를 담아 반환한다.
  Future<CreateResult> createSingle({
    required int facilityId,
    required DateTime usageDate,
    List<ScheduleSpec> customSpecs = const [],
  }) async {
    final now = DateTime.now();
    final day = AppDate.dateOnly(usageDate);

    // 1) 충돌 검사(같은 시설 같은 날짜) — 저장 직전 도메인 계층에서 수행(계획서 12장).
    final existing = await _reservations.getForFacility(facilityId);
    final conflict = _conflict.check(
      facilityId: facilityId,
      usageDate: day,
      existing: existing,
    );
    if (conflict.hasConflict) {
      return CreateResult.blocked([conflict]);
    }

    // 2) 규칙 적용 + 스케줄 생성.
    final rules = await _rules.getEnabledForFacility(facilityId);
    final gen = _scheduleGen.generate(
      usageDate: day,
      rules: rules,
      customSpecs: customSpecs,
      now: now,
    );

    // 3) 저장.
    final created = await _reservations.createWithSchedules(
      facilityId: facilityId,
      usageDate: day,
      batchId: null,
      specs: gen.specs,
    );

    // 4) 미래 스케줄 알림 등록.
    await _registerNotifications(created.schedules);

    return CreateResult.success(
      reservations: [created.reservation],
      pastSpecs: gen.pastSpecs,
    );
  }

  /// 반복 일정 등록. 생성될 각 사용일에 대해 충돌을 검사하고,
  /// 하나라도 충돌하면 전체를 저장하지 않는다(계획서 9·12장).
  Future<CreateResult> createRecurring({
    required int facilityId,
    required RecurrenceSpec spec,
  }) async {
    final now = DateTime.now();
    final usageDates = _recurrence.generate(spec);
    if (usageDates.isEmpty) {
      return CreateResult.empty();
    }

    final existing = await _reservations.getForFacility(facilityId);
    final conflicts = _conflict.checkMany(
      facilityId: facilityId,
      usageDates: usageDates,
      existing: existing,
    );
    if (conflicts.isNotEmpty) {
      return CreateResult.blocked(conflicts);
    }

    final rules = await _rules.getEnabledForFacility(facilityId);
    final batchId = _uuid.v4();
    final createdReservations = <Reservation>[];
    final pastSpecs = <ScheduleSpec>[];

    for (final day in usageDates) {
      final gen = _scheduleGen.generate(
        usageDate: day,
        rules: rules,
        now: now,
      );
      final created = await _reservations.createWithSchedules(
        facilityId: facilityId,
        usageDate: day,
        batchId: batchId,
        specs: gen.specs,
      );
      createdReservations.add(created.reservation);
      pastSpecs.addAll(gen.pastSpecs);
      await _registerNotifications(created.schedules);
    }

    return CreateResult.success(
      reservations: createdReservations,
      pastSpecs: pastSpecs,
      batchId: batchId,
    );
  }

  /// 사용자 지정 추가 스케줄(계획서 8.3).
  Future<void> addCustomSchedule(int reservationId, ScheduleSpec spec) async {
    final schedule = await _reservations.addCustomSchedule(reservationId, spec);
    await _registerNotifications([schedule]);
  }

  /// 스케줄 알림 on/off 토글(계획서 14.2).
  Future<void> setScheduleNotification(Schedule schedule, bool enabled) async {
    final updated = schedule.copyWith(
      notificationEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    await _reservations.updateSchedule(updated);
    if (enabled) {
      await _registerNotifications([updated]);
    } else if (schedule.notificationId != null) {
      await _notifications.cancel(schedule.notificationId!);
      await _reservations.setNotificationId(schedule.id, null);
    }
  }

  /// 단일 일정 삭제: 알림 취소 → 스케줄/예약 삭제(계획서 14.3).
  Future<void> deleteReservation(int reservationId) async {
    final schedules = await _reservations.schedulesFor(reservationId);
    for (final s in schedules) {
      if (s.notificationId != null) {
        await _notifications.cancel(s.notificationId!);
      }
    }
    await _reservations.delete(reservationId);
  }

  /// 반복 그룹 전체 삭제(계획서 13장).
  Future<void> deleteBatch(String batchId) async {
    final reservations = await _reservations.getByBatch(batchId);
    for (final r in reservations) {
      final schedules = await _reservations.schedulesFor(r.id);
      for (final s in schedules) {
        if (s.notificationId != null) {
          await _notifications.cancel(s.notificationId!);
        }
      }
    }
    await _reservations.deleteBatch(batchId);
  }

  /// 앱 시작 시 알림 동기화(계획서 15장).
  Future<void> syncNotificationsOnStartup() async {
    final future = await _reservations.futureNotifiable(DateTime.now());
    await _notifications.sync(future);
  }

  /// 미래 스케줄에 대해 알림을 등록하고 notificationId 를 저장한다.
  Future<void> _registerNotifications(List<Schedule> schedules) async {
    for (final s in schedules) {
      final registered = await _notifications.scheduleFor(s);
      if (registered) {
        // 알림 ID = Schedule.id 를 저장해 이후 취소/동기화에 사용.
        await _reservations.setNotificationId(s.id, s.id);
      }
    }
  }
}

/// 일정 등록 결과.
class CreateResult {
  const CreateResult._({
    required this.status,
    this.reservations = const [],
    this.pastSpecs = const [],
    this.conflicts = const [],
    this.batchId,
  });

  factory CreateResult.success({
    required List<Reservation> reservations,
    List<ScheduleSpec> pastSpecs = const [],
    String? batchId,
  }) =>
      CreateResult._(
        status: CreateStatus.success,
        reservations: reservations,
        pastSpecs: pastSpecs,
        batchId: batchId,
      );

  factory CreateResult.blocked(List<ConflictResult> conflicts) =>
      CreateResult._(status: CreateStatus.conflict, conflicts: conflicts);

  factory CreateResult.empty() =>
      const CreateResult._(status: CreateStatus.empty);

  final CreateStatus status;
  final List<Reservation> reservations;

  /// 이미 지나 알림이 등록되지 않은 스케줄(경고 표시용, 계획서 11.2).
  final List<ScheduleSpec> pastSpecs;

  /// 충돌 목록(차단 시).
  final List<ConflictResult> conflicts;

  final String? batchId;

  bool get isSuccess => status == CreateStatus.success;
  bool get isBlocked => status == CreateStatus.conflict;
  bool get hasPastWarning => pastSpecs.isNotEmpty;
}

enum CreateStatus { success, conflict, empty }
