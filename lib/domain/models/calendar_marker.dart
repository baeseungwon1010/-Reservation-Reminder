import 'package:flutter/foundation.dart';

import 'enums.dart';

/// 달력의 한 날짜에 찍히는 표식 겸 하단 목록 항목.
/// 예약(해야 하는 날)과 사용(사용일)을 모두 담되 source 로 구분한다(#6).
@immutable
class CalendarMarker {
  const CalendarMarker({
    required this.date,
    required this.reservationId,
    required this.usageDate,
    required this.title,
    required this.facilityId,
    required this.facilityName,
    required this.facilityColor,
    required this.source,
  });

  /// 이 표식이 찍히는 날짜(예약일 또는 사용일).
  final DateTime date;

  /// 연결된 사용 일정(Reservation) id 와 그 사용일.
  final int reservationId;
  final DateTime usageDate;

  /// 스케줄 제목(예: "예약").
  final String title;

  final int facilityId;
  final String facilityName;
  final int facilityColor;
  final ScheduleSource source;

  bool get isUsage => source == ScheduleSource.usage;
}
