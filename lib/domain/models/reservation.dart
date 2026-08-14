import 'package:flutter/foundation.dart';

/// 사용 일정. "시설 X를 언제 사용한다"는 원본 정보.
/// 실제 예약해야 하는 스케줄(Schedule)과는 분리된다(계획서 6장).
@immutable
class Reservation {
  const Reservation({
    required this.id,
    required this.facilityId,
    required this.usageDate,
    required this.batchId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int facilityId;

  /// 사용 날짜(시각 무시, 자정 정규화 저장).
  final DateTime usageDate;

  /// 반복 생성으로 묶인 그룹 식별자. 단일 일정은 null(계획서 9.3).
  final String? batchId;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRecurring => batchId != null;

  Reservation copyWith({
    int? facilityId,
    DateTime? usageDate,
    String? batchId,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id,
      facilityId: facilityId ?? this.facilityId,
      usageDate: usageDate ?? this.usageDate,
      batchId: batchId ?? this.batchId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
