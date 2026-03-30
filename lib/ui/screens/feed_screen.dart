import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../ui/widgets/sf_card.dart';
import '../../ui/widgets/sf_avatar.dart';
import '../../ui/widgets/sf_bottom_tab_bar.dart';
import '../../ui/widgets/sf_button.dart';
import '../../data/post_repository.dart';
import '../../core/session/session_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

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
                'Subscribe to a hall to access the feed',
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

    final feedPostsAsync = ref.watch(feedPostsProvider);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Freasy Feed',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: SFColors.gold,
          ),
        ),
        backgroundColor: SFColors.charcoal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: SFColors.gold),
            onPressed: () {
              // TODO: Open post composer
            },
          ),
        ],
      ),
      body: feedPostsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.dynamic_feed_outlined,
                    size: 64,
                    color: SFColors.creamMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posts from your subscribed halls will appear here',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final profile = post['profiles'] as Map<String, dynamic>?;
              final hall = post['halls'] as Map<String, dynamic>?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SFCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SFAvatar(
                            imageUrl: profile?['avatar_url'] as String?,
                            displayName: profile?['display_name'] as String?,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?['display_name'] as String? ?? 'Unknown',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  hall?['name'] as String? ?? 'Unknown Hall',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTime(post['created_at'] as String?),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post['body'] as String? ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (post['image_url'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: SFColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.network(
                            post['image_url'] as String,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_border, size: 20),
                            onPressed: () {
                              // TODO: Like post
                            },
                          ),
                          Text(
                            '${post['like_count'] ?? 0}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.comment_outlined, size: 20),
                            onPressed: () {
                              // TODO: Show comments
                            },
                          ),
                          Text(
                            '${post['comment_count'] ?? 0}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
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

final feedPostsProvider = FutureProvider((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isAuthenticated || session.userId == null) {
    return <Map<String, dynamic>>[];
  }
  final postRepo = ref.read(postRepositoryProvider);
  return await postRepo.getFreasyFeedPosts(session.userId!);
});
