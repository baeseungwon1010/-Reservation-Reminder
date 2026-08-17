import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/utils/formatting.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/facility.dart';
import '../../domain/models/reservation.dart';
import '../../domain/models/schedule.dart';
import '../common/schedule_visuals.dart';
import 'widgets/custom_schedule_dialog.dart';

/// 일정 상세: 사용 일정 + 예약 스케줄 목록(계획서 4·5.2·6장).
class ReservationDetailScreen extends ConsumerWidget {
  const ReservationDetailScreen({super.key, required this.reservationId});

  final int reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(reservationByIdProvider(reservationId));
    final schedulesAsync =
        ref.watch(schedulesForReservationProvider(reservationId));
    final facilities = ref.watch(facilitiesProvider).value ?? const <Facility>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 상세'),
        actions: [
          reservationAsync.maybeWhen(
            data: (r) => r == null
                ? const SizedBox.shrink()
                : PopupMenuButton<String>(
                    onSelected: (v) => _onMenu(context, ref, v, r),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('이 일정 삭제'),
                      ),
                      if (r.isRecurring)
                        const PopupMenuItem(
                          value: 'deleteBatch',
                          child: Text('반복 그룹 전체 삭제'),
                        ),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: reservationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (reservation) {
          if (reservation == null) {
            return const Center(child: Text('삭제된 일정입니다.'));
          }
          final facility = facilities
              .where((f) => f.id == reservation.facilityId)
              .cast<Facility?>()
              .firstWhere((_) => true, orElse: () => null);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(reservation: reservation, facility: facility),
              const Divider(height: 1),
              Expanded(
                child: schedulesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('오류: $e')),
                  data: (schedules) =>
                      _ScheduleList(reservationId: reservationId, schedules: schedules),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: reservationAsync.maybeWhen(
        data: (r) => r == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _addCustom(context, ref, r),
                icon: const Icon(Icons.add),
                label: const Text('직접 추가'),
              ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _addCustom(
    BuildContext context,
    WidgetRef ref,
    Reservation r,
  ) async {
    final spec = await showCustomScheduleDialog(context, baseDate: r.usageDate);
    if (spec == null) return;
    await ref
        .read(reservationServiceProvider)
        .addCustomSchedule(r.id, spec);
    ref.invalidate(schedulesForReservationProvider(reservationId));
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    String action,
    Reservation r,
  ) async {
    final service = ref.read(reservationServiceProvider);
    if (action == 'delete') {
      final ok = await _confirm(context, '이 일정을 삭제할까요?');
      if (ok) {
        await service.deleteReservation(r.id);
        if (context.mounted) Navigator.pop(context);
      }
    } else if (action == 'deleteBatch' && r.batchId != null) {
      final ok = await _confirm(
        context,
        '반복으로 생성된 그룹 전체를 삭제할까요?',
      );
      if (ok) {
        await service.deleteBatch(r.batchId!);
        if (context.mounted) Navigator.pop(context);
      }
    }
  }

  Future<bool> _confirm(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.reservation, required this.facility});

  final Reservation reservation;
  final Facility? facility;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(facility?.color ?? 0xFF9E9E9E),
            radius: 10,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                facility?.name ?? '(삭제된 시설)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('사용일 ${Fmt.ymdWeekday(reservation.usageDate)}'),
            ],
          ),
          const Spacer(),
          if (reservation.isRecurring)
            const Chip(label: Text('반복'), visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

class _ScheduleList extends ConsumerWidget {
  const _ScheduleList({required this.reservationId, required this.schedules});

  final int reservationId;
  final List<Schedule> schedules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (schedules.isEmpty) {
      return const Center(child: Text('일정이 없어요.'));
    }
    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      itemCount: schedules.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = schedules[i];
        final status = s.statusAt(now);
        final isUsage = s.source == ScheduleSource.usage;
        final done = status == ScheduleStatus.done;
        return ListTile(
          leading: Icon(
            ScheduleVisuals.icon(s.source),
            color: done
                ? Theme.of(context).colorScheme.outline
                : (isUsage
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.primary),
          ),
          title: Text(s.title),
          subtitle: Text(
            '${Fmt.dateTime(s.date)} · ${status.label}'
            '${s.source == ScheduleSource.custom ? ' · 사용자 지정' : ''}',
          ),
          trailing: isUsage
              ? null
              : Switch(
                  value: s.notificationEnabled,
                  onChanged: s.isPastInstant(now)
                      ? null // 지난 스케줄은 알림 토글 불가(계획서 11.1)
                      : (v) async {
                          await ref
                              .read(reservationServiceProvider)
                              .setScheduleNotification(s, v);
                          ref.invalidate(
                              schedulesForReservationProvider(reservationId));
                        },
                ),
        );
      },
    );
  }

}
