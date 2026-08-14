import 'package:flutter/foundation.dart';

import 'enums.dart';

/// 반복 생성 요청. 영구 객체가 아니라 여러 개의 독립 Reservation 을
/// 한 번에 만들기 위한 입력이다(계획서 9장).
@immutable
class RecurrenceSpec {
  const RecurrenceSpec({
    required this.mode,
    required this.start,
    required this.end,
    this.intervalDays = 7,
    this.weekdays = const <int>{},
  });

  final RecurrenceMode mode;
  final DateTime start;
  final DateTime end;

  /// everyNDays 모드에서 사용. 1 이상.
  final int intervalDays;

  /// weekdays 모드에서 사용. DateTime.monday(1)~DateTime.sunday(7).
  final Set<int> weekdays;

  String? validate() {
    if (end.isBefore(start)) return '종료일이 시작일보다 빠릅니다.';
    if (mode == RecurrenceMode.everyNDays && intervalDays < 1) {
      return '반복 간격은 1일 이상이어야 합니다.';
    }
    if (mode == RecurrenceMode.weekdays && weekdays.isEmpty) {
      return '요일을 하나 이상 선택하세요.';
    }
    return null;
  }
}
