import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../data/repositories/facility_repository.dart';
import '../data/repositories/reservation_repository.dart';
import '../data/repositories/rule_repository.dart';
import '../domain/models/facility.dart';
import '../domain/models/reservation.dart';
import '../domain/models/rule.dart';
import '../domain/models/schedule.dart';
import '../notifications/notification_manager.dart';
import 'reservation_service.dart';

/// ---- 인프라 ----

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final notificationManagerProvider = Provider<NotificationManager>((ref) {
  return NotificationManager();
});

/// ---- 저장소 ----

final facilityRepositoryProvider = Provider<FacilityRepository>((ref) {
  return FacilityRepository(ref.watch(databaseProvider).facilityDao);
});

final ruleRepositoryProvider = Provider<RuleRepository>((ref) {
  return RuleRepository(ref.watch(databaseProvider).ruleDao);
});

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ReservationRepository(db, db.reservationDao, db.scheduleDao);
});

/// ---- 서비스 ----

final reservationServiceProvider = Provider<ReservationService>((ref) {
  return ReservationService(
    reservationRepository: ref.watch(reservationRepositoryProvider),
    ruleRepository: ref.watch(ruleRepositoryProvider),
    notificationManager: ref.watch(notificationManagerProvider),
  );
});

/// ---- 앱 시작 초기화 ----
///
/// 알림 초기화/권한 요청 + DB↔OS 알림 동기화(계획서 15장).
final startupProvider = FutureProvider<void>((ref) async {
  final notifications = ref.watch(notificationManagerProvider);
  await notifications.init();
  await notifications.requestPermissions();
  await ref.watch(reservationServiceProvider).syncNotificationsOnStartup();
});

/// ---- 조회 상태 ----

final facilitiesProvider = StreamProvider<List<Facility>>((ref) {
  return ref.watch(facilityRepositoryProvider).watchAll();
});

final enabledFacilitiesProvider = FutureProvider<List<Facility>>((ref) async {
  // 시설 목록이 바뀌면 재계산.
  ref.watch(facilitiesProvider);
  return ref.watch(facilityRepositoryProvider).getEnabled();
});

final rulesForFacilityProvider =
    StreamProvider.family<List<Rule>, int>((ref, facilityId) {
  return ref.watch(ruleRepositoryProvider).watchForFacility(facilityId);
});

/// 현재 달력에 표시 중인 월(1일 기준).
final focusedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// 달력에서 선택된 날짜.
final selectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// 표시 중인 월의 예약 목록.
final monthReservationsProvider =
    StreamProvider<List<Reservation>>((ref) {
  final month = ref.watch(focusedMonthProvider);
  return ref
      .watch(reservationRepositoryProvider)
      .watchForMonth(month.year, month.month);
});

/// 특정 예약의 스케줄 목록.
final schedulesForReservationProvider =
    FutureProvider.family<List<Schedule>, int>((ref, reservationId) {
  return ref.watch(reservationRepositoryProvider).schedulesFor(reservationId);
});

/// 단일 예약 조회.
final reservationByIdProvider =
    FutureProvider.family<Reservation?, int>((ref, id) {
  return ref.watch(reservationRepositoryProvider).findById(id);
});
