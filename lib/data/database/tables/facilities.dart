import 'package:drift/drift.dart';

/// 시설 테이블.
class Facilities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// ARGB int 색상.
  IntColumn get color => integer()();

  /// 비활성 시설은 신규 등록 선택 불가, 기존 데이터는 유지.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
