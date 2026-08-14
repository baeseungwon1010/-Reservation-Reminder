import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/calendar/calendar_screen.dart';

class ReservationReminderApp extends ConsumerWidget {
  const ReservationReminderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 앱 시작 초기화(알림 권한 + 동기화)를 백그라운드로 트리거.
    ref.listen(startupProvider, (_, __) {});

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      home: const CalendarScreen(),
    );
  }
}
