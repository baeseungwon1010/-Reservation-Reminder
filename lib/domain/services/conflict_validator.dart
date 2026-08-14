import '../../core/utils/date_utils.dart';
import '../models/reservation.dart';

/// 일정 충돌 검사(계획서 12장).
///
/// 동일 시설에 같은 사용 날짜가 이미 존재하면 충돌로 본다.
/// UI뿐 아니라 저장 직전 서비스/도메인 계층에서도 이 검증을 수행한다.
class ConflictValidator {
  const ConflictValidator();

  /// 단일 사용일이 기존 예약과 충돌하는지 검사.
  ///
  /// [existing] 은 저장소에서 조회한 같은 시설(또는 전체)의 예약 목록.
  /// [ignoreReservationId] 는 수정 시 자기 자신을 제외하기 위한 값.
  ConflictResult check({
    required int facilityId,
    required DateTime usageDate,
    required List<Reservation> existing,
    int? ignoreReservationId,
  }) {
    final conflicts = existing.where((r) {
      if (r.id == ignoreReservationId) return false;
      if (r.facilityId != facilityId) return false;
      return AppDate.isSameDate(r.usageDate, usageDate);
    }).toList();

    return ConflictResult(
      usageDate: AppDate.dateOnly(usageDate),
      conflicts: conflicts,
    );
  }

  /// 반복 생성 시 여러 사용일을 한꺼번에 검사(계획서 12장 마지막 문단).
  List<ConflictResult> checkMany({
    required int facilityId,
    required List<DateTime> usageDates,
    required List<Reservation> existing,
  }) {
    return usageDates
        .map((d) => check(
              facilityId: facilityId,
              usageDate: d,
              existing: existing,
            ))
        .where((r) => r.hasConflict)
        .toList();
  }
}

class ConflictResult {
  const ConflictResult({
    required this.usageDate,
    required this.conflicts,
  });

  final DateTime usageDate;
  final List<Reservation> conflicts;

  bool get hasConflict => conflicts.isNotEmpty;
}
