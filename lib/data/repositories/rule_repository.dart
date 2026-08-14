import 'package:drift/drift.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/rule.dart';
import '../database/database.dart' as db;
import 'mappers.dart';

/// 예약 규칙 저장소.
class RuleRepository {
  RuleRepository(this._dao);

  final db.RuleDao _dao;

  Future<List<Rule>> getForFacility(int facilityId) async =>
      (await _dao.getForFacility(facilityId)).map(Mappers.rule).toList();

  /// 규칙 적용 시 활성 규칙만.
  Future<List<Rule>> getEnabledForFacility(int facilityId) async =>
      (await _dao.getEnabledForFacility(facilityId))
          .map(Mappers.rule)
          .toList();

  Stream<List<Rule>> watchForFacility(int facilityId) => _dao
      .watchForFacility(facilityId)
      .map((rows) => rows.map(Mappers.rule).toList());

  Future<int> create({
    required int facilityId,
    required String title,
    required int offset,
    RuleType type = RuleType.relativeDays,
  }) {
    final now = DateTime.now();
    return _dao.insertRule(
      db.RulesCompanion(
        facilityId: Value(facilityId),
        title: Value(title),
        type: Value(type.name),
        offset: Value(offset),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> update(Rule rule) => _dao.updateRule(Mappers.ruleRow(rule));

  Future<void> delete(int id) => _dao.deleteRule(id);
}
