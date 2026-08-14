import 'package:drift/drift.dart';

import 'facilities.dart';

/// 예약 규칙 테이블. 시설에 종속된다.
class Rules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get facilityId =>
      integer().references(Facilities, #id, onDelete: KeyAction.cascade)();

  /// 스케줄 제목으로 쓰이는 규칙명. 예: "예약", "예약 확인".
  TextColumn get title => text().withLength(min: 1, max: 100)();

  /// RuleType.name. 현재는 relativeDays.
  TextColumn get type =>
      text().withDefault(const Constant('relativeDays'))();

  /// 사용일로부터 며칠 전.
  IntColumn get offset => integer()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
