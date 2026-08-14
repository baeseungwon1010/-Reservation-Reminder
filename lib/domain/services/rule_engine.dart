import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../models/enums.dart';
import '../models/rule.dart';
import '../models/schedule_spec.dart';

/// 시설 예약 규칙을 사용일에 적용하여 스케줄 명세를 계산한다.
///
/// 계획서 8장: `사용일 - N일 = 예약 스케줄 날짜`, 시각은 자정(00:00) 고정.
class RuleEngine {
  const RuleEngine();

  /// 활성화된 규칙만 적용한다. 결과는 날짜 오름차순 정렬.
  List<ScheduleSpec> generate({
    required DateTime usageDate,
    required List<Rule> rules,
  }) {
    final specs = <ScheduleSpec>[];
    for (final rule in rules) {
      if (!rule.enabled) continue;
      final date = _applyRule(rule, usageDate);
      if (date == null) continue;
      specs.add(
        ScheduleSpec(
          title: rule.title,
          date: date,
          source: ScheduleSource.rule,
          notificationEnabled: true,
        ),
      );
    }
    specs.sort((a, b) => a.date.compareTo(b.date));
    return specs;
  }

  DateTime? _applyRule(Rule rule, DateTime usageDate) {
    switch (rule.type) {
      case RuleType.relativeDays:
        final day = AppDate.daysBefore(usageDate, rule.offset);
        return AppDate.withTime(
          day,
          AppConstants.autoScheduleHour,
          AppConstants.autoScheduleMinute,
        );
    }
  }
}
