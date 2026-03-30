import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../ui/widgets/sf_card.dart';
import '../../ui/widgets/sf_avatar.dart';
import '../../ui/widgets/sf_badge.dart';
import '../../ui/widgets/sf_button.dart';
import '../../data/hall_repository.dart';
import '../../data/subscription_repository.dart';
import '../../core/session/session_provider.dart';

class HallInteriorScreen extends ConsumerWidget {
  final String slug;

  const HallInteriorScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hallAsync = ref.watch(hallBySlugProvider(slug));
    final session = ref.watch(sessionProvider);
    final hallId = hallAsync.value?['id'] as String? ?? '';
    final isSubscribedAsync = session.isAuthenticated && session.userId != null && hallId.isNotEmpty
        ? ref.watch(isSubscribedProvider('${session.userId!}_$hallId'))
        : const AsyncValue.data(false);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: SFColors.charcoal,
        actions: hallAsync.maybeWhen(
          data: (hall) {
            if (hall == null) return null;

            final creators = hall['creators'] as List<dynamic>?;
            final creator = creators?.isNotEmpty == true ? creators![0] : null;
            final creatorProfileId = creator?['profile_id'] as String?;
            final isCreator = session.userId != null && creatorProfileId == session.userId;

            if (isCreator) {
              return [
                IconButton(
                  icon: const Icon(Icons.settings, color: SFColors.gold),
                  tooltip: 'Manage Hall',
                  onPressed: () {
                    final id = hall['id'] as String;
                    context.push('/hall/$slug/settings?hallId=$id');
                  },
                ),
              ];
            }
            return null;
          },
          orElse: () => null,
        ),
      ),
      body: hallAsync.when(
        data: (hall) {
          if (hall == null) {
            return Center(
              child: Text(
                'Hall not found',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final creators = hall['creators'] as List<dynamic>?;
          final creator = creators?.isNotEmpty == true ? creators![0] : null;
          final profile = creator?['profiles'] as Map<String, dynamic>?;
          final creatorProfileId = creator?['profile_id'] as String?;
          final isCreator = session.userId != null && creatorProfileId == session.userId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hall banner
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: SFColors.charcoal,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SFColors.gold.withOpacity(0.2),
                        SFColors.charcoal,
                      ],
                    ),
                    image: hall['banner_url'] != null
                        ? DecorationImage(
                            image: NetworkImage(hall['banner_url'] as String),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                // Creator profile section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SFAvatar(
                        imageUrl: hall['avatar_url'] as String? ?? profile?['avatar_url'] as String?,
                        displayName: hall['name'] as String?,
                        size: 80,
                        showCreatorRing: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    hall['name'] as String? ?? 'Unknown Hall',
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                ),
                                isSubscribedAsync.when(
                                  data: (isSubscribed) => isSubscribed
                                      ? const SFBadge(
                                          label: 'SUBSCRIBED',
                                          variant: SFBadgeVariant.success,
                                        )
                                      : const SizedBox.shrink(),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@$slug • ${hall['subscriber_count'] ?? 0} subscribers',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              hall['bio'] as String? ?? hall['description'] as String? ?? 'No description available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (!isCreator &&
                                (!isSubscribedAsync.hasValue || !isSubscribedAsync.value!)) ...[
                              const SizedBox(height: 16),
                              SFButton(
                                label: 'Subscribe',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Subscription checkout coming soon'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Section cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      _SectionCard(
                        icon: Icons.article_outlined,
                        title: 'Posts',
                        onTap: () => context.push('/hall/$slug/posts'),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        icon: Icons.play_circle_outline,
                        title: 'Videos',
                        onTap: () => context.push('/hall/$slug/videos'),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'Chat',
                        onTap: () => context.push('/hall/$slug/chat'),
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
          child: Text(
            'Error: $error',
            style: const TextStyle(color: SFColors.error),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SFCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: SFColors.gold, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Icon(Icons.chevron_right, color: SFColors.creamMuted),
        ],
      ),
    );
  }
}

final hallBySlugProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, slug) async {
  final hallRepo = ref.read(hallRepositoryProvider);
  return await hallRepo.getHallBySlug(slug);
});

final isSubscribedProvider = FutureProvider.family<bool, String>((ref, key) async {
  final parts = key.split('_');
  if (parts.length < 2) return false;
  final userId = parts[0];
  final hallId = parts.sublist(1).join('_');
  final subRepo = ref.read(subscriptionRepositoryProvider);
  return await subRepo.isSubscribedToHall(userId, hallId);
});
