import 'package:flutter/foundation.dart';

import 'enums.dart';

/// 저장 전, 규칙/사용자 입력으로부터 계산된 스케줄 명세.
/// Schedule 엔티티(DB 저장 형태)와 달리 id/notificationId 를 갖지 않는다.
@immutable
class ScheduleSpec {
  const ScheduleSpec({
    required this.title,
    required this.date,
    required this.source,
    required this.notificationEnabled,
  });

  final String title;
  final DateTime date;
  final ScheduleSource source;
  final bool notificationEnabled;

  ScheduleSpec copyWith({
    String? title,
    DateTime? date,
    ScheduleSource? source,
    bool? notificationEnabled,
  }) {
    return ScheduleSpec(
      title: title ?? this.title,
      date: date ?? this.date,
      source: source ?? this.source,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}
