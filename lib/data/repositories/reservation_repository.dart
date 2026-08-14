import 'package:drift/drift.dart';

import '../../domain/models/reservation.dart';
import '../../domain/models/schedule.dart';
import '../../domain/models/schedule_spec.dart';
import '../database/database.dart' as db;
import 'mappers.dart';

/// 사용 일정 + 스케줄 저장소. 두 테이블을 함께 다루므로 트랜잭션을 관리한다.
class ReservationRepository {
  ReservationRepository(this._db, this._reservationDao, this._scheduleDao);

  final db.AppDatabase _db;
  final db.ReservationDao _reservationDao;
  final db.ScheduleDao _scheduleDao;

  Future<List<Reservation>> getAll() async =>
      (await _reservationDao.getAll()).map(Mappers.reservation).toList();

  Future<Reservation?> findById(int id) async {
    final row = await _reservationDao.findById(id);
    return row == null ? null : Mappers.reservation(row);
  }

  Future<List<Reservation>> getForFacility(int facilityId) async =>
      (await _reservationDao.getForFacility(facilityId))
          .map(Mappers.reservation)
          .toList();

  Stream<List<Reservation>> watchForMonth(int year, int month) => _reservationDao
      .watchForMonth(year, month)
      .map((rows) => rows.map(Mappers.reservation).toList());

  Future<List<Schedule>> schedulesFor(int reservationId) async =>
      (await _scheduleDao.getForReservation(reservationId))
          .map(Mappers.schedule)
          .toList();

  /// 사용 일정과 그 스케줄들을 한 트랜잭션으로 저장한다.
  /// 저장된 Schedule(신규 id 포함) 목록을 돌려준다.
  Future<CreatedReservation> createWithSchedules({
    required int facilityId,
    required DateTime usageDate,
    required String? batchId,
    required List<ScheduleSpec> specs,
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now();
      final reservationId = await _reservationDao.insertReservation(
        db.ReservationsCompanion(
          facilityId: Value(facilityId),
          usageDate: Value(usageDate),
          batchId: Value(batchId),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final schedules = <Schedule>[];
      for (final spec in specs) {
        final id = await _scheduleDao.insertSchedule(
          db.SchedulesCompanion(
            reservationId: Value(reservationId),
            title: Value(spec.title),
            date: Value(spec.date),
            source: Value(spec.source.name),
            notificationEnabled: Value(spec.notificationEnabled),
            notificationId: const Value(null),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        final row = await _scheduleDao.findById(id);
        if (row != null) schedules.add(Mappers.schedule(row));
      }

      final reservation =
          Mappers.reservation((await _reservationDao.findById(reservationId))!);
      return CreatedReservation(reservation: reservation, schedules: schedules);
    });
  }

  Future<Schedule> addCustomSchedule(
    int reservationId,
    ScheduleSpec spec,
  ) async {
    final now = DateTime.now();
    final id = await _scheduleDao.insertSchedule(
      db.SchedulesCompanion(
        reservationId: Value(reservationId),
        title: Value(spec.title),
        date: Value(spec.date),
        source: Value(spec.source.name),
        notificationEnabled: Value(spec.notificationEnabled),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return Mappers.schedule((await _scheduleDao.findById(id))!);
  }

  Future<void> updateSchedule(Schedule schedule) =>
      _scheduleDao.updateSchedule(Mappers.scheduleRow(schedule));

  Future<void> setNotificationId(int scheduleId, int? notificationId) =>
      _scheduleDao.setNotificationId(scheduleId, notificationId);

  /// 예약 삭제. 연결 Schedule 은 FK cascade 로 함께 삭제된다.
  Future<void> delete(int reservationId) =>
      _reservationDao.deleteById(reservationId);

  /// 반복 그룹 전체 삭제(계획서 13장).
  Future<void> deleteBatch(String batchId) =>
      _reservationDao.deleteByBatch(batchId);

  Future<List<Reservation>> getByBatch(String batchId) async =>
      (await _reservationDao.getByBatch(batchId))
          .map(Mappers.reservation)
          .toList();

  /// 앱 시작 시 알림 동기화용: 미래 + 알림 활성 스케줄.
  Future<List<Schedule>> futureNotifiable(DateTime now) async =>
      (await _scheduleDao.getFutureNotifiable(now))
          .map(Mappers.schedule)
          .toList();

  Future<List<Schedule>> allSchedules() async =>
      (await _scheduleDao.getAll()).map(Mappers.schedule).toList();
}

/// createWithSchedules 결과.
class CreatedReservation {
  const CreatedReservation({
    required this.reservation,
    required this.schedules,
  });

  final Reservation reservation;
  final List<Schedule> schedules;
}
