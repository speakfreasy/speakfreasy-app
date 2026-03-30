import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository();
});

class VideoRepository {
  final SupabaseClient _supabase = supabase;

  // Video status lifecycle: uploading → processing → published | failed
  // RLS videos_select policy gates on status = 'published'.
  // Creators/admins bypass this via videos_select_creator_admin policy.

  /// Get published videos for a specific hall (subscriber view).
  /// Note: videos have no author FK — creator is inferred via hall ownership.
  Future<List<Map<String, dynamic>>> getHallVideos(String hallId) async {
    final response = await _supabase
        .from('videos')
        .select('''
          *,
          halls!inner(
            name,
            slug
          )
        ''')
        .eq('hall_id', hallId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get video by ID
  Future<Map<String, dynamic>?> getVideoById(String videoId) async {
    final response = await _supabase
        .from('videos')
        .select('''
          *,
          halls!inner(
            name,
            slug
          )
        ''')
        .eq('id', videoId)
        .maybeSingle();

    return response;
  }

  /// Insert a video record with status='uploading', then update to 'published'
  /// once the Bunny.net upload and processing is confirmed complete.
  /// Call updateVideoStatus(id, 'published') from the Bunny webhook handler.
  Future<Map<String, dynamic>> createVideoRecord({
    required String hallId,
    required String title,
    String? description,
    String? bunnyVideoId,
    String? bunnyLibraryId,
  }) async {
    final response = await _supabase
        .from('videos')
        .insert({
          'hall_id': hallId,
          'title': title,
          'description': description,
          'bunny_video_id': bunnyVideoId,
          'bunny_library_id': bunnyLibraryId,
          'status': 'uploading',
        })
        .select()
        .single();

    return response;
  }

  /// Update video status. Valid values: uploading, processing, published, failed.
  Future<void> updateVideoStatus(String videoId, String status) async {
    final now = DateTime.now().toIso8601String();
    await _supabase
        .from('videos')
        .update({
          'status': status,
          'updated_at': now,
          if (status == 'published') 'published_at': now,
        })
        .eq('id', videoId);
  }
}
