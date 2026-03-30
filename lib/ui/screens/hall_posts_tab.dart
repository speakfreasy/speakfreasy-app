import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../ui/widgets/sf_card.dart';
import '../../ui/widgets/sf_avatar.dart';
import '../../data/post_repository.dart';
import '../../core/session/session_provider.dart';
import '../../ui/screens/creator/creator_new_post_screen.dart';
import '../../ui/widgets/post_comments_sheet.dart';
import 'hall_interior_screen.dart'; // For hallBySlugProvider and isSubscribedProvider

// Fetches all post IDs the current user has liked in a hall — single batch query
final userLikedPostIdsProvider = FutureProvider.family<Set<String>, String>((ref, key) async {
  final idx = key.indexOf('_');
  if (idx == -1) return {};
  final userId = key.substring(0, idx);
  final hallId = key.substring(idx + 1);
  return await ref.read(postRepositoryProvider).getLikedPostIdsInHall(userId, hallId);
});

// Optimistic local overrides so likes feel instant
// Map<postId, (isLiked, count)>
final postLikeOverridesProvider =
    StateProvider<Map<String, ({bool isLiked, int count})>>((ref) => {});

// Tracks posts whose like is currently in-flight — prevents double-fires
final _pendingLikeIdsProvider = StateProvider<Set<String>>((ref) => {});

// Set this before navigating to /hall/:slug/posts to auto-open comments for a post
final pendingCommentsPostIdProvider = StateProvider<String?>((ref) => null);

class HallPostsTab extends ConsumerStatefulWidget {
  final String slug;

  const HallPostsTab({super.key, required this.slug});

  @override
  ConsumerState<HallPostsTab> createState() => _HallPostsTabState();
}

class _HallPostsTabState extends ConsumerState<HallPostsTab> {
  bool _didAutoOpenComments = false;

  Future<void> _deletePost(
    BuildContext context,
    String postId,
    String hallId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SFColors.charcoal,
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(postRepositoryProvider).deletePost(postId);
    ref.invalidate(hallPostsProvider(hallId));
  }

  void _toggleLike(
    String postId,
    bool currentIsLiked,
    int currentCount,
  ) async {
    // Ignore tap if this post's like is already in-flight
    if (ref.read(_pendingLikeIdsProvider).contains(postId)) return;

    // Mark in-flight
    ref.read(_pendingLikeIdsProvider.notifier).update((s) => {...s, postId});

    // Optimistic update — responds immediately
    ref.read(postLikeOverridesProvider.notifier).update((state) => {
          ...state,
          postId: (
            isLiked: !currentIsLiked,
            count: currentIsLiked ? currentCount - 1 : currentCount + 1,
          ),
        });

    try {
      await ref.read(postRepositoryProvider).togglePostLike(postId);
    } catch (_) {
      // Revert on failure
      ref.read(postLikeOverridesProvider.notifier).update((state) => {
            ...state,
            postId: (isLiked: currentIsLiked, count: currentCount),
          });
    } finally {
      // Always clear the in-flight marker
      ref
          .read(_pendingLikeIdsProvider.notifier)
          .update((s) => s.where((id) => id != postId).toSet());
    }
  }

  void _autoOpenComments(BuildContext context, String postId, bool canComment) {
    if (_didAutoOpenComments) return;
    _didAutoOpenComments = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingCommentsPostIdProvider.notifier).state = null;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) => PostCommentsSheet(
            postId: postId,
            canComment: canComment,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hallAsync = ref.watch(hallBySlugProvider(widget.slug));
    final session = ref.watch(sessionProvider);

    // Derive hallId early so liked-IDs provider can be watched at build level
    final hallId = hallAsync.value?['id'] as String? ?? '';
    final likedIdsAsync = session.userId != null && hallId.isNotEmpty
        ? ref.watch(userLikedPostIdsProvider('${session.userId}_$hallId'))
        : const AsyncValue.data(<String>{});
    final likedIds = likedIdsAsync.value ?? {};
    final likeOverrides = ref.watch(postLikeOverridesProvider);
    final pendingLikeIds = ref.watch(_pendingLikeIdsProvider);

    // Compute isCreator at top level for the FAB
    final creators = hallAsync.value?['creators'] as List<dynamic>?;
    final creatorProfileId = creators?.isNotEmpty == true
        ? creators![0]['profile_id'] as String?
        : null;
    final isCreatorForFab =
        session.userId != null && creatorProfileId == session.userId;

    // isSubscribedForFab: resolved from async value (null = still loading → hide FAB)
    final isSubscribedForFab =
        hallAsync.value != null && session.isAuthenticated && session.userId != null
            ? ref
                .watch(isSubscribedProvider('${session.userId!}_${hallId}'))
                .value ??
                false
            : false;

    final canPost = isCreatorForFab || isSubscribedForFab;

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Posts'),
        backgroundColor: SFColors.charcoal,
      ),
      floatingActionButton: canPost
          ? FloatingActionButton.small(
              onPressed: () async {
                // Creators use their own hallId from the session; subscribers
                // need to tell the post screen which hall to post to.
                if (!isCreatorForFab) {
                  ref.read(hallBeingPostedToProvider.notifier).state = hallId;
                }
                await context.push('/creator/post/new');
                if (hallId.isNotEmpty) {
                  ref.invalidate(hallPostsProvider(hallId));
                }
              },
              backgroundColor: SFColors.gold,
              foregroundColor: SFColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: hallAsync.when(
        data: (hall) {
          if (hall == null) {
            return const Center(child: Text('Hall not found'));
          }

          final postsAsync = ref.watch(hallPostsProvider(hall['id'] as String));
          final isSubscribedAsync = session.isAuthenticated && session.userId != null
              ? ref.watch(isSubscribedProvider('${session.userId!}_${hall['id']}'))
              : const AsyncValue.data(false);

          // Creators always have full access
          final hallCreators = hall['creators'] as List<dynamic>?;
          final hallCreatorProfileId = hallCreators?.isNotEmpty == true
              ? hallCreators![0]['profile_id'] as String?
              : null;
          final isCreator =
              session.userId != null && hallCreatorProfileId == session.userId;

          return postsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return Center(
                  child: Text(
                    'No posts yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }

              // Auto-open comments if navigated from notifications
              final pendingPostId = ref.read(pendingCommentsPostIdProvider);
              if (pendingPostId != null && posts.any((p) => p['id'] == pendingPostId)) {
                final isSubscribed = isCreator || (isSubscribedAsync.value ?? false);
                _autoOpenComments(context, pendingPostId, isSubscribed);
              }

              final pinnedPosts =
                  posts.where((p) => p['pinned'] == true).toList();
              final regularPosts =
                  posts.where((p) => p['pinned'] != true).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pinnedPosts.length + regularPosts.length,
                itemBuilder: (context, index) {
                  final Map<String, dynamic> post;
                  final bool isPinned;

                  if (index < pinnedPosts.length) {
                    post = pinnedPosts[index];
                    isPinned = true;
                  } else {
                    post = regularPosts[index - pinnedPosts.length];
                    isPinned = false;
                  }

                  final profile = post['profiles'] as Map<String, dynamic>?;
                  final isSubscribed =
                      isCreator || (isSubscribedAsync.value ?? false);
                  final postId = post['id'] as String;

                  // Resolve the first image from post_media join
                  final mediaList = post['post_media'] as List<dynamic>?;
                  final firstImage = mediaList
                      ?.where((m) => m['type'] == 'image')
                      .isNotEmpty == true
                      ? mediaList!.firstWhere((m) => m['type'] == 'image')
                      : null;
                  final imageUrl = firstImage?['url'] as String?;

                  // Resolve like state: local override wins over server data
                  final override = likeOverrides[postId];
                  final isLiked =
                      override?.isLiked ?? likedIds.contains(postId);
                  final likeCount =
                      override?.count ?? (post['like_count'] as int? ?? 0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SFCard(
                      decorativeCorners: isPinned,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPinned)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.push_pin,
                                      size: 16, color: SFColors.gold),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PINNED',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: SFColors.gold),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              SFAvatar(
                                imageUrl: profile?['avatar_url'] as String?,
                                displayName:
                                    profile?['display_name'] as String?,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile?['display_name'] as String? ??
                                          'Unknown',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    Text(
                                      _formatTime(
                                          post['created_at'] as String?),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              // 3-dot menu for author / creator / admin
                              Builder(builder: (ctx) {
                                final isAuthor = session.userId == post['author_id'];
                                final isAdmin = session.role?.toLowerCase() == 'admin';
                                if (!isAuthor && !isCreator && !isAdmin) {
                                  return const SizedBox.shrink();
                                }
                                return PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: SFColors.creamMuted,
                                    size: 20,
                                  ),
                                  color: SFColors.charcoal,
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      ref.read(postBeingEditedProvider.notifier).state = post;
                                      await context.push('/creator/post/new');
                                      ref.invalidate(hallPostsProvider(hall['id'] as String));
                                    } else if (value == 'delete') {
                                      await _deletePost(context, postId, hall['id'] as String);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    if (isAuthor)
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post['body'] as String? ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (imageUrl != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Like / comment row
                          Row(
                            children: [
                              GestureDetector(
                                onTap: isSubscribed && !pendingLikeIds.contains(postId)
                                    ? () => _toggleLike(postId, isLiked, likeCount)
                                    : null,
                                child: Row(
                                  children: [
                                    Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 20,
                                      color: isLiked
                                          ? Colors.red
                                          : SFColors.creamMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$likeCount',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => DraggableScrollableSheet(
                                    initialChildSize: 0.6,
                                    minChildSize: 0.4,
                                    maxChildSize: 0.92,
                                    expand: false,
                                    builder: (_, scrollController) => PostCommentsSheet(
                                      postId: postId,
                                      canComment: isSubscribed,
                                      onCommentAdded: () => ref.invalidate(hallPostsProvider(hall['id'] as String)),
                                    ),
                                  ),
                                ),
                                child: Row(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    size: 20,
                                    color: isSubscribed
                                        ? SFColors.creamMuted
                                        : SFColors.creamMuted.withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post['comment_count'] ?? 0}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              ),
                            ],
                          ),
                          if (!isSubscribed)
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SFColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: SFColors.gold),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock,
                                      color: SFColors.gold, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Subscribe to like and comment',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: SFColors.gold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(time);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}

final hallPostsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, hallId) async {
  return await ref.read(postRepositoryProvider).getHallPosts(hallId);
});
