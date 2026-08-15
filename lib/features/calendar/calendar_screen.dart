import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../application/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/models/calendar_marker.dart';
import '../../domain/models/facility.dart';
import '../../domain/models/reservation.dart';
import '../facility/facility_list_screen.dart';
import '../reservation/create_reservation_screen.dart';
import '../settings/settings_screen.dart';
import 'day_reservations_list.dart';

/// 메인 화면: 월간 달력(계획서 5장).
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final reservationsAsync = ref.watch(monthReservationsProvider);
    final markersAsync = ref.watch(monthMarkersProvider);
    final facilitiesAsync = ref.watch(facilitiesProvider);

    final facilitiesById = <int, Facility>{
      for (final f in facilitiesAsync.value ?? const <Facility>[]) f.id: f,
    };

    // 사용일 목록(달력 하단 리스트용)
    final reservations = reservationsAsync.value ?? const <Reservation>[];
    final resByDay = <DateTime, List<Reservation>>{};
    for (final r in reservations) {
      resByDay.putIfAbsent(AppDate.dateOnly(r.usageDate), () => []).add(r);
    }
    List<Reservation> reservationsOf(DateTime d) =>
        resByDay[AppDate.dateOnly(d)] ?? const [];

    // 마커: 예약일 + 사용일(구분)
    final markers = markersAsync.value ?? const <CalendarMarker>[];
    final markersByDay = <DateTime, List<CalendarMarker>>{};
    for (final m in markers) {
      markersByDay.putIfAbsent(AppDate.dateOnly(m.date), () => []).add(m);
    }
    List<CalendarMarker> markersOf(DateTime d) =>
        markersByDay[AppDate.dateOnly(d)] ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: '시설 관리',
            icon: const Icon(Icons.apartment_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FacilityListScreen()),
            ),
          ),
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: TableCalendar<CalendarMarker>(
              locale: 'ko_KR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _clampFocused(focusedMonth, selectedDay),
              currentDay: DateTime.now(),
              selectedDayPredicate: (d) => isSameDay(d, selectedDay),
              eventLoader: markersOf,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              availableCalendarFormats: const {CalendarFormat.month: '월'},
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              onHeaderTapped: (_) => _pickYearMonth(context, ref, focusedMonth),
              onDaySelected: (selected, focused) {
                ref.read(selectedDayProvider.notifier).state =
                    AppDate.dateOnly(selected);
                ref.read(focusedMonthProvider.notifier).state =
                    DateTime(focused.year, focused.month);
              },
              onPageChanged: (focused) {
                ref.read(focusedMonthProvider.notifier).state =
                    DateTime(focused.year, focused.month);
              },
              calendarBuilders: CalendarBuilders<CalendarMarker>(
                markerBuilder: (context, day, dayMarkers) {
                  if (dayMarkers.isEmpty) return null;
                  return Padding(
                    padding: const EdgeInsets.only(top: 34),
                    child: Wrap(
                      spacing: 3,
                      alignment: WrapAlignment.center,
                      children: dayMarkers.take(4).map(_dot).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: DayReservationsList(
              day: selectedDay,
              reservations: reservationsOf(selectedDay),
              facilitiesById: facilitiesById,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateReservationScreen(initialDate: selectedDay),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('일정 추가'),
      ),
    );
  }

  /// 사용일 = 꽉 찬 점, 예약(해야 하는)일 = 테두리만 있는 점(#6).
  Widget _dot(CalendarMarker m) {
    final color = Color(m.facilityColor);
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: m.isUsage ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  DateTime _clampFocused(DateTime focusedMonth, DateTime selectedDay) {
    if (selectedDay.year == focusedMonth.year &&
        selectedDay.month == focusedMonth.month) {
      return selectedDay;
    }
    return focusedMonth;
  }

  /// 헤더(예: 2026년 9월) 탭 → 연/월 선택(#7).
  Future<void> _pickYearMonth(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _YearMonthPickerDialog(initial: current),
    );
    if (picked != null) {
      ref.read(focusedMonthProvider.notifier).state =
          DateTime(picked.year, picked.month);
    }
  }
}

/// 연도 + 월을 고르는 간단한 다이얼로그(#7).
class _YearMonthPickerDialog extends StatefulWidget {
  const _YearMonthPickerDialog({required this.initial});
  final DateTime initial;

  @override
  State<_YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<_YearMonthPickerDialog> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('연도 · 월 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _year--),
              ),
              Text('$_year년',
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _year++),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var m = 1; m <= 12; m++)
                ChoiceChip(
                  label: Text('$m월'),
                  selected: _month == m,
                  onSelected: (_) => setState(() => _month = m),
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
          onPressed: () =>
              Navigator.pop(context, DateTime(_year, _month)),
          child: const Text('이동'),
        ),
      ],
    );
  }
}
