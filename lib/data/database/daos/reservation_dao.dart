import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/reservations.dart';

part 'reservation_dao.g.dart';

@DriftAccessor(tables: [Reservations])
class ReservationDao extends DatabaseAccessor<AppDatabase>
    with _$ReservationDaoMixin {
  ReservationDao(super.db);

  Future<List<Reservation>> getAll() => select(reservations).get();

  Stream<List<Reservation>> watchAll() => select(reservations).watch();

  Future<Reservation?> findById(int id) =>
      (select(reservations)..where((r) => r.id.equals(id)))
          .getSingleOrNull();

  Future<List<Reservation>> getForFacility(int facilityId) =>
      (select(reservations)..where((r) => r.facilityId.equals(facilityId)))
          .get();

  /// 특정 월(1일~말일)에 사용일이 걸치는 예약. 달력 표시용.
  Stream<List<Reservation>> watchForMonth(int year, int month) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return (select(reservations)
          ..where((r) =>
              r.usageDate.isBiggerOrEqualValue(start) &
              r.usageDate.isSmallerThanValue(end))
          ..orderBy([(r) => OrderingTerm(expression: r.usageDate)]))
        .watch();
  }

  Future<List<Reservation>> getByBatch(String batchId) =>
      (select(reservations)..where((r) => r.batchId.equals(batchId))).get();

  Future<int> insertReservation(ReservationsCompanion entry) =>
      into(reservations).insert(entry);

  Future<int> deleteById(int id) =>
      (delete(reservations)..where((r) => r.id.equals(id))).go();

  /// 반복 생성 그룹 전체 삭제. 연결된 Schedule 은 cascade 로 함께 삭제된다.
  Future<int> deleteByBatch(String batchId) =>
      (delete(reservations)..where((r) => r.batchId.equals(batchId))).go();
}
