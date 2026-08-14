/// 날짜/시간 계산 유틸.
///
/// 앱 전역에서 "날짜" 비교는 반드시 이 유틸을 통해 수행한다.
/// 시간대는 기기 로컬 시간을 신뢰한다(계획서 16장).
class AppDate {
  AppDate._();

  /// 시각을 버리고 그 날의 00:00:00 으로 정규화한다.
  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// 그 날의 자정(00:00). dateOnly 와 동일하지만 의도를 드러내는 별칭.
  static DateTime atMidnight(DateTime dt) => dateOnly(dt);

  /// 특정 날짜에 시/분을 지정한 DateTime.
  static DateTime withTime(DateTime date, int hour, int minute) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  /// 두 DateTime 이 같은 "날짜"인지(시각 무시).
  static bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// N일 전 날짜(자정). 사용일 - offset일.
  static DateTime daysBefore(DateTime usageDate, int offsetDays) =>
      dateOnly(usageDate).subtract(Duration(days: offsetDays));

  /// 날짜 기준으로 date 가 today "이전"인지(= 완료). 시각 무시.
  static bool isDateBeforeToday(DateTime date, DateTime today) =>
      dateOnly(date).isBefore(dateOnly(today));

  /// 정확한 시각 기준으로 이미 지난 시점인지(알림 등록 가능 여부 판단용).
  static bool isPastInstant(DateTime instant, DateTime now) =>
      !instant.isAfter(now);

  /// start~end(양끝 포함) 사이 날짜들을 하루 간격으로 열거.
  static List<DateTime> eachDay(DateTime start, DateTime end) {
    final result = <DateTime>[];
    var cur = dateOnly(start);
    final last = dateOnly(end);
    while (!cur.isAfter(last)) {
      result.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return result;
  }
}
