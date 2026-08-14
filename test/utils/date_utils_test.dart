import 'package:flutter_test/flutter_test.dart';
import 'package:reservation_reminder/core/utils/date_utils.dart';

void main() {
  group('AppDate', () {
    test('dateOnly strips time', () {
      final d = DateTime(2026, 9, 20, 13, 45);
      expect(AppDate.dateOnly(d), DateTime(2026, 9, 20));
    });

    test('daysBefore computes usage - N days at midnight', () {
      final usage = DateTime(2026, 9, 20, 10);
      expect(AppDate.daysBefore(usage, 7), DateTime(2026, 9, 13));
      expect(AppDate.daysBefore(usage, 3), DateTime(2026, 9, 17));
    });

    test('daysBefore handles month boundary', () {
      final usage = DateTime(2026, 3, 2);
      expect(AppDate.daysBefore(usage, 5), DateTime(2026, 2, 25));
    });

    test('isDateBeforeToday ignores time', () {
      final today = DateTime(2026, 9, 15, 23, 59);
      expect(AppDate.isDateBeforeToday(DateTime(2026, 9, 14), today), isTrue);
      expect(AppDate.isDateBeforeToday(DateTime(2026, 9, 15), today), isFalse);
      expect(AppDate.isDateBeforeToday(DateTime(2026, 9, 16), today), isFalse);
    });

    test('isPastInstant compares exact time', () {
      final now = DateTime(2026, 9, 15, 10);
      expect(AppDate.isPastInstant(DateTime(2026, 9, 15, 9), now), isTrue);
      expect(AppDate.isPastInstant(DateTime(2026, 9, 15, 11), now), isFalse);
    });

    test('eachDay is inclusive of both ends', () {
      final days = AppDate.eachDay(DateTime(2026, 9, 1), DateTime(2026, 9, 3));
      expect(days, [
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 2),
        DateTime(2026, 9, 3),
      ]);
    });
  });
}
