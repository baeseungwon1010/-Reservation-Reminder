import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatting.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/facility.dart';
import '../../domain/models/recurrence.dart';
import '../../domain/models/rule.dart';
import '../../domain/models/schedule_spec.dart';
import '../../domain/services/recurrence_generator.dart';
import '../../domain/services/rule_engine.dart';
import '../common/schedule_visuals.dart';
import '../common/time_wheel_picker.dart';
import 'widgets/custom_schedule_dialog.dart';
import 'widgets/reservation_result_dialogs.dart';

/// 일정 추가(통합). 반복은 별도 화면이 아니라 토글 속성으로 제공한다(#8).
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
  late DateTime _date; // 단일: 사용일 / 반복: 시작일
  late DateTime _endDate; // 반복 종료일

  bool _recurring = false;
  RecurrenceMode _mode = RecurrenceMode.everyNDays;
  int _intervalDays = 7;
  final Set<int> _weekdays = {DateTime.monday};

  // 단일 모드에서 편집 가능한 스케줄 목록(규칙+사용자지정, 시간 편집 반영).
  List<ScheduleSpec> _specs = [];
  String _specsKey = '';

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
    _date = AppDate.dateOnly(widget.initialDate);
    _endDate = _date.add(const Duration(days: 28));
  }

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(enabledFacilitiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('일정 추가')),
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
    final rules =
        (rulesAsync.value ?? const <Rule>[]).where((r) => r.enabled).toList();

    if (!_recurring) _regenIfNeeded(rules);

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
        const SizedBox(height: 12),

        // 반복 토글 (#8)
        Card(
          child: SwitchListTile(
            title: const Text('반복 일정'),
            subtitle: const Text('여러 사용일을 한 번에 생성'),
            value: _recurring,
            onChanged: (v) => setState(() => _recurring = v),
          ),
        ),
        const SizedBox(height: 12),

        if (_recurring) ..._recurringFields() else ..._singleFields(rules),

        const SizedBox(height: 24),
        _submitButton(),
      ],
    );
  }

  // ---------- 단일 모드 ----------

  void _regenIfNeeded(List<Rule> rules) {
    final key = '$_facilityId|${_date.toIso8601String()}|${rules.length}';
    if (key == _specsKey) return;
    _specsKey = key;
    _specs = const RuleEngine().generate(usageDate: _date, rules: rules);
  }

  List<Widget> _singleFields(List<Rule> rules) {
    final now = DateTime.now();
    final pastCount =
        _specs.where((s) => AppDate.isPastInstant(s.date, now)).length;

    return [
      Text('사용 날짜', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today),
        label: Text(Fmt.ymdWeekday(_date)),
        onPressed: () => _pickDate(_date, (d) => setState(() => _date = d)),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Text('생성될 예약 스케줄', style: Theme.of(context).textTheme.labelLarge),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('추가 스케줄'),
            onPressed: _addCustom,
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_specs.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('규칙이 없습니다. "추가 스케줄"로 직접 넣거나 시설 규칙을 설정하세요.'),
          ),
        )
      else
        Card(
          child: Column(
            children: [
              for (var i = 0; i < _specs.length; i++)
                _specTile(_specs[i], i, now),
            ],
          ),
        ),
      if (pastCount > 0) ...[
        const SizedBox(height: 12),
        _PastBanner(pastCount),
      ],
    ];
  }

  Widget _specTile(ScheduleSpec spec, int index, DateTime now) {
    final isPast = AppDate.isPastInstant(spec.date, now);
    return ListTile(
      dense: true,
      leading: Icon(
        ScheduleVisuals.icon(spec.source),
        color: isPast ? Theme.of(context).disabledColor : null,
      ),
      title: Text(spec.title),
      subtitle: Text(Fmt.dateTime(spec.date)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPast)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text('지남', style: TextStyle(fontSize: 11)),
            ),
          IconButton(
            tooltip: '시간 변경',
            icon: const Icon(Icons.schedule, size: 20),
            onPressed: () => _editTime(index),
          ),
          IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _specs.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Future<void> _editTime(int index) async {
    final spec = _specs[index];
    final picked = await pickTimeWheel(
      context,
      initial: TimeOfDay(hour: spec.date.hour, minute: spec.date.minute),
    );
    if (picked == null) return;
    setState(() {
      _specs[index] = spec.copyWith(
        date: AppDate.withTime(spec.date, picked.hour, picked.minute),
      );
    });
  }

  Future<void> _addCustom() async {
    final spec = await showCustomScheduleDialog(context, baseDate: _date);
    if (spec != null) setState(() => _specs.add(spec));
  }

  // ---------- 반복 모드 ----------

  RecurrenceSpec get _recurrenceSpec => RecurrenceSpec(
        mode: _mode,
        start: _date,
        end: _endDate,
        intervalDays: _intervalDays,
        weekdays: _weekdays,
      );

  List<DateTime> get _recurrencePreview {
    if (_recurrenceSpec.validate() != null) return const [];
    try {
      return const RecurrenceGenerator().generate(_recurrenceSpec);
    } catch (_) {
      return const [];
    }
  }

  List<Widget> _recurringFields() {
    final preview = _recurrencePreview;
    final error = _recurrenceSpec.validate();
    return [
      Row(
        children: [
          Expanded(
            child: _dateField('시작일', _date,
                (d) => setState(() => _date = d)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dateField('종료일', _endDate,
                (d) => setState(() => _endDate = d)),
          ),
        ],
      ),
      const SizedBox(height: 16),
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
            return FilterChip(
              label: Text(e.value),
              selected: _weekdays.contains(e.key),
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
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error ?? '생성될 일정: ${preview.length}건\n'
                '${preview.take(12).map(Fmt.md).join(', ')}'
                '${preview.length > 12 ? ' …' : ''}',
            style: TextStyle(
              color: error != null ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '반복 일정은 각 사용일에 시설 규칙이 자동 적용됩니다.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }

  // ---------- 공통 ----------

  Widget _dateField(String label, DateTime value, ValueChanged<DateTime> onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(Fmt.md(value)),
          onPressed: () => _pickDate(value, onPick),
        ),
      ],
    );
  }

  Future<void> _pickDate(DateTime initial, ValueChanged<DateTime> onPick) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPick(AppDate.dateOnly(picked));
  }

  Widget _submitButton() {
    final canSubmit = _recurring
        ? (_recurrenceSpec.validate() == null && _recurrencePreview.isNotEmpty)
        : true;
    return FilledButton(
      onPressed: (_submitting || !canSubmit) ? null : _submit,
      child: _submitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Text(_recurring ? '${_recurrencePreview.length}건 등록' : '등록'),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final service = ref.read(reservationServiceProvider);
      final result = _recurring
          ? await service.createRecurring(
              facilityId: _facilityId!, spec: _recurrenceSpec)
          : await service.createSingle(
              facilityId: _facilityId!, usageDate: _date, specs: _specs);
      if (!mounted) return;

      if (result.isBlocked) {
        await showConflictDialog(context, result.conflicts);
        return;
      }
      if (result.hasPastWarning) {
        await showPastWarningDialog(context, result.pastSpecs);
      }
      if (mounted) {
        if (_recurring) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.reservations.length}건 등록됨')),
          );
        }
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _PastBanner extends StatelessWidget {
  const _PastBanner(this.count);
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
