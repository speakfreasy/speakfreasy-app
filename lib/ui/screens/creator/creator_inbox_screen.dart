import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../ui/widgets/sf_card.dart';
import '../../../ui/widgets/sf_avatar.dart';
import '../../../data/comment_repository.dart';
import '../../../core/session/session_provider.dart';
import 'creator_dashboard_screen.dart'; // For recentCommentsProvider

class CreatorInboxScreen extends ConsumerWidget {
  const CreatorInboxScreen({super.key});

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
    final commentsAsync = ref.watch(recentCommentsProvider(hallId));

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Inbox',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: SFColors.gold,
          ),
        ),
        backgroundColor: SFColors.charcoal,
      ),
      body: commentsAsync.when(
        data: (comments) {
          if (comments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: SFColors.creamMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No comments yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comments on your posts and videos will appear here',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              final profile = comment['profiles'] as Map<String, dynamic>?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SFCard(
                  onTap: () {
                    // TODO: Navigate to comment context
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const Icon(
                        Icons.chevron_right,
                        color: SFColors.gold,
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
