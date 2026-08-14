import 'package:flutter/foundation.dart';

import '../../core/utils/date_utils.dart';
import 'enums.dart';

/// 실제 예약/확인해야 하는 개별 스케줄. Reservation 하나에 여러 개 연결될 수 있다.
@immutable
class Schedule {
  const Schedule({
    required this.id,
    required this.reservationId,
    required this.title,
    required this.date,
    required this.source,
    required this.notificationEnabled,
    required this.notificationId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int reservationId;

  /// 스케줄 제목. 예: "예약", "예약 확인", "준비물 확인".
  final String title;

  /// 예약 시점. 자동 생성 규칙은 자정(00:00), 사용자 지정은 임의 시각.
  final DateTime date;

  final ScheduleSource source;

  /// 알림 활성화 여부.
  final bool notificationEnabled;

  /// OS 알림 ID. 등록되지 않았으면 null(계획서 14.1).
  final int? notificationId;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// 기기 현재 날짜 기준 상태 판정(계획서 10장).
  ScheduleStatus statusAt(DateTime now) =>
      AppDate.isDateBeforeToday(date, now)
          ? ScheduleStatus.done
          : ScheduleStatus.upcoming;

  /// 정확한 시각 기준으로 이미 지난 스케줄인지(알림 등록 불가 판단).
  bool isPastInstant(DateTime now) => AppDate.isPastInstant(date, now);

  Schedule copyWith({
    String? title,
    DateTime? date,
    ScheduleSource? source,
    bool? notificationEnabled,
    int? notificationId,
    bool clearNotificationId = false,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id,
      reservationId: reservationId,
      title: title ?? this.title,
      date: date ?? this.date,
      source: source ?? this.source,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationId:
          clearNotificationId ? null : (notificationId ?? this.notificationId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
