import 'package:flutter_test/flutter_test.dart';
import 'package:reservation_reminder/domain/models/reservation.dart';
import 'package:reservation_reminder/domain/services/conflict_validator.dart';

Reservation _res({
  required int id,
  required int facilityId,
  required DateTime usageDate,
}) {
  final now = DateTime(2026, 1, 1);
  return Reservation(
    id: id,
    facilityId: facilityId,
    usageDate: usageDate,
    batchId: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  const validator = ConflictValidator();

  test('같은 시설 같은 날짜면 충돌', () {
    final existing = [_res(id: 1, facilityId: 10, usageDate: DateTime(2026, 9, 20))];
    final result = validator.check(
      facilityId: 10,
      usageDate: DateTime(2026, 9, 20, 13),
      existing: existing,
    );
    expect(result.hasConflict, isTrue);
    expect(result.conflicts.single.id, 1);
  });

  test('다른 시설이면 충돌 아님', () {
    final existing = [_res(id: 1, facilityId: 10, usageDate: DateTime(2026, 9, 20))];
    final result = validator.check(
      facilityId: 99,
      usageDate: DateTime(2026, 9, 20),
      existing: existing,
    );
    expect(result.hasConflict, isFalse);
  });

  test('자기 자신은 무시(수정 시나리오)', () {
    final existing = [_res(id: 1, facilityId: 10, usageDate: DateTime(2026, 9, 20))];
    final result = validator.check(
      facilityId: 10,
      usageDate: DateTime(2026, 9, 20),
      existing: existing,
      ignoreReservationId: 1,
    );
    expect(result.hasConflict, isFalse);
  });

  test('checkMany 는 충돌하는 날짜만 반환', () {
    final existing = [
      _res(id: 1, facilityId: 10, usageDate: DateTime(2026, 9, 7)),
      _res(id: 2, facilityId: 10, usageDate: DateTime(2026, 9, 21)),
    ];
    final results = validator.checkMany(
      facilityId: 10,
      usageDates: [
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 14),
        DateTime(2026, 9, 21),
        DateTime(2026, 9, 28),
      ],
      existing: existing,
    );
    expect(results.length, 2);
    expect(results.map((r) => r.usageDate),
        containsAll([DateTime(2026, 9, 7), DateTime(2026, 9, 21)]));
  });
}
