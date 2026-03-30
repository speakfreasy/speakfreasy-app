import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});

class PostRepository {
  final SupabaseClient _supabase = supabase;

  /// Get posts for a specific hall, including attached media.
  Future<List<Map<String, dynamic>>> getHallPosts(String hallId) async {
    final response = await _supabase
        .from('posts')
        .select('''
          *,
          profiles!inner(
            display_name,
            avatar_url
          ),
          halls!inner(
            name,
            slug
          ),
          post_media(
            id,
            url,
            type,
            position
          )
        ''')
        .eq('hall_id', hallId)
        .order('pinned', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get Freasy Feed posts (from all subscribed halls)
  /// FIX: user_access doesn't have 'hall_id' or 'active' columns
  /// user_access only has: user_id, has_any_active_sub, updated_at
  /// We need to use subscriptions table to get per-hall access
  Future<List<Map<String, dynamic>>> getFreasyFeedPosts(String userId) async {
    // Get user's subscribed halls from subscriptions table
    final subscriptions = await _supabase
        .from('subscriptions')
        .select('hall_id')
        .eq('user_id', userId)
        .eq('status', 'active');
    
    if (subscriptions.isEmpty) {
      return [];
    }
    
    final hallIds = (subscriptions as List).map((sub) => sub['hall_id'] as String).toList();
    
    final response = await _supabase
        .from('posts')
        .select('''
          *,
          profiles!inner(
            display_name,
            avatar_url
          ),
          halls!inner(
            name,
            slug
          )
        ''')
        .inFilter('hall_id', hallIds)
        .eq('scope', 'freasy')
        .order('created_at', ascending: false)
        .limit(50);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new post. Images are stored separately via [createPostMedia].
  Future<Map<String, dynamic>> createPost({
    required String hallId,
    required String scope, // 'hall' or 'freasy'
    required String body,
    bool pinned = false,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('posts')
        .insert({
          'hall_id': hallId,
          'author_id': user.id,
          'scope': scope,
          'body': body,
          'pinned': pinned,
        })
        .select('''
          *,
          profiles!inner(
            display_name,
            avatar_url
          ),
          halls!inner(
            name,
            slug
          )
        ''')
        .single();

    return response;
  }

  /// Attach an image CDN URL to an existing post via the post_media table.
  Future<void> createPostMedia({
    required String postId,
    required String url,
    String type = 'image',
  }) async {
    await _supabase.from('post_media').insert({
      'post_id': postId,
      'url': url,
      'type': type,
      'position': 0,
    });
  }

  /// Toggle like on a post — calls a SECURITY DEFINER RPC so RLS on `posts`
  /// doesn't block the like_count update. Returns true if now liked, false if unliked.
  Future<bool> togglePostLike(String postId) async {
    final result = await _supabase
        .rpc('toggle_post_like', params: {'p_post_id': postId});
    return result as bool;
  }

  /// Check if current user liked a post
  Future<bool> hasUserLikedPost(String postId, String userId) async {
    final response = await _supabase
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  /// Fetch all post IDs the user has liked within a specific hall (single query)
  Future<Set<String>> getLikedPostIdsInHall(String userId, String hallId) async {
    final response = await _supabase
        .from('post_likes')
        .select('post_id, posts!inner(hall_id)')
        .eq('user_id', userId)
        .eq('posts.hall_id', hallId);

    return Set<String>.from(
      (response as List).map((row) => row['post_id'] as String),
    );
  }

  /// Update a post's body and/or pinned state (author only per RLS)
  Future<void> updatePost({
    required String postId,
    required String body,
    bool? pinned,
  }) async {
    await _supabase
        .from('posts')
        .update({
          'body': body,
          if (pinned != null) 'pinned': pinned,
        })
        .eq('id', postId);
  }

  /// Delete a post (author, hall creator, or admin per RLS)
  Future<void> deletePost(String postId) async {
    await _supabase
        .from('posts')
        .delete()
        .eq('id', postId);
  }
}
