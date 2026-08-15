import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/facility.dart';
import '../../domain/models/rule.dart';
import 'widgets/rule_dialog.dart';

/// 시설 추가/수정 + 규칙 관리(계획서 4·8장).
class FacilityEditScreen extends ConsumerStatefulWidget {
  const FacilityEditScreen({super.key, this.facility});

  final Facility? facility;

  bool get isEditing => facility != null;

  @override
  ConsumerState<FacilityEditScreen> createState() =>
      _FacilityEditScreenState();
}

class _FacilityEditScreenState extends ConsumerState<FacilityEditScreen> {
  late final TextEditingController _name;
  late int _color;

  /// 신규 시설 추가 시 함께 만들 기본 "예약" 규칙의 일수(2주 전 기본).
  int _defaultOffset = AppConstants.defaultReservationOffsetDays;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.facility?.name ?? '');
    _color = widget.facility?.color ??
        AppConstants.facilityColorPalette.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '시설 수정' : '시설 추가'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '시설 이름'),
          ),
          const SizedBox(height: 20),
          Text('색상', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppConstants.facilityColorPalette.map((c) {
              final selected = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (widget.isEditing) ...[
            const Divider(),
            _RulesSection(facilityId: widget.facility!.id),
          ] else ...[
            Text('기본 예약 알림', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Expanded(child: Text('사용일 기준')),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _defaultOffset > 0
                          ? () => setState(() => _defaultOffset--)
                          : null,
                    ),
                    Text('$_defaultOffset일 전',
                        style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _defaultOffset++),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '저장하면 위 조건의 "예약" 규칙이 자동 생성됩니다. 이후 규칙을 추가/수정할 수 있습니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('시설 이름을 입력하세요.')));
      return;
    }
    final repo = ref.read(facilityRepositoryProvider);
    if (widget.isEditing) {
      await repo.update(
        widget.facility!.copyWith(
          name: name,
          color: _color,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      final id = await repo.create(name: name, color: _color);
      // 신규 시설에 기본 "예약" 규칙 자동 생성(#4).
      await ref.read(ruleRepositoryProvider).create(
            facilityId: id,
            title: AppConstants.defaultReservationRuleTitle,
            offset: _defaultOffset,
          );
    }
    if (mounted) Navigator.pop(context);
  }
}

class _RulesSection extends ConsumerWidget {
  const _RulesSection({required this.facilityId});

  final int facilityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(rulesForFacilityProvider(facilityId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('예약 규칙', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('규칙 추가'),
              onPressed: () => _addOrEdit(context, ref, null),
            ),
          ],
        ),
        rulesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('오류: $e'),
          data: (rules) {
            if (rules.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('규칙이 없습니다. "규칙 추가"로 N일 전 규칙을 만드세요.'),
              );
            }
            return Column(
              children: rules
                  .map((r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text('${r.offset}')),
                        title: Text(r.title),
                        subtitle: Text('사용일 ${r.offset}일 전'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: r.enabled,
                              onChanged: (v) => ref
                                  .read(ruleRepositoryProvider)
                                  .update(r.copyWith(
                                    enabled: v,
                                    updatedAt: DateTime.now(),
                                  )),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => ref
                                  .read(ruleRepositoryProvider)
                                  .delete(r.id),
                            ),
                          ],
                        ),
                        onTap: () => _addOrEdit(context, ref, r),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _addOrEdit(
    BuildContext context,
    WidgetRef ref,
    Rule? rule,
  ) async {
    final result = await showRuleDialog(context, rule: rule);
    if (result == null) return;
    final repo = ref.read(ruleRepositoryProvider);
    if (rule == null) {
      await repo.create(
        facilityId: facilityId,
        title: result.title,
        offset: result.offset,
      );
    } else {
      await repo.update(rule.copyWith(
        title: result.title,
        offset: result.offset,
        updatedAt: DateTime.now(),
      ));
    }
  }
}
