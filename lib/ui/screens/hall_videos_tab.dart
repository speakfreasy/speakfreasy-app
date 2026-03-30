import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../ui/widgets/sf_card.dart';
import '../../data/hall_repository.dart';
import '../../data/video_repository.dart';
import '../../data/subscription_repository.dart';
import '../../core/session/session_provider.dart';
import 'hall_interior_screen.dart'; // For hallBySlugProvider and isSubscribedProvider

class HallVideosTab extends ConsumerWidget {
  final String slug;

  const HallVideosTab({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hallAsync = ref.watch(hallBySlugProvider(slug));
    final session = ref.watch(sessionProvider);

    // Derive isCreator from cached hall data for the AppBar action
    final hallValue = hallAsync.value;
    final creators = hallValue?['creators'] as List<dynamic>?;
    final creatorProfileId = creators?.isNotEmpty == true
        ? creators![0]['profile_id'] as String?
        : null;
    final isCreatorTop = session.userId != null && creatorProfileId == session.userId;

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Videos'),
        backgroundColor: SFColors.charcoal,
        actions: [
          if (isCreatorTop)
            IconButton(
              icon: const Icon(Icons.add, color: SFColors.gold),
              tooltip: 'Upload Video',
              onPressed: () => context.push('/creator/video/upload'),
            ),
        ],
      ),
      body: hallAsync.when(
        data: (hall) {
          if (hall == null) {
            return const Center(child: Text('Hall not found'));
          }

          final hallId = hall['id'] as String;
          final videosAsync = ref.watch(hallVideosProvider(hallId));
          final isSubscribedAsync = session.isAuthenticated && session.userId != null
              ? ref.watch(isSubscribedProvider('${session.userId!}_$hallId'))
              : const AsyncValue.data(false);

          // Creators always have full access to their own hall
          final isCreator = isCreatorTop;

          return videosAsync.when(
            data: (videos) {
              if (videos.isEmpty) {
                return Center(
                  child: Text(
                    'No videos yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  final isSubscribed = isCreator || (isSubscribedAsync.value ?? false);

                  return SFCard(
                    onTap: isSubscribed
                        ? () {
                            final libraryId = video['bunny_library_id'] as String? ?? '';
                            final videoId = video['bunny_video_id'] as String? ?? '';
                            final title = Uri.encodeComponent(
                                video['title'] as String? ?? '');
                            context.push('/video/$libraryId/$videoId?title=$title');
                          }
                        : () {
                            // TODO: Show paywall
                          },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: SFColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    size: 48,
                                    color: SFColors.gold,
                                  ),
                                ),
                                if (!isSubscribed)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: SFColors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.lock,
                                        size: 16,
                                        color: SFColors.gold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          video['title'] as String? ?? 'Untitled',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${video['view_count'] ?? 0} views • ${_formatTime(video['created_at'] as String?)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
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

final hallVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, hallId) async {
  final videoRepo = ref.read(videoRepositoryProvider);
  return await videoRepo.getHallVideos(hallId);
});
