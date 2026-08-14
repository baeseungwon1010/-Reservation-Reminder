import 'package:flutter/material.dart';

import '../../../core/utils/formatting.dart';
import '../../../domain/models/schedule_spec.dart';
import '../../../domain/services/conflict_validator.dart';

/// 충돌 경고(계획서 12장). 일정 추가가 차단되었음을 알린다.
Future<void> showConflictDialog(
  BuildContext context,
  List<ConflictResult> conflicts,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      icon: const Icon(Icons.error_outline),
      title: const Text('일정 충돌'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('해당 시설에 이미 등록된 일정이 있어 추가할 수 없습니다.'),
          const SizedBox(height: 12),
          for (final c in conflicts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${Fmt.ymdWeekday(c.usageDate)}'),
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

/// 지난 스케줄 경고(계획서 11.2). 저장은 되지만 알림이 등록되지 않는다.
Future<void> showPastWarningDialog(
  BuildContext context,
  List<ScheduleSpec> pastSpecs,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      icon: const Icon(Icons.warning_amber),
      title: const Text('이미 지난 일정이 있습니다'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('아래 스케줄은 이미 지나 알림이 등록되지 않았습니다.\n일정 자체는 정상 저장됩니다.'),
          const SizedBox(height: 12),
          for (final s in pastSpecs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${Fmt.md(s.date)} ${s.title}'),
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
