import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/comment_repository.dart';
import '../../ui/widgets/sf_avatar.dart';

final postCommentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, postId) async {
  return await ref.read(commentRepositoryProvider).getPostComments(postId);
});

class PostCommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  final bool canComment;
  final void Function()? onCommentAdded; // called after a comment is submitted

  const PostCommentsSheet({
    super.key,
    required this.postId,
    required this.canComment,
    this.onCommentAdded,
  });

  @override
  ConsumerState<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends ConsumerState<PostCommentsSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;

  // Optimistic comments added this session
  final List<Map<String, dynamic>> _optimisticComments = [];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    _controller.clear();

    // Optimistic entry
    final optimistic = {
      'id': 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      'body': body,
      'created_at': DateTime.now().toIso8601String(),
      'profiles': null,
    };
    setState(() => _optimisticComments.add(optimistic));

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final result = await ref.read(commentRepositoryProvider).createComment(
            parentType: 'post',
            parentId: widget.postId,
            body: body,
          );
      // Replace optimistic with real
      setState(() {
        final idx = _optimisticComments.indexWhere((c) => c['id'] == optimistic['id']);
        if (idx != -1) _optimisticComments[idx] = result;
      });
      widget.onCommentAdded?.call();
      // Refresh server list in background
      ref.invalidate(postCommentsProvider(widget.postId));
    } catch (e) {
      // Remove optimistic on failure and restore text
      setState(() {
        _optimisticComments.remove(optimistic);
        _controller.text = body;
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Container(
      decoration: const BoxDecoration(
        color: SFColors.charcoal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
            child: Row(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SFColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SFColors.border),

          // Comments list
          Expanded(
            child: commentsAsync.when(
              data: (serverComments) {
                // Merge server + optimistic, dedup by id
                final serverIds = serverComments.map((c) => c['id']).toSet();
                final extras = _optimisticComments
                    .where((c) => !serverIds.contains(c['id']))
                    .toList();
                final all = [...serverComments, ...extras];

                if (all.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: SFColors.creamMuted),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: all.length,
                  itemBuilder: (context, i) => _CommentTile(comment: all[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),

          // Input row
          if (widget.canComment)
            SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: SFColors.border)),
                  color: SFColors.charcoal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: SFColors.creamMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: SFColors.gold),
                            onPressed: _submit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                  ],
                ),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Subscribe to comment',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: SFColors.creamMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final profile = comment['profiles'] as Map<String, dynamic>?;
    final isOptimistic = (comment['id'] as String).startsWith('optimistic_');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SFAvatar(
            imageUrl: profile?['avatar_url'] as String?,
            displayName: profile?['display_name'] as String?,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile?['display_name'] as String? ?? 'You',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOptimistic ? 'just now' : _formatTime(comment['created_at'] as String?),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: SFColors.creamMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Opacity(
                  opacity: isOptimistic ? 0.6 : 1.0,
                  child: Text(
                    comment['body'] as String? ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final time = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(time);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'just now';
    } catch (_) {
      return '';
    }
  }
}
