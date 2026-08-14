import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatting.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/facility.dart';
import '../../domain/models/recurrence.dart';
import '../../domain/services/recurrence_generator.dart';
import 'widgets/reservation_result_dialogs.dart';

/// 반복 일정 생성(계획서 9장). 여러 개의 독립 사용 일정을 한 번에 생성한다.
class CreateRecurringScreen extends ConsumerStatefulWidget {
  const CreateRecurringScreen({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  ConsumerState<CreateRecurringScreen> createState() =>
      _CreateRecurringScreenState();
}

class _CreateRecurringScreenState
    extends ConsumerState<CreateRecurringScreen> {
  int? _facilityId;
  late DateTime _start;
  late DateTime _end;
  RecurrenceMode _mode = RecurrenceMode.everyNDays;
  int _intervalDays = 7;
  final Set<int> _weekdays = {DateTime.monday};
  bool _submitting = false;

  static const _weekdayLabels = {
    DateTime.monday: '월',
    DateTime.tuesday: '화',
    DateTime.wednesday: '수',
    DateTime.thursday: '목',
    DateTime.friday: '금',
    DateTime.saturday: '토',
    DateTime.sunday: '일',
  };

  @override
  void initState() {
    super.initState();
    _start = AppDate.dateOnly(widget.initialDate);
    _end = _start.add(const Duration(days: 28));
  }

  RecurrenceSpec get _spec => RecurrenceSpec(
        mode: _mode,
        start: _start,
        end: _end,
        intervalDays: _intervalDays,
        weekdays: _weekdays,
      );

  List<DateTime> get _preview {
    if (_spec.validate() != null) return const [];
    try {
      return const RecurrenceGenerator().generate(_spec);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(enabledFacilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('반복 일정 생성')),
      body: facilitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('시설을 불러오지 못했습니다: $e')),
        data: (facilities) {
          if (facilities.isEmpty) {
            return const Center(child: Text('활성화된 시설이 없습니다.'));
          }
          _facilityId ??= facilities.first.id;
          return _form(facilities);
        },
      ),
    );
  }

  Widget _form(List<Facility> facilities) {
    final preview = _preview;
    final error = _spec.validate();

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
                    child: Row(children: [
                      CircleAvatar(radius: 7, backgroundColor: Color(f.color)),
                      const SizedBox(width: 8),
                      Text(f.name),
                    ]),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _facilityId = v),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: '시작일',
                value: _start,
                onPick: (d) => setState(() => _start = d),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: '종료일',
                value: _end,
                onPick: (d) => setState(() => _end = d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SegmentedButton<RecurrenceMode>(
          segments: const [
            ButtonSegment(
              value: RecurrenceMode.everyNDays,
              label: Text('N일마다'),
              icon: Icon(Icons.repeat),
            ),
            ButtonSegment(
              value: RecurrenceMode.weekdays,
              label: Text('특정 요일'),
              icon: Icon(Icons.view_week),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 16),
        if (_mode == RecurrenceMode.everyNDays)
          Row(
            children: [
              const Text('반복 간격'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _intervalDays > 1
                    ? () => setState(() => _intervalDays--)
                    : null,
              ),
              Text('$_intervalDays일',
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _intervalDays++),
              ),
            ],
          )
        else
          Wrap(
            spacing: 8,
            children: _weekdayLabels.entries.map((e) {
              final selected = _weekdays.contains(e.key);
              return FilterChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _weekdays.add(e.key);
                  } else {
                    _weekdays.remove(e.key);
                  }
                }),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error ?? '생성될 일정: ${preview.length}건',
                  style: TextStyle(
                    color: error != null
                        ? Theme.of(context).colorScheme.error
                        : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (error == null && preview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    preview.take(12).map(Fmt.md).join(', ') +
                        (preview.length > 12 ? ' …' : ''),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: (_submitting || error != null || preview.isEmpty)
              ? null
              : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('${preview.length}건 등록'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(reservationServiceProvider)
          .createRecurring(facilityId: _facilityId!, spec: _spec);
      if (!mounted) return;

      if (result.isBlocked) {
        await showConflictDialog(context, result.conflicts);
        return;
      }
      if (result.hasPastWarning) {
        await showPastWarningDialog(context, result.pastSpecs);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.reservations.length}건 등록됨')),
        );
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(Fmt.md(value)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) onPick(AppDate.dateOnly(picked));
          },
        ),
      ],
    );
  }
}
