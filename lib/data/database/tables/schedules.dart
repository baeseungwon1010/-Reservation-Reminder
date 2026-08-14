import 'package:drift/drift.dart';

import 'reservations.dart';

/// 예약 스케줄 테이블. Reservation 에 종속된다.
class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reservationId =>
      integer().references(Reservations, #id, onDelete: KeyAction.cascade)();

  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// 예약 시점(자동 생성은 자정, 사용자 지정은 임의 시각).
  DateTimeColumn get date => dateTime()();

  /// ScheduleSource.name (rule | custom | usage).
  TextColumn get source => text()();

  BoolColumn get notificationEnabled =>
      boolean().withDefault(const Constant(true))();

  /// OS 로컬 알림 ID. 미등록이면 null.
  IntColumn get notificationId => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
