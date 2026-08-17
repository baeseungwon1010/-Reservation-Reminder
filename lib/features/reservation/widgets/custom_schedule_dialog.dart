import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatting.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/schedule_spec.dart';
import '../../common/time_wheel_picker.dart';

/// 사용자 지정 추가 스케줄 입력 다이얼로그(계획서 8.3).
/// 제목/날짜/시간/알림 여부를 입력받아 ScheduleSpec 을 돌려준다.
Future<ScheduleSpec?> showCustomScheduleDialog(
  BuildContext context, {
  required DateTime baseDate,
  ScheduleSpec? initial,
}) {
  return showDialog<ScheduleSpec>(
    context: context,
    builder: (_) => _CustomScheduleDialog(baseDate: baseDate, initial: initial),
  );
}

class _CustomScheduleDialog extends StatefulWidget {
  const _CustomScheduleDialog({required this.baseDate, this.initial});

  final DateTime baseDate;
  final ScheduleSpec? initial;

  @override
  State<_CustomScheduleDialog> createState() => _CustomScheduleDialogState();
}

class _CustomScheduleDialogState extends State<_CustomScheduleDialog> {
  late final TextEditingController _title;
  late DateTime _date;
  late TimeOfDay _time;
  bool _notify = true;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _title = TextEditingController(text: init?.title ?? '');
    _date = AppDate.dateOnly(init?.date ?? widget.baseDate);
    _time = TimeOfDay.fromDateTime(init?.date ?? widget.baseDate);
    _notify = init?.notificationEnabled ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('일정 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(Fmt.md(_date)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _date = AppDate.dateOnly(picked));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(_time.format(context)),
                    onPressed: () async {
                      final picked =
                          await pickTimeWheel(context, initial: _time);
                      if (picked != null) setState(() => _time = picked);
                    },
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('알림'),
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final title = _title.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(
              context,
              ScheduleSpec(
                title: title,
                date: AppDate.withTime(_date, _time.hour, _time.minute),
                source: ScheduleSource.custom,
                notificationEnabled: _notify,
              ),
            );
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
