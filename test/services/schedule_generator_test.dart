import 'package:flutter_test/flutter_test.dart';
import 'package:reservation_reminder/domain/models/enums.dart';
import 'package:reservation_reminder/domain/models/rule.dart';
import 'package:reservation_reminder/domain/models/schedule_spec.dart';
import 'package:reservation_reminder/domain/services/schedule_generator.dart';

Rule _rule(String title, int offset) {
  final now = DateTime(2026, 1, 1);
  return Rule(
    id: offset,
    facilityId: 1,
    title: title,
    type: RuleType.relativeDays,
    offset: offset,
    enabled: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  const gen = ScheduleGenerator();

  test('규칙 + 사용일 마커 + 사용자 지정 스케줄을 합쳐 날짜순 정렬', () {
    final result = gen.generate(
      usageDate: DateTime(2026, 9, 20),
      rules: [_rule('예약', 7), _rule('예약 확인', 3)],
      now: DateTime(2026, 8, 1), // 모두 미래
      customSpecs: [
        ScheduleSpec(
          title: '준비물 확인',
          date: DateTime(2026, 9, 19, 9),
          source: ScheduleSource.custom,
          notificationEnabled: true,
        ),
      ],
    );

    // 예약(13) < 예약확인(17) < 준비물(19) < 사용(20)
    expect(result.specs.map((s) => s.title).toList(),
        ['예약', '예약 확인', '준비물 확인', '사용']);
    expect(result.hasPast, isFalse);
    // 사용일 마커는 알림 off.
    final usage =
        result.specs.firstWhere((s) => s.source == ScheduleSource.usage);
    expect(usage.notificationEnabled, isFalse);
  });

  test('이미 지난 스케줄은 알림이 강제 비활성화되고 경고에 포함(계획서 11장)', () {
    // 현재 2026-09-15, 사용일 09-20 → 7일전(09/13) 은 지남, 3일전(09/17) 은 예정.
    final result = gen.generate(
      usageDate: DateTime(2026, 9, 20),
      rules: [_rule('예약', 7), _rule('예약 확인', 3)],
      now: DateTime(2026, 9, 15, 10),
    );

    final past = result.specs
        .firstWhere((s) => s.date == DateTime(2026, 9, 13, 22));
    expect(past.notificationEnabled, isFalse); // 지나서 알림 off
    expect(result.hasPast, isTrue);
    expect(result.pastSpecs.length, 1);
    expect(result.pastSpecs.single.title, '예약');

    final upcoming = result.specs
        .firstWhere((s) => s.date == DateTime(2026, 9, 17, 22));
    expect(upcoming.notificationEnabled, isTrue);
  });

  test('includeUsageMarker=false 면 사용일 마커를 만들지 않는다', () {
    final result = gen.generate(
      usageDate: DateTime(2026, 9, 20),
      rules: [_rule('예약', 7)],
      now: DateTime(2026, 8, 1),
      includeUsageMarker: false,
    );
    expect(result.specs.any((s) => s.source == ScheduleSource.usage), isFalse);
  });
}
