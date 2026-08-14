import 'package:drift/drift.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/facility.dart';
import '../../domain/models/reservation.dart';
import '../../domain/models/rule.dart';
import '../../domain/models/schedule.dart';
import '../database/database.dart' as db;

/// Drift 행(row) <-> 도메인 모델 변환.
///
/// Drift 가 생성하는 데이터 클래스(`db.Facility` 등)와 도메인 모델은 이름이 같아
/// 여기서는 database 를 `db.` 접두사로 임포트해 구분한다.
class Mappers {
  Mappers._();

  static Facility facility(db.Facility r) => Facility(
        id: r.id,
        name: r.name,
        color: r.color,
        enabled: r.enabled,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  static db.Facility facilityRow(Facility f) => db.Facility(
        id: f.id,
        name: f.name,
        color: f.color,
        enabled: f.enabled,
        createdAt: f.createdAt,
        updatedAt: f.updatedAt,
      );

  static Rule rule(db.Rule r) => Rule(
        id: r.id,
        facilityId: r.facilityId,
        title: r.title,
        type: RuleType.fromName(r.type),
        offset: r.offset,
        enabled: r.enabled,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  static db.Rule ruleRow(Rule r) => db.Rule(
        id: r.id,
        facilityId: r.facilityId,
        title: r.title,
        type: r.type.name,
        offset: r.offset,
        enabled: r.enabled,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  static Reservation reservation(db.Reservation r) => Reservation(
        id: r.id,
        facilityId: r.facilityId,
        usageDate: r.usageDate,
        batchId: r.batchId,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  static Schedule schedule(db.Schedule r) => Schedule(
        id: r.id,
        reservationId: r.reservationId,
        title: r.title,
        date: r.date,
        source: ScheduleSource.fromName(r.source),
        notificationEnabled: r.notificationEnabled,
        notificationId: r.notificationId,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  static db.Schedule scheduleRow(Schedule s) => db.Schedule(
        id: s.id,
        reservationId: s.reservationId,
        title: s.title,
        date: s.date,
        source: s.source.name,
        notificationEnabled: s.notificationEnabled,
        notificationId: s.notificationId,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
      );

  /// 규칙 생성용 Companion.
  static db.RulesCompanion ruleCompanion(Rule r) => db.RulesCompanion(
        facilityId: Value(r.facilityId),
        title: Value(r.title),
        type: Value(r.type.name),
        offset: Value(r.offset),
        enabled: Value(r.enabled),
        createdAt: Value(r.createdAt),
        updatedAt: Value(r.updatedAt),
      );
}
