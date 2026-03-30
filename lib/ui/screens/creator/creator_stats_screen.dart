import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../ui/widgets/sf_card.dart';
import '../../../core/session/session_provider.dart';
import 'creator_dashboard_screen.dart'; // For creatorStatsProvider

class CreatorStatsScreen extends ConsumerWidget {
  const CreatorStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    
    if (session.creatorHallId == null) {
      return Scaffold(
        backgroundColor: SFColors.black,
        body: Center(
          child: Text(
            'No hall found',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final hallId = session.creatorHallId!;
    final statsAsync = ref.watch(creatorStatsProvider(hallId));

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Stats',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: SFColors.gold,
          ),
        ),
        backgroundColor: SFColors.charcoal,
      ),
      body: statsAsync.when(
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subscriber Count
                SFCard(
                  child: Column(
                    children: [
                      const Icon(Icons.people, color: SFColors.gold, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        '${stats['subscriber_count'] ?? 0}',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: SFColors.gold,
                        ),
                      ),
                      Text(
                        'Total Subscribers',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Views
                SFCard(
                  child: Column(
                    children: [
                      const Icon(Icons.visibility, color: SFColors.gold, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        '${stats['views_7d'] ?? 0}',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: SFColors.gold,
                        ),
                      ),
                      Text(
                        'Views (Last 7 Days)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Top Posts/Videos placeholder
                SFCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOP CONTENT',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: SFColors.gold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Coming soon',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
