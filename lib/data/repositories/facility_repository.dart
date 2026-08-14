import 'package:drift/drift.dart';

import '../../domain/models/facility.dart';
import '../database/database.dart' as db;
import 'mappers.dart';

/// 시설 저장소.
class FacilityRepository {
  FacilityRepository(this._dao);

  final db.FacilityDao _dao;

  Future<List<Facility>> getAll() async =>
      (await _dao.getAll()).map(Mappers.facility).toList();

  Future<List<Facility>> getEnabled() async =>
      (await _dao.getEnabled()).map(Mappers.facility).toList();

  Stream<List<Facility>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(Mappers.facility).toList());

  Future<Facility?> findById(int id) async {
    final row = await _dao.findById(id);
    return row == null ? null : Mappers.facility(row);
  }

  Future<int> create({required String name, required int color}) {
    final now = DateTime.now();
    return _dao.insertFacility(
      db.FacilitiesCompanion.insert(
        name: name,
        color: color,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update(Facility facility) =>
      _dao.updateFacility(Mappers.facilityRow(facility));

  /// 비활성화(삭제 대신). 기존 데이터 유지(계획서 4.2).
  Future<void> setEnabled(int id, bool enabled) =>
      _dao.setEnabled(id, enabled);
}
