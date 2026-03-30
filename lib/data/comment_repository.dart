import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository();
});

class CommentRepository {
  final SupabaseClient _supabase = supabase;

  /// Get comments for a post
  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    final response = await _supabase
        .from('comments')
        .select('''
          *,
          profiles!inner(
            display_name,
            avatar_url
          )
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get comments for a video
  Future<List<Map<String, dynamic>>> getVideoComments(String videoId) async {
    final response = await _supabase
        .from('comments')
        .select('''
          *,
          profiles!inner(
            display_name,
            avatar_url
          )
        ''')
        .eq('video_id', videoId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a comment on a post or video.
  /// [parentType] must be 'post' or 'video'.
  Future<Map<String, dynamic>> createComment({
    required String parentType, // 'post' or 'video'
    required String parentId,
    required String body,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final payload = <String, dynamic>{
      'author_id': user.id,
      'body': body,
    };
    if (parentType == 'post') {
      payload['post_id'] = parentId;
    } else if (parentType == 'video') {
      payload['video_id'] = parentId;
    } else {
      throw ArgumentError('parentType must be "post" or "video"');
    }

    final response = await _supabase
        .from('comments')
        .insert(payload)
        .select('''
          *,
          profiles!inner(
            display_name,
            avatar_url
          )
        ''')
        .single();

    return response;
  }

  /// Get recent comments for creator inbox (across all posts and videos in their hall)
  Future<List<Map<String, dynamic>>> getRecentCommentsForCreator({
    required String creatorHallId,
    int limit = 20,
  }) async {
    final posts = await _supabase
        .from('posts')
        .select('id')
        .eq('hall_id', creatorHallId);

    final videos = await _supabase
        .from('videos')
        .select('id')
        .eq('hall_id', creatorHallId);

    final postIds = posts.map((p) => p['id'] as String).toList();
    final videoIds = videos.map((v) => v['id'] as String).toList();

    if (postIds.isEmpty && videoIds.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> allComments = [];

    if (postIds.isNotEmpty) {
      final postComments = await _supabase
          .from('comments')
          .select('''
            *,
            profiles!inner(
              display_name,
              avatar_url
            )
          ''')
          .inFilter('post_id', postIds)
          .order('created_at', ascending: false)
          .limit(limit);

      allComments.addAll(List<Map<String, dynamic>>.from(postComments));
    }

    if (videoIds.isNotEmpty) {
      final videoComments = await _supabase
          .from('comments')
          .select('''
            *,
            profiles!inner(
              display_name,
              avatar_url
            )
          ''')
          .inFilter('video_id', videoIds)
          .order('created_at', ascending: false)
          .limit(limit);

      allComments.addAll(List<Map<String, dynamic>>.from(videoComments));
    }

    allComments.sort((a, b) {
      final aTime = DateTime.parse(a['created_at'] as String);
      final bTime = DateTime.parse(b['created_at'] as String);
      return bTime.compareTo(aTime);
    });

    return allComments.take(limit).toList();
  }
}
