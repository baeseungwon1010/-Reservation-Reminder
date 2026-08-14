import 'package:flutter_test/flutter_test.dart';
import 'package:reservation_reminder/domain/models/enums.dart';
import 'package:reservation_reminder/domain/models/rule.dart';
import 'package:reservation_reminder/domain/services/rule_engine.dart';

Rule _rule({
  required String title,
  required int offset,
  bool enabled = true,
}) {
  final now = DateTime(2026, 1, 1);
  return Rule(
    id: offset,
    facilityId: 1,
    title: title,
    type: RuleType.relativeDays,
    offset: offset,
    enabled: enabled,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  const engine = RuleEngine();

  test('강당 규칙 예: 사용일 09/20 → 09/13 예약, 09/17 예약 확인', () {
    final specs = engine.generate(
      usageDate: DateTime(2026, 9, 20),
      rules: [
        _rule(title: '예약', offset: 7),
        _rule(title: '예약 확인', offset: 3),
      ],
    );

    expect(specs.length, 2);
    // 날짜 오름차순 정렬.
    expect(specs[0].date, DateTime(2026, 9, 13));
    expect(specs[0].title, '예약');
    expect(specs[1].date, DateTime(2026, 9, 17));
    expect(specs[1].title, '예약 확인');
    // 자정 고정.
    expect(specs[0].date.hour, 0);
    expect(specs[0].date.minute, 0);
    // 규칙 스케줄은 알림 기본 활성.
    expect(specs.every((s) => s.notificationEnabled), isTrue);
    expect(specs.every((s) => s.source == ScheduleSource.rule), isTrue);
  });

  test('비활성 규칙은 제외된다', () {
    final specs = engine.generate(
      usageDate: DateTime(2026, 9, 20),
      rules: [
        _rule(title: '예약', offset: 7),
        _rule(title: '비활성', offset: 1, enabled: false),
      ],
    );
    expect(specs.length, 1);
    expect(specs.single.title, '예약');
  });

  test('규칙이 없으면 빈 목록', () {
    expect(engine.generate(usageDate: DateTime(2026, 9, 20), rules: []),
        isEmpty);
  });
}
