import 'package:flutter/material.dart';

/// 앱 전역 상수.
class AppConstants {
  AppConstants._();

  static const String appName = '예약 알리미';

  /// 기본 제공 시설 이름.
  static const String defaultAuditoriumName = '강당';
  static const String defaultClassroomName = '강의실';

  /// 시설별 기본 색상(ARGB int). 실제 값은 시설 데이터에 저장된다.
  static const int defaultAuditoriumColor = 0xFF1E88E5; // 파랑
  static const int defaultClassroomColor = 0xFF43A047; // 초록

  /// 시설 색상 팔레트(시설 추가/편집 시 선택지).
  static const List<int> facilityColorPalette = <int>[
    0xFF1E88E5,
    0xFF43A047,
    0xFFE53935,
    0xFFF4511E,
    0xFF8E24AA,
    0xFF00897B,
    0xFFFB8C00,
    0xFF3949AB,
  ];

  /// 자동 생성 예약 스케줄의 기본 시간(22:00). 어디까지나 기본값이며
  /// 등록 화면에서 각 스케줄의 시간을 개별 수정할 수 있다.
  static const int autoScheduleHour = 22;
  static const int autoScheduleMinute = 0;

  /// 신규 시설을 추가할 때 부여되는 기본 "예약" 규칙의 일수(2주 전).
  static const int defaultReservationOffsetDays = 14;

  /// 기본 예약 규칙 제목.
  static const String defaultReservationRuleTitle = '예약';

  /// 반복 생성 시 안전 상한(무한 루프 방지).
  static const int maxRecurrenceCount = 366;
}

/// 시설별 기본 색상 매핑 헬퍼.
Color colorFromArgb(int argb) => Color(argb);
