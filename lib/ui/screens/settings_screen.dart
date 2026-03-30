import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../ui/widgets/sf_card.dart';
import '../../ui/widgets/sf_avatar.dart';
import '../../ui/widgets/sf_bottom_tab_bar.dart';
import '../../ui/widgets/sf_button.dart';
import '../../ui/widgets/sf_divider.dart';
import '../../data/auth_repository.dart';
import '../../data/profile_repository.dart';
import '../../data/subscription_repository.dart';
import '../../core/session/session_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final profileAsync = session.isAuthenticated && session.userId != null
        ? ref.watch(currentProfileProvider(session.userId!))
        : const AsyncValue.data(null);
    final subscriptionsAsync = session.isAuthenticated && session.userId != null
        ? ref.watch(userSubscriptionsProvider(session.userId!))
        : const AsyncValue.data(<Map<String, dynamic>>[]);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: SFColors.gold,
          ),
        ),
        backgroundColor: SFColors.charcoal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          SFCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROFILE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SFColors.gold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SFAvatar(
                      displayName: session.role?.trim().toLowerCase() == 'admin' ? 'Admin' : 'User',
                      size: 60,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.userId ?? 'Unknown',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            session.role?.trim().toLowerCase() ?? 'subscriber',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          profileAsync.when(
                            data: (profile) {
                              final dbRole = profile?['role']?.toString();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'DB role: ${dbRole ?? "null"}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SFColors.creamMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (e, _) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'DB error: $e',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: SFColors.error,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // My Subscriptions
          SFCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY SUBSCRIPTIONS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SFColors.gold,
                  ),
                ),
                const SizedBox(height: 16),
                subscriptionsAsync.when(
                  data: (subscriptions) {
                    if (subscriptions.isEmpty) {
                      return Text(
                        'No active subscriptions',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }
                    return Column(
                      children: subscriptions.map((sub) {
                        final hall = sub['halls'] as Map<String, dynamic>?;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hall?['name'] as String? ?? 'Unknown Hall',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    Text(
                                      'Active',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: SFColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Cancel subscription
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Logout
          SFButton(
            label: 'Logout',
            variant: SFButtonVariant.secondary,
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
              ref.read(sessionProvider.notifier).refresh();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

final currentProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final repo = ref.read(profileRepositoryProvider);
  return await repo.getProfile(userId);
});

final userSubscriptionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final subRepo = ref.read(subscriptionRepositoryProvider);
  return await subRepo.getUserSubscriptions(userId);
});
