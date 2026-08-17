import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/constants/app_constants.dart';

/// 설정 화면. MVP 범위에서는 알림 권한/동기화 위주.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const _SectionHeader('알림'),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('알림 권한 요청'),
            subtitle: const Text('알림이 오지 않으면 권한을 다시 확인하세요.'),
            onTap: () async {
              final granted = await ref
                  .read(notificationManagerProvider)
                  .requestPermissions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(granted ? '알림 권한 허용됨' : '알림 권한이 거부되었습니다.'),
                  ),
                );
              }
            },
          ),
          const Divider(),
          const _SectionHeader('정보'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppConstants.appName),
            subtitle: Text('v1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('데이터 저장'),
            subtitle: Text('해당 앱은 동기화가 적용되지 않으며 기기 내부에만 저장됩니다.'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
