import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../ui/widgets/sf_card.dart';
import '../../ui/widgets/sf_avatar.dart';
import '../../ui/widgets/sf_bottom_tab_bar.dart';
import '../../ui/widgets/sf_button.dart';
import '../../data/hall_repository.dart';
import '../../core/session/session_provider.dart';
import 'halls_screen.dart'; // For allHallsProvider

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    
    if (!session.hasAnyActiveSub) {
      return Scaffold(
        backgroundColor: SFColors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 64,
                color: SFColors.gold,
              ),
              const SizedBox(height: 16),
              Text(
                'Subscribe to a hall to access discovery',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SFButton(
                label: 'Browse Halls',
                onPressed: () => context.go('/halls'),
              ),
            ],
          ),
        ),
      );
    }

    final allHallsAsync = ref.watch(allHallsProvider);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Discover',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: SFColors.gold,
          ),
        ),
        backgroundColor: SFColors.charcoal,
      ),
      body: allHallsAsync.when(
        data: (halls) {
          if (halls.isEmpty) {
            return Center(
              child: Text(
                'No halls available',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'RECOMMENDED HALLS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: SFColors.gold,
                ),
              ),
              const SizedBox(height: 16),
              ...halls.map((hall) {
                final creators = hall['creators'] as List<dynamic>?;
                final creator = creators?.isNotEmpty == true ? creators![0] : null;
                final profile = creator?['profiles'] as Map<String, dynamic>?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SFCard(
                    onTap: () => context.go('/hall/${hall['slug']}'),
                    child: Row(
                      children: [
                        SFAvatar(
                          imageUrl: profile?['avatar_url'] as String?,
                          displayName: profile?['display_name'] as String?,
                          size: 60,
                          showCreatorRing: true,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hall['name'] as String? ?? 'Unknown Hall',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile?['display_name'] as String? ?? 'Unknown Creator',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 16,
                                    color: SFColors.creamMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${hall['subscriber_count'] ?? 0} subscribers',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '\$${(hall['price_cents'] as int? ?? 0) / 100}/mo',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: SFColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SFButton(
                          label: 'Subscribe',
                          variant: SFButtonVariant.secondary,
                          onPressed: () {
                            // TODO: Stripe checkout
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Subscription checkout coming soon'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
