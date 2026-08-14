import 'package:flutter_test/flutter_test.dart';
import 'package:reservation_reminder/domain/models/enums.dart';
import 'package:reservation_reminder/domain/models/recurrence.dart';
import 'package:reservation_reminder/domain/services/recurrence_generator.dart';

void main() {
  const gen = RecurrenceGenerator();

  test('N일마다: 09/01~10/01, 7일마다 (계획서 9.1 예시)', () {
    final dates = gen.generate(RecurrenceSpec(
      mode: RecurrenceMode.everyNDays,
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 10, 1),
      intervalDays: 7,
    ));
    expect(dates, [
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 8),
      DateTime(2026, 9, 15),
      DateTime(2026, 9, 22),
      DateTime(2026, 9, 29),
    ]);
  });

  test('특정 요일: 09/01~10/01, 월·수', () {
    final dates = gen.generate(RecurrenceSpec(
      mode: RecurrenceMode.weekdays,
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 10, 1),
      weekdays: const {DateTime.monday, DateTime.wednesday},
    ));
    // 2026-09-01 은 화요일. 첫 월요일은 09-07.
    expect(dates.first, DateTime(2026, 9, 2)); // 수
    expect(dates.contains(DateTime(2026, 9, 7)), isTrue); // 월
    expect(dates.every((d) =>
        d.weekday == DateTime.monday || d.weekday == DateTime.wednesday), isTrue);
  });

  test('종료일이 시작일보다 빠르면 예외', () {
    expect(
      () => gen.generate(RecurrenceSpec(
        mode: RecurrenceMode.everyNDays,
        start: DateTime(2026, 9, 10),
        end: DateTime(2026, 9, 1),
      )),
      throwsArgumentError,
    );
  });

  test('요일 미선택이면 예외', () {
    expect(
      () => gen.generate(RecurrenceSpec(
        mode: RecurrenceMode.weekdays,
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 10, 1),
        weekdays: const {},
      )),
      throwsArgumentError,
    );
  });
}
