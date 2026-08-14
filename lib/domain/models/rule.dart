import 'package:flutter/foundation.dart';

import 'enums.dart';

/// 시설별 예약 규칙. 예: "7일 전 → 예약", "3일 전 → 예약 확인".
@immutable
class Rule {
  const Rule({
    required this.id,
    required this.facilityId,
    required this.title,
    required this.type,
    required this.offset,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int facilityId;

  /// 규칙 이름(스케줄 제목으로 사용). 예: "예약", "예약 확인".
  final String title;

  final RuleType type;

  /// 사용일로부터 며칠 전인지. relativeDays 규칙에서 사용.
  final int offset;

  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rule copyWith({
    String? title,
    RuleType? type,
    int? offset,
    bool? enabled,
    DateTime? updatedAt,
  }) {
    return Rule(
      id: id,
      facilityId: facilityId,
      title: title ?? this.title,
      type: type ?? this.type,
      offset: offset ?? this.offset,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
