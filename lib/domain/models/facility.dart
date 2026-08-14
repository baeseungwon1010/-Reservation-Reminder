import 'package:flutter/foundation.dart';

/// 시설. 강당/강의실 등. 각 시설은 독립적인 예약 규칙을 가진다.
@immutable
class Facility {
  const Facility({
    required this.id,
    required this.name,
    required this.color,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;

  /// ARGB int 색상. 달력 표시에 사용(계획서 5.1).
  final int color;

  /// 비활성화된 시설은 신규 일정 등록 시 선택 불가하지만
  /// 기존 데이터는 유지된다(계획서 4.2).
  final bool enabled;

  final DateTime createdAt;
  final DateTime updatedAt;

  Facility copyWith({
    String? name,
    int? color,
    bool? enabled,
    DateTime? updatedAt,
  }) {
    return Facility(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Facility && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);
}
