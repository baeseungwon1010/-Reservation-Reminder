import 'package:flutter/material.dart';

import '../../core/utils/formatting.dart';
import '../../domain/models/calendar_marker.dart';
import '../../domain/models/enums.dart';
import '../common/schedule_visuals.dart';
import '../reservation/reservation_detail_screen.dart';

/// 선택한 날짜의 일정 목록. 사용일뿐 아니라 그날 해야 하는 예약도 함께 보여준다(#6).
class DayScheduleList extends StatelessWidget {
  const DayScheduleList({
    super.key,
    required this.day,
    required this.markers,
  });

  final DateTime day;
  final List<CalendarMarker> markers;

  @override
  Widget build(BuildContext context) {
    // 사용일 먼저, 그다음 예약/사용자지정 순으로 정렬.
    final sorted = [...markers]..sort((a, b) {
        if (a.isUsage != b.isUsage) return a.isUsage ? -1 : 1;
        return a.date.compareTo(b.date);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            Fmt.ymdWeekday(day),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (sorted.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                '이 날은 일정이 없어요.\n아래 버튼으로 추가할 수 있어요.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _tile(context, sorted[i]),
            ),
          ),
      ],
    );
  }

  Widget _tile(BuildContext context, CalendarMarker m) {
    final color = Color(m.facilityColor);
    final scheme = Theme.of(context).colorScheme;

    final String titleText;
    final String subtitleText;
    if (m.isUsage) {
      titleText = '${m.facilityName} 사용';
      subtitleText = '사용일';
    } else {
      // 예약 / 사용자 지정
      titleText = '${m.facilityName} · ${m.title}';
      subtitleText = '${ScheduleVisuals.label(m.source)} · 사용일 ${Fmt.md(m.usageDate)}';
    }

    return Card(
      child: ListTile(
        leading: _leading(m, color, scheme),
        title: Text(titleText),
        subtitle: Text(subtitleText),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ReservationDetailScreen(reservationId: m.reservationId),
          ),
        ),
      ),
    );
  }

  /// 사용일은 꽉 찬 원, 예약일은 링 + 아이콘으로 구분.
  Widget _leading(CalendarMarker m, Color color, ColorScheme scheme) {
    if (m.isUsage) {
      return CircleAvatar(radius: 12, backgroundColor: color);
    }
    return CircleAvatar(
      radius: 12,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Icon(
        m.source == ScheduleSource.custom
            ? Icons.push_pin_outlined
            : Icons.notifications_active_outlined,
        size: 15,
        color: color,
      ),
    );
  }
}
