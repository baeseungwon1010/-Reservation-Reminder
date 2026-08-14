/// 예약 규칙 종류. 현재 MVP는 상대 날짜(N일 전)만 지원한다(계획서 8장).
enum RuleType {
  /// 사용일 기준 N일 전.
  relativeDays;

  static RuleType fromName(String name) => RuleType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => RuleType.relativeDays,
      );
}

/// 스케줄의 출처.
enum ScheduleSource {
  /// 시설 예약 규칙(N일 전)에 의해 자동 생성.
  rule,

  /// 사용자가 직접 추가한 스케줄.
  custom,

  /// 사용일 자체를 나타내는 마커.
  usage;

  static ScheduleSource fromName(String name) =>
      ScheduleSource.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ScheduleSource.rule,
      );
}

/// 스케줄 상태. 사용자가 직접 완료하지 않고 기기 날짜로 자동 판정한다(계획서 10장).
enum ScheduleStatus {
  /// 스케줄 날짜 >= 오늘.
  upcoming,

  /// 스케줄 날짜 < 오늘.
  done;

  String get label => this == ScheduleStatus.upcoming ? '예정' : '완료';
}

/// 반복 생성 방식(계획서 9장).
enum RecurrenceMode {
  /// N일마다.
  everyNDays,

  /// 특정 요일(월~일).
  weekdays,
}
