import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../ui/widgets/sf_card.dart';
import '../../../ui/widgets/sf_button.dart';
import '../../../ui/widgets/sf_badge.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/hall_repository.dart';
import '../../../data/comment_repository.dart';

class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

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
    final recentCommentsAsync = ref.watch(recentCommentsProvider(hallId));
    final hallDataAsync = ref.watch(creatorHallDataProvider(hallId));

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Creator Dashboard',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: SFColors.gold,
          ),
        ),
        backgroundColor: SFColors.charcoal,
        actions: [
          // Hall Settings Button
          hallDataAsync.when(
            data: (hall) {
              if (hall == null) return const SizedBox.shrink();
              final slug = hall['slug'] as String?;
              if (slug == null) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.settings, color: SFColors.gold),
                tooltip: 'Hall Settings',
                onPressed: () => context.push('/hall/$slug/settings?hallId=$hallId'),
              );
            },
            loading: () => const SizedBox(width: 48),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Profile Settings Button
          IconButton(
            icon: const Icon(Icons.person, color: SFColors.gold),
            tooltip: 'Profile Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: statsAsync.when(
                    data: (stats) => SFCard(
                      child: Column(
                        children: [
                          const Icon(Icons.people, color: SFColors.gold, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '${stats['subscriber_count'] ?? 0}',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          Text(
                            'Subscribers',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SFCard(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SFCard(
                      child: Text('Error'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: statsAsync.when(
                    data: (stats) => SFCard(
                      child: Column(
                        children: [
                          const Icon(Icons.visibility, color: SFColors.gold, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '${stats['views_7d'] ?? 0}',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          Text(
                            'Views (7d)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SFCard(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SFCard(
                      child: Text('Error'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Quick Actions
            Text(
              'QUICK ACTIONS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SFColors.gold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SFCard(
                    onTap: () => context.go('/creator/post/new'),
                    child: Column(
                      children: [
                        const Icon(Icons.edit, color: SFColors.gold, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'New Post',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Share update',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SFCard(
                    onTap: () => context.push('/creator/video/upload'),
                    child: Column(
                      children: [
                        const Icon(Icons.video_library, color: SFColors.gold, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Upload Video',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Via Bunny.net',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Estimated Earnings
            Text(
              'EST. EARNINGS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SFColors.gold,
              ),
            ),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (stats) => SFCard(
                decorativeCorners: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${stats['estimated_earnings'] ?? '0.00'}',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: SFColors.gold,
                          ),
                        ),
                        const SFBadge(
                          label: 'THIS MONTH',
                          variant: SFBadgeVariant.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${stats['subscriber_count'] ?? 0} subs x \$${stats['payout_per_sub'] ?? '0.60'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pricing set by SpeakFreasy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SFColors.creamMuted,
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SFCard(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SFCard(
                child: Text('Error'),
              ),
            ),
            const SizedBox(height: 24),
            // Recent Comments
            Text(
              'RECENT COMMENTS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SFColors.gold,
              ),
            ),
            const SizedBox(height: 12),
            recentCommentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return SFCard(
                    child: Center(
                      child: Text(
                        'No comments yet',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }
                return Column(
                  children: comments.take(5).map((comment) {
                    final profile = comment['profiles'] as Map<String, dynamic>?;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SFCard(
                        onTap: () {
                          // TODO: Navigate to comment context
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?['display_name'] as String? ?? 'Unknown',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment['body'] as String? ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(comment['created_at'] as String?),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading comments'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inMinutes}m ago';
      }
    } catch (e) {
      return '';
    }
  }
}

final creatorStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, hallId) async {
  // TODO: Implement actual stats query
  // For now, return placeholder data
  return {
    'subscriber_count': 0,
    'views_7d': 0,
    'estimated_earnings': '0.00',
    'payout_per_sub': '0.60',
  };
});

final recentCommentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, hallId) async {
  final commentRepo = ref.read(commentRepositoryProvider);
  return await commentRepo.getRecentCommentsForCreator(creatorHallId: hallId);
});

final creatorHallDataProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, hallId) async {
  final hallRepo = ref.read(hallRepositoryProvider);
  return await hallRepo.getHallById(hallId);
});
