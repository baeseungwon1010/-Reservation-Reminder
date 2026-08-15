import 'package:drift/drift.dart';

import '../../../domain/models/calendar_marker.dart';
import '../../../domain/models/enums.dart';
import '../tables/facilities.dart' show Facilities;
import '../database.dart';
import '../tables/reservations.dart';
import '../tables/schedules.dart';

part 'schedule_dao.g.dart';

@DriftAccessor(tables: [Schedules, Reservations, Facilities])
class ScheduleDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduleDaoMixin {
  ScheduleDao(super.db);

  /// 특정 월에 걸치는 모든 스케줄을 시설 색상과 함께 조회한다(달력 마커용, #6).
  /// 예약해야 하는 날짜와 사용일이 함께 포함된다.
  Stream<List<CalendarMarker>> watchMarkersForMonth(int year, int month) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    final query = select(schedules).join([
      innerJoin(
        reservations,
        reservations.id.equalsExp(schedules.reservationId),
      ),
      innerJoin(
        facilities,
        facilities.id.equalsExp(reservations.facilityId),
      ),
    ])
      ..where(schedules.date.isBiggerOrEqualValue(start) &
          schedules.date.isSmallerThanValue(end));

    return query.watch().map((rows) {
      return rows.map((row) {
        final s = row.readTable(schedules);
        final f = row.readTable(facilities);
        return CalendarMarker(
          date: s.date,
          facilityId: f.id,
          facilityColor: f.color,
          source: ScheduleSource.fromName(s.source),
        );
      }).toList();
    });
  }

  Future<List<Schedule>> getForReservation(int reservationId) =>
      (select(schedules)
            ..where((s) => s.reservationId.equals(reservationId))
            ..orderBy([(s) => OrderingTerm(expression: s.date)]))
          .get();

  Future<List<Schedule>> getAll() => select(schedules).get();

  Future<Schedule?> findById(int id) =>
      (select(schedules)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<int> insertSchedule(SchedulesCompanion entry) =>
      into(schedules).insert(entry);

  Future<void> insertMany(List<SchedulesCompanion> entries) async {
    await batch((b) => b.insertAll(schedules, entries));
  }

  Future<bool> updateSchedule(Schedule entry) =>
      update(schedules).replace(entry);

  Future<int> setNotificationId(int scheduleId, int? notificationId) {
    return (update(schedules)..where((s) => s.id.equals(scheduleId))).write(
      SchedulesCompanion(
        notificationId: Value(notificationId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteForReservation(int reservationId) =>
      (delete(schedules)..where((s) => s.reservationId.equals(reservationId)))
          .go();

  /// 앞으로 알림을 걸어야 하는 스케줄(미래 + 알림 활성).
  /// 앱 시작 시 알림 동기화에 사용한다(계획서 15장).
  Future<List<Schedule>> getFutureNotifiable(DateTime now) =>
      (select(schedules)
            ..where((s) =>
                s.notificationEnabled.equals(true) &
                s.date.isBiggerThanValue(now)))
          .get();
}
