import 'package:flutter/material.dart';

import '../../../domain/models/rule.dart';

/// 규칙 입력 결과(제목 + N일 전).
class RuleInput {
  const RuleInput({required this.title, required this.offset});
  final String title;
  final int offset;
}

/// N일 전 규칙 추가/수정 다이얼로그(계획서 8.1).
Future<RuleInput?> showRuleDialog(BuildContext context, {Rule? rule}) {
  return showDialog<RuleInput>(
    context: context,
    builder: (_) => _RuleDialog(rule: rule),
  );
}

class _RuleDialog extends StatefulWidget {
  const _RuleDialog({this.rule});
  final Rule? rule;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late final TextEditingController _title;
  late int _offset;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.rule?.title ?? '');
    _offset = widget.rule?.offset ?? 7;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rule == null ? '규칙 추가' : '규칙 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '규칙 이름',
              hintText: '예: 예약, 예약 확인',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('사용일'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed:
                    _offset > 0 ? () => setState(() => _offset--) : null,
              ),
              Text('$_offset일 전',
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _offset++),
              ),
            ],
          ),
        ],
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
            Navigator.pop(context, RuleInput(title: title, offset: _offset));
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
