import 'package:flutter/material.dart';

/// 사용자에게 보여줄 오류 정보. 메시지는 통일하고, 원인은 짧은 오류 코드로 구분한다.
class AppError {
  const AppError(this.code);

  final String code;

  /// 사용자에게 보여주는 통일 메시지.
  static const String message = '문제가 생겼습니다. 다시 시도해 주세요.';

  /// 예외를 자주 발생하는 유형으로 분류해 오류 코드를 부여한다.
  factory AppError.from(Object error) {
    final s = error.toString().toLowerCase();
    if (s.contains('sqlite') ||
        s.contains('drift') ||
        s.contains('database')) {
      return const AppError(codeDatabase);
    }
    if (s.contains('notification') ||
        s.contains('alarm') ||
        s.contains('permission')) {
      return const AppError(codeNotification);
    }
    if (s.contains('timezone') || s.contains('tz ')) {
      return const AppError(codeTimezone);
    }
    if (s.contains('socket') ||
        s.contains('network') ||
        s.contains('timeout')) {
      return const AppError(codeNetwork);
    }
    return const AppError(codeUnknown);
  }

  // 자주 발생하는 오류 코드.
  static const String codeDatabase = 'E-DB-01'; // 로컬 저장소 읽기/쓰기
  static const String codeNotification = 'E-NOTI-01'; // 알림 등록/권한
  static const String codeTimezone = 'E-TZ-01'; // 시간대 초기화
  static const String codeNetwork = 'E-NET-01'; // (예비) 네트워크
  static const String codeUnknown = 'E-UNKNOWN'; // 분류되지 않은 오류
}

/// 오류 발생 시 공통으로 보여주는 화면 조각.
/// 통일 메시지 + 아래 작게 오류 코드를 표시한다.
class AppErrorView extends StatelessWidget {
  const AppErrorView(this.error, {super.key, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final appError = AppError.from(error);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 40),
            const SizedBox(height: 12),
            Text(
              AppError.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '오류 코드: ${appError.code}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
