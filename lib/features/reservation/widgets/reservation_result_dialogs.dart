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
          const Text('이 시설에 같은 날 일정이 이미 있어서 추가할 수 없어요.'),
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
          const Text('아래 일정은 이미 지나서 알림이 등록되지 않았어요.\n일정은 그대로 저장돼요.'),
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
