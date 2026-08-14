import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models/schedule.dart';

/// OS 로컬 알림 관리(계획서 14·15장).
///
/// - DB 의 Schedule 을 원본으로 보고, OS 알림은 그로부터 파생되는 정보로 취급한다.
/// - 각 Schedule 의 알림 ID 로는 Schedule.id 를 그대로 사용한다(고유·안정적).
class NotificationManager {
  NotificationManager([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'reservation_reminders';
  static const String _channelName = '예약 알림';
  static const String _channelDesc = '시설 예약 규칙에 따른 예약/확인 알림';

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (e) {
      // 시간대 조회 실패 시 UTC 로 폴백(계획서 16장: 기기 시간 신뢰가 원칙).
      debugPrint('Timezone 초기화 실패, UTC 사용: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    _initialized = true;
  }

  /// 알림 권한 요청. 승인 여부를 반환한다.
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      // 정시 알림(Android 12+). 거부되어도 앱은 동작한다.
      await android.requestExactAlarmsPermission();
      return granted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  /// 단일 스케줄 알림 예약. 이미 지난 시각이면 등록하지 않고 false 를 반환한다.
  Future<bool> scheduleFor(Schedule schedule) async {
    await init();
    final now = DateTime.now();
    if (!schedule.notificationEnabled || schedule.isPastInstant(now)) {
      return false;
    }

    final when = tz.TZDateTime.from(schedule.date, tz.local);
    await _plugin.zonedSchedule(
      schedule.id, // 알림 ID = Schedule.id
      _title(schedule),
      _body(schedule),
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'schedule:${schedule.id}',
    );
    return true;
  }

  Future<void> cancel(int notificationId) async {
    await init();
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<Set<int>> pendingIds() async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((p) => p.id).toSet();
  }

  /// DB 의 "미래 + 알림 활성" 스케줄과 OS 예약 상태를 일치시킨다(계획서 15장).
  ///
  /// - 필요한데 없으면 등록
  /// - OS 에는 있는데 DB 기준으로 불필요하면 제거
  ///
  /// 앱 시작 시, 그리고 대량 변경(반복 삭제/업데이트) 후 호출한다.
  Future<void> sync(List<Schedule> desiredFutureSchedules) async {
    await init();

    final desired = {
      for (final s in desiredFutureSchedules)
        if (s.notificationEnabled && !s.isPastInstant(DateTime.now())) s.id: s,
    };
    final pending = await pendingIds();

    // 불필요한 OS 알림 제거.
    for (final id in pending) {
      if (!desired.containsKey(id)) {
        await _plugin.cancel(id);
      }
    }

    // 누락된 알림 등록.
    for (final entry in desired.entries) {
      if (!pending.contains(entry.key)) {
        await scheduleFor(entry.value);
      }
    }
  }

  String _title(Schedule s) => '예약 알림';

  String _body(Schedule s) => s.title;
}
