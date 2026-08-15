import 'package:flutter/foundation.dart';

import 'enums.dart';

/// 달력의 한 날짜에 찍히는 표식. 예약(해야 하는 날)과 사용(사용일)을 구분한다(#6).
@immutable
class CalendarMarker {
  const CalendarMarker({
    required this.date,
    required this.facilityId,
    required this.facilityColor,
    required this.source,
  });

  final DateTime date;
  final int facilityId;
  final int facilityColor;
  final ScheduleSource source;

  bool get isUsage => source == ScheduleSource.usage;
}
