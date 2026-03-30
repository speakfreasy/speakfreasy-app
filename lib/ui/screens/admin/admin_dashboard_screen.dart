import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../data/admin_repository.dart';
import '../../widgets/sf_card.dart';

final adminCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getCounts();
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(adminCountsProvider);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Admin',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: SFColors.gold),
        ),
        backgroundColor: SFColors.charcoal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/admin/halls'),
            child: const Text('Halls', style: TextStyle(color: SFColors.gold)),
          ),
          TextButton(
            onPressed: () => context.go('/admin/users'),
            child: const Text('Users', style: TextStyle(color: SFColors.gold)),
          ),
          TextButton(
            onPressed: () => context.go('/admin/creators'),
            child: const Text('Creators', style: TextStyle(color: SFColors.gold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: SFColors.gold),
            ),
            const SizedBox(height: 16),
            countsAsync.when(
              data: (counts) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SFCard(
                          child: Column(
                            children: [
                              const Icon(Icons.people, color: SFColors.gold, size: 32),
                              const SizedBox(height: 8),
                              Text('${counts['users'] ?? 0}', style: Theme.of(context).textTheme.headlineMedium),
                              Text('Users', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SFCard(
                          child: Column(
                            children: [
                              const Icon(Icons.storefront, color: SFColors.gold, size: 32),
                              const SizedBox(height: 8),
                              Text('${counts['halls'] ?? 0}', style: Theme.of(context).textTheme.headlineMedium),
                              Text('Halls', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SFCard(
                          child: Column(
                            children: [
                              const Icon(Icons.person, color: SFColors.gold, size: 32),
                              const SizedBox(height: 8),
                              Text('${counts['creators'] ?? 0}', style: Theme.of(context).textTheme.headlineMedium),
                              Text('Creators', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SFCard(
                          child: Column(
                            children: [
                              const Icon(Icons.card_membership, color: SFColors.gold, size: 32),
                              const SizedBox(height: 8),
                              Text('${counts['activeSubscriptions'] ?? 0}', style: Theme.of(context).textTheme.headlineMedium),
                              Text('Active subs', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: SFColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}
