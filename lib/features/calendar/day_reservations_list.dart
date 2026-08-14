import 'package:flutter/material.dart';

import '../../core/utils/formatting.dart';
import '../../domain/models/facility.dart';
import '../../domain/models/reservation.dart';
import '../reservation/reservation_detail_screen.dart';

/// 선택한 날짜의 사용 일정 목록(계획서 5.2: 달력은 사용 일정 중심).
class DayReservationsList extends StatelessWidget {
  const DayReservationsList({
    super.key,
    required this.day,
    required this.reservations,
    required this.facilitiesById,
  });

  final DateTime day;
  final List<Reservation> reservations;
  final Map<int, Facility> facilitiesById;

  @override
  Widget build(BuildContext context) {
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
        if (reservations.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                '등록된 일정이 없습니다.\n아래 버튼으로 추가하세요.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
              itemCount: reservations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = reservations[i];
                final facility = facilitiesById[r.facilityId];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 8,
                      backgroundColor:
                          Color(facility?.color ?? 0xFF9E9E9E),
                    ),
                    title: Text(facility?.name ?? '(삭제된 시설)'),
                    subtitle: Text(
                      r.isRecurring ? '반복 생성 일정' : '단일 일정',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ReservationDetailScreen(reservationId: r.id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
