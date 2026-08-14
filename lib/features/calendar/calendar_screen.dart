import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../application/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatting.dart';
import '../../domain/models/facility.dart';
import '../../domain/models/reservation.dart';
import '../facility/facility_list_screen.dart';
import '../reservation/create_reservation_screen.dart';
import '../reservation/create_recurring_screen.dart';
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
    final facilitiesAsync = ref.watch(facilitiesProvider);

    final facilitiesById = <int, Facility>{
      for (final f in facilitiesAsync.value ?? const <Facility>[]) f.id: f,
    };

    final reservations = reservationsAsync.value ?? const <Reservation>[];
    final byDay = <DateTime, List<Reservation>>{};
    for (final r in reservations) {
      final key = AppDate.dateOnly(r.usageDate);
      byDay.putIfAbsent(key, () => []).add(r);
    }

    List<Reservation> eventsOf(DateTime day) =>
        byDay[AppDate.dateOnly(day)] ?? const [];

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
            child: TableCalendar<Reservation>(
              locale: 'ko_KR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _clampFocused(focusedMonth, selectedDay),
              currentDay: DateTime.now(),
              selectedDayPredicate: (d) => isSameDay(d, selectedDay),
              eventLoader: eventsOf,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              availableCalendarFormats: const {CalendarFormat.month: '월'},
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
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
              calendarBuilders: CalendarBuilders<Reservation>(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return Padding(
                    padding: const EdgeInsets.only(top: 34),
                    child: Wrap(
                      spacing: 2,
                      alignment: WrapAlignment.center,
                      children: events.take(4).map((r) {
                        final color = facilitiesById[r.facilityId]?.color ??
                            AppConstants.defaultAuditoriumColor;
                        return Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: DayReservationsList(
              day: selectedDay,
              reservations: eventsOf(selectedDay),
              facilitiesById: facilitiesById,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref, selectedDay),
        icon: const Icon(Icons.add),
        label: const Text('일정 추가'),
      ),
    );
  }

  DateTime _clampFocused(DateTime focusedMonth, DateTime selectedDay) {
    // 선택일이 표시 월에 속하면 선택일을, 아니면 그 달 1일을 focus.
    if (selectedDay.year == focusedMonth.year &&
        selectedDay.month == focusedMonth.month) {
      return selectedDay;
    }
    return focusedMonth;
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, DateTime day) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('단일 일정'),
              subtitle: Text('${Fmt.mdWeekday(day)} 사용 일정 등록'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateReservationScreen(initialDate: day),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('반복 일정'),
              subtitle: const Text('N일마다 / 특정 요일로 여러 일정 생성'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateRecurringScreen(initialDate: day),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
