import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/rules.dart';

part 'rule_dao.g.dart';

@DriftAccessor(tables: [Rules])
class RuleDao extends DatabaseAccessor<AppDatabase> with _$RuleDaoMixin {
  RuleDao(super.db);

  Future<List<Rule>> getForFacility(int facilityId) =>
      (select(rules)
            ..where((r) => r.facilityId.equals(facilityId))
            ..orderBy([(r) => OrderingTerm(expression: r.offset)]))
          .get();

  /// 규칙 적용 시에는 활성 규칙만 조회한다.
  Future<List<Rule>> getEnabledForFacility(int facilityId) =>
      (select(rules)
            ..where((r) =>
                r.facilityId.equals(facilityId) & r.enabled.equals(true))
            ..orderBy([(r) => OrderingTerm(expression: r.offset)]))
          .get();

  Stream<List<Rule>> watchForFacility(int facilityId) =>
      (select(rules)
            ..where((r) => r.facilityId.equals(facilityId))
            ..orderBy([(r) => OrderingTerm(expression: r.offset)]))
          .watch();

  Future<int> insertRule(RulesCompanion entry) => into(rules).insert(entry);

  Future<bool> updateRule(Rule entry) => update(rules).replace(entry);

  Future<int> deleteRule(int id) =>
      (delete(rules)..where((r) => r.id.equals(id))).go();
}
