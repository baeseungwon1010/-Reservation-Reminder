import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import 'facility_edit_screen.dart';

/// 시설 관리(계획서 4장). 추가/수정/비활성화.
class FacilityListScreen extends ConsumerWidget {
  const FacilityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('시설 관리')),
      body: facilitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (facilities) {
          if (facilities.isEmpty) {
            return const Center(child: Text('시설이 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: facilities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final f = facilities[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(f.color),
                  radius: 10,
                ),
                title: Text(f.name),
                subtitle: Text(f.enabled ? '활성' : '비활성 (신규 등록 불가)'),
                trailing: Switch(
                  value: f.enabled,
                  onChanged: (v) => ref
                      .read(facilityRepositoryProvider)
                      .setEnabled(f.id, v),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FacilityEditScreen(facility: f),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FacilityEditScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('시설 추가'),
      ),
    );
  }
}
