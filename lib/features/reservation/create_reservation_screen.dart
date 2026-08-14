import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatting.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/facility.dart';
import '../../domain/models/rule.dart';
import '../../domain/models/schedule_spec.dart';
import '../../domain/services/schedule_generator.dart';
import 'widgets/custom_schedule_dialog.dart';
import 'widgets/reservation_result_dialogs.dart';

/// 단일 일정 등록(계획서 7장).
class CreateReservationScreen extends ConsumerStatefulWidget {
  const CreateReservationScreen({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  ConsumerState<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState
    extends ConsumerState<CreateReservationScreen> {
  int? _facilityId;
  late DateTime _usageDate;
  final List<ScheduleSpec> _customSpecs = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _usageDate = AppDate.dateOnly(widget.initialDate);
  }

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(enabledFacilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('단일 일정 등록')),
      body: facilitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('시설을 불러오지 못했습니다: $e')),
        data: (facilities) {
          if (facilities.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('활성화된 시설이 없습니다.\n먼저 시설을 추가/활성화하세요.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          _facilityId ??= facilities.first.id;
          return _form(facilities);
        },
      ),
    );
  }

  Widget _form(List<Facility> facilities) {
    final rulesAsync = ref.watch(rulesForFacilityProvider(_facilityId!));
    final rules = (rulesAsync.value ?? const <Rule>[])
        .where((r) => r.enabled)
        .toList();

    final preview = const ScheduleGenerator().generate(
      usageDate: _usageDate,
      rules: rules,
      customSpecs: _customSpecs,
      now: DateTime.now(),
      includeUsageMarker: false,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text('시설', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _facilityId,
          items: facilities
              .map((f) => DropdownMenuItem(
                    value: f.id,
                    child: Row(
                      children: [
                        CircleAvatar(radius: 7, backgroundColor: Color(f.color)),
                        const SizedBox(width: 8),
                        Text(f.name),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _facilityId = v),
        ),
        const SizedBox(height: 20),
        Text('사용 날짜', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: Text(Fmt.ymdWeekday(_usageDate)),
          onPressed: _pickUsageDate,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('생성될 예약 스케줄',
                style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('추가 스케줄'),
              onPressed: _addCustomSchedule,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (preview.specs.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('적용할 규칙이 없습니다. 시설 규칙을 확인하세요.'),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final spec in preview.specs)
                  _SchedulePreviewTile(
                    spec: spec,
                    isPast: AppDate.isPastInstant(spec.date, DateTime.now()),
                    onRemove: spec.source == ScheduleSource.custom
                        ? () => setState(() => _customSpecs.remove(spec))
                        : null,
                  ),
              ],
            ),
          ),
        if (preview.hasPast) ...[
          const SizedBox(height: 12),
          _PastWarningBanner(count: preview.pastSpecs.length),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submitting ? null : () => _submit(rules),
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('등록'),
        ),
      ],
    );
  }

  Future<void> _pickUsageDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _usageDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _usageDate = AppDate.dateOnly(picked));
    }
  }

  Future<void> _addCustomSchedule() async {
    final spec = await showCustomScheduleDialog(context, baseDate: _usageDate);
    if (spec != null) setState(() => _customSpecs.add(spec));
  }

  Future<void> _submit(List<Rule> rules) async {
    setState(() => _submitting = true);
    try {
      final service = ref.read(reservationServiceProvider);
      final result = await service.createSingle(
        facilityId: _facilityId!,
        usageDate: _usageDate,
        customSpecs: _customSpecs,
      );
      if (!mounted) return;

      if (result.isBlocked) {
        await showConflictDialog(context, result.conflicts);
        return;
      }
      if (result.hasPastWarning) {
        await showPastWarningDialog(context, result.pastSpecs);
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SchedulePreviewTile extends StatelessWidget {
  const _SchedulePreviewTile({
    required this.spec,
    required this.isPast,
    this.onRemove,
  });

  final ScheduleSpec spec;
  final bool isPast;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        spec.source == ScheduleSource.custom
            ? Icons.push_pin_outlined
            : Icons.notifications_active_outlined,
        color: isPast ? Theme.of(context).disabledColor : null,
      ),
      title: Text(spec.title),
      subtitle: Text(Fmt.dateTime(spec.date)),
      trailing: onRemove != null
          ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
            )
          : (isPast
              ? const Chip(
                  label: Text('지남', style: TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                )
              : null),
    );
  }
}

class _PastWarningBanner extends StatelessWidget {
  const _PastWarningBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '이미 지난 스케줄 $count건은 저장되지만 알림이 등록되지 않습니다.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
