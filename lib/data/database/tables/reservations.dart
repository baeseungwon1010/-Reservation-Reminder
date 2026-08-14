import 'package:drift/drift.dart';

import 'facilities.dart';

/// 사용 일정 테이블.
class Reservations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get facilityId =>
      integer().references(Facilities, #id, onDelete: KeyAction.restrict)();

  /// 사용 날짜(자정 정규화 저장).
  DateTimeColumn get usageDate => dateTime()();

  /// 반복 생성 그룹 식별자. 단일 일정은 null.
  TextColumn get batchId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
