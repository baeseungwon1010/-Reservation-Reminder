import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import 'daos/facility_dao.dart';
import 'daos/reservation_dao.dart';
import 'daos/rule_dao.dart';
import 'daos/schedule_dao.dart';
import 'tables/facilities.dart';
import 'tables/reservations.dart';
import 'tables/rules.dart';
import 'tables/schedules.dart';

// 저장소에서 `database.dart as db` 로 접근할 때 DAO 타입도 함께 보이도록 재노출.
// (export 지시자는 part 지시자보다 앞에 와야 한다.)
export 'daos/facility_dao.dart';
export 'daos/rule_dao.dart';
export 'daos/reservation_dao.dart';
export 'daos/schedule_dao.dart';

part 'database.g.dart';

/// 앱 로컬 데이터베이스(SQLite + Drift). 서버 없음, local-first.
@DriftDatabase(
  tables: [Facilities, Rules, Reservations, Schedules],
  daos: [FacilityDao, RuleDao, ReservationDao, ScheduleDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 테스트에서 인메모리 DB 를 주입하기 위한 생성자.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaults();
        },
        beforeOpen: (details) async {
          // 외래키 제약 활성화(참조 무결성 + cascade 삭제).
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (m, from, to) async {
          // v2: 기본으로 넣었던 "예약 확인" 규칙/스케줄을 정리한다.
          // (예전 설치본에 남아있는 잔재 제거. 규칙에서 생성된 것만 삭제)
          if (from < 2) {
            await (delete(rules)..where((r) => r.title.equals('예약 확인')))
                .go();
            await (delete(schedules)
                  ..where((s) =>
                      s.title.equals('예약 확인') & s.source.equals('rule')))
                .go();
            // 삭제된 스케줄의 OS 알림은 앱 시작 시 동기화에서 자동 취소된다.
          }
        },
      );

  /// 최초 설치 시 기본 시설/규칙을 생성한다(계획서 4.1).
  /// 실제 일수/내용은 실제 예약 규칙에 맞게 조정한다.
  Future<void> _seedDefaults() async {
    final now = DateTime.now();

    final auditoriumId = await into(facilities).insert(
      FacilitiesCompanion.insert(
        name: AppConstants.defaultAuditoriumName,
        color: AppConstants.defaultAuditoriumColor,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await into(rules).insert(
      RulesCompanion.insert(
        facilityId: auditoriumId,
        title: AppConstants.defaultReservationRuleTitle,
        offset: 7,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final classroomId = await into(facilities).insert(
      FacilitiesCompanion.insert(
        name: AppConstants.defaultClassroomName,
        color: AppConstants.defaultClassroomColor,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await into(rules).insert(
      RulesCompanion.insert(
        facilityId: classroomId,
        title: AppConstants.defaultReservationRuleTitle,
        offset: 3,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'reservation_reminder.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
