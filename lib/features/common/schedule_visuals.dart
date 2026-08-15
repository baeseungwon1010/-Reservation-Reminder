import 'package:flutter/material.dart';

import '../../domain/models/enums.dart';

/// ScheduleSource 별 시각 요소(아이콘/색 힌트). 예약·사용·사용자지정을 구분한다.
class ScheduleVisuals {
  ScheduleVisuals._();

  /// 스케줄 종류별 아이콘. 예약과 사용을 분명히 구분한다(#1).
  static IconData icon(ScheduleSource source) {
    switch (source) {
      case ScheduleSource.rule:
        return Icons.notifications_active_outlined; // 예약(알림) — 종
      case ScheduleSource.usage:
        return Icons.location_on_outlined; // 사용 — 장소 핀
      case ScheduleSource.custom:
        return Icons.push_pin_outlined; // 사용자 지정 — 압정
    }
  }

  static String label(ScheduleSource source) {
    switch (source) {
      case ScheduleSource.rule:
        return '예약';
      case ScheduleSource.usage:
        return '사용';
      case ScheduleSource.custom:
        return '사용자 지정';
    }
  }
}
