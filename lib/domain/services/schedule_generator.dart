import '../../core/utils/date_utils.dart';
import '../models/enums.dart';
import '../models/rule.dart';
import '../models/schedule_spec.dart';
import 'rule_engine.dart';

/// 스케줄 생성 결과. 저장 대상 명세와, 이미 지난 스케줄 경고를 담는다.
class ScheduleGenerationResult {
  const ScheduleGenerationResult({
    required this.specs,
    required this.pastSpecs,
  });

  /// 저장할 전체 스케줄 명세(날짜 오름차순).
  final List<ScheduleSpec> specs;

  /// 이미 시각이 지나 알림이 등록되지 않는 스케줄(계획서 11장).
  /// 스케줄 자체는 정상 저장하되, 등록 화면에서 경고에 사용한다.
  final List<ScheduleSpec> pastSpecs;

  bool get hasPast => pastSpecs.isNotEmpty;
}

/// 사용일 + 규칙 + 사용자 지정 스케줄을 결합해 최종 스케줄 명세를 만든다.
///
/// - 규칙(N일 전) 스케줄: RuleEngine 위임
/// - 사용일 마커: 달력/상세에서 사용일을 함께 보이기 위한 스케줄(알림 기본 off)
/// - 사용자 지정 스케줄: 그대로 병합
class ScheduleGenerator {
  const ScheduleGenerator({RuleEngine ruleEngine = const RuleEngine()})
      : _ruleEngine = ruleEngine;

  final RuleEngine _ruleEngine;

  ScheduleGenerationResult generate({
    required DateTime usageDate,
    required List<Rule> rules,
    required DateTime now,
    List<ScheduleSpec> customSpecs = const <ScheduleSpec>[],
    bool includeUsageMarker = true,
  }) {
    final specs = <ScheduleSpec>[
      ..._ruleEngine.generate(usageDate: usageDate, rules: rules),
      ...customSpecs,
    ];

    if (includeUsageMarker) {
      specs.add(
        ScheduleSpec(
          title: '사용',
          date: AppDate.atMidnight(usageDate),
          source: ScheduleSource.usage,
          notificationEnabled: false,
        ),
      );
    }

    // 이미 지난 스케줄은 알림 비활성화로 강제 저장(계획서 11.1).
    final normalized = <ScheduleSpec>[];
    final past = <ScheduleSpec>[];
    for (final spec in specs) {
      if (AppDate.isPastInstant(spec.date, now)) {
        if (spec.notificationEnabled) {
          past.add(spec); // 원래 알림 대상이었는데 지나서 못 거는 경우만 경고
        }
        normalized.add(spec.copyWith(notificationEnabled: false));
      } else {
        normalized.add(spec);
      }
    }

    normalized.sort((a, b) => a.date.compareTo(b.date));
    return ScheduleGenerationResult(specs: normalized, pastSpecs: past);
  }
}
