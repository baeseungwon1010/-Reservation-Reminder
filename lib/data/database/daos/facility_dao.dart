import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/facilities.dart';

part 'facility_dao.g.dart';

@DriftAccessor(tables: [Facilities])
class FacilityDao extends DatabaseAccessor<AppDatabase>
    with _$FacilityDaoMixin {
  FacilityDao(super.db);

  Future<List<Facility>> getAll() =>
      (select(facilities)..orderBy([(f) => OrderingTerm(expression: f.id)]))
          .get();

  /// 활성 시설만(신규 일정 등록용).
  Future<List<Facility>> getEnabled() =>
      (select(facilities)..where((f) => f.enabled.equals(true))).get();

  Stream<List<Facility>> watchAll() =>
      (select(facilities)..orderBy([(f) => OrderingTerm(expression: f.id)]))
          .watch();

  Future<Facility?> findById(int id) =>
      (select(facilities)..where((f) => f.id.equals(id))).getSingleOrNull();

  Future<int> insertFacility(FacilitiesCompanion entry) =>
      into(facilities).insert(entry);

  Future<bool> updateFacility(Facility entry) =>
      update(facilities).replace(entry);

  /// 비활성화(삭제 대신). 기존 예약/스케줄/알림은 유지된다(계획서 4.2).
  Future<int> setEnabled(int id, bool enabled) {
    return (update(facilities)..where((f) => f.id.equals(id))).write(
      FacilitiesCompanion(
        enabled: Value(enabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
