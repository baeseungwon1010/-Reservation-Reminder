import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../models/enums.dart';
import '../models/recurrence.dart';

/// 반복 조건으로부터 사용일 목록을 생성한다(계획서 9장).
///
/// 영구적인 "반복 객체"를 만들지 않고, 독립적인 사용일들의 목록만 돌려준다.
/// 각 사용일은 이후 개별 Reservation 으로 저장된다.
class RecurrenceGenerator {
  const RecurrenceGenerator();

  List<DateTime> generate(RecurrenceSpec spec) {
    final error = spec.validate();
    if (error != null) {
      throw ArgumentError(error);
    }
    switch (spec.mode) {
      case RecurrenceMode.everyNDays:
        return _everyNDays(spec);
      case RecurrenceMode.weekdays:
        return _weekdays(spec);
    }
  }

  List<DateTime> _everyNDays(RecurrenceSpec spec) {
    final result = <DateTime>[];
    var cur = AppDate.dateOnly(spec.start);
    final end = AppDate.dateOnly(spec.end);
    var guard = 0;
    while (!cur.isAfter(end) && guard < AppConstants.maxRecurrenceCount) {
      result.add(cur);
      cur = cur.add(Duration(days: spec.intervalDays));
      guard++;
    }
    return result;
  }

  List<DateTime> _weekdays(RecurrenceSpec spec) {
    return AppDate.eachDay(spec.start, spec.end)
        .where((d) => spec.weekdays.contains(d.weekday))
        .toList();
  }
}
