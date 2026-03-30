import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../data/admin_repository.dart';
import '../../widgets/sf_card.dart';

final adminHallsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getAdminHalls();
});

class AdminHallsScreen extends ConsumerWidget {
  const AdminHallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hallsAsync = ref.watch(adminHallsProvider);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Admin · Halls',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: SFColors.gold),
        ),
        backgroundColor: SFColors.charcoal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          TextButton(onPressed: () => context.go('/admin'), child: const Text('Dashboard', style: TextStyle(color: SFColors.gold))),
          TextButton(onPressed: () => context.go('/admin/users'), child: const Text('Users', style: TextStyle(color: SFColors.gold))),
          TextButton(onPressed: () => context.go('/admin/creators'), child: const Text('Creators', style: TextStyle(color: SFColors.gold))),
        ],
      ),
      body: hallsAsync.when(
        data: (halls) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: halls.length,
          itemBuilder: (context, index) {
            final hall = halls[index];
            final name = hall['name'] as String? ?? '—';
            final slug = hall['slug'] as String? ?? '—';
            final owner = hall['owner'] as Map<String, dynamic>?;
            final ownerName = owner?['display_name'] as String? ?? owner?['email'] as String? ?? '—';
            final subCount = hall['sub_count'] as int? ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SFCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: Theme.of(context).textTheme.titleMedium),
                          Text('@$slug', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text('Owner: $ownerName', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text('$subCount subs', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SFColors.gold)),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: SFColors.error))),
      ),
    );
  }
}
