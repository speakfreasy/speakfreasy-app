import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

final hallRepositoryProvider = Provider<HallRepository>((ref) {
  return HallRepository();
});

class HallRepository {
  final SupabaseClient _supabase = supabase;

  /// Get all halls (public preview)
  Future<List<Map<String, dynamic>>> getAllHalls() async {
    final response = await _supabase
        .from('halls')
        .select('''
          id,
          name,
          slug,
          description,
          bio,
          avatar_url,
          banner_url,
          price_cents,
          approved,
          created_at,
          creators!inner(
            profile_id,
            approved,
            profiles!inner(
              display_name,
              avatar_url
            )
          )
        ''')
        .eq('creators.approved', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get hall by ID
  Future<Map<String, dynamic>?> getHallById(String hallId) async {
    final response = await _supabase
        .from('halls')
        .select('''
          id,
          name,
          slug,
          description,
          bio,
          avatar_url,
          banner_url,
          price_cents,
          approved,
          created_at
        ''')
        .eq('id', hallId)
        .maybeSingle();

    return response;
  }

  /// Get hall by slug
  Future<Map<String, dynamic>?> getHallBySlug(String slug) async {
    final response = await _supabase
        .from('halls')
        .select('''
          id,
          name,
          slug,
          description,
          bio,
          avatar_url,
          banner_url,
          price_cents,
          approved,
          created_at,
          creators!inner(
            profile_id,
            approved,
            profiles!inner(
              id,
              display_name,
              avatar_url,
              bio
            )
          )
        ''')
        .eq('slug', slug)
        .eq('creators.approved', true)
        .maybeSingle();

    return response;
  }

  /// Get halls by creator ID
  Future<List<Map<String, dynamic>>> getHallsByCreator(String creatorId) async {
    final response = await _supabase
        .from('halls')
        .select('''
          *,
          creators!inner(
            profile_id,
            approved
          )
        ''')
        .eq('creators.profile_id', creatorId)
        .eq('creators.approved', true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get halls the user is subscribed to
  /// FIX: user_access doesn't have 'active' column - it has 'has_any_active_sub'
  /// Also, user_access doesn't have per-hall access - it's a global flag
  /// We need to use subscriptions table instead for per-hall subscriptions
  Future<List<Map<String, dynamic>>> getUserSubscribedHalls(String userId) async {
    // Query subscriptions table which has hall_id
    final response = await _supabase
        .from('subscriptions')
        .select('''
          hall_id,
          status,
          halls!inner(
            *,
            creators!inner(
              profile_id,
              profiles!inner(
                display_name,
                avatar_url
              )
            )
          )
        ''')
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map((sub) => sub['halls'] as Map<String, dynamic>)
        .toList();
  }

  /// Update hall details (name, bio, description)
  Future<void> updateHallDetails({
    required String hallId,
    String? name,
    String? bio,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (description != null) updates['description'] = description;
    updates['updated_at'] = DateTime.now().toIso8601String();

    final res = await _supabase.from('halls').update(updates).eq('id', hallId).select('id');
    if (res.isEmpty) {
      throw Exception('Hall update failed: no rows updated (check RLS / permissions)');
    }
  }

  /// Update hall avatar URL
  Future<void> updateHallAvatar(String hallId, String avatarUrl) async {
    final res = await _supabase.from('halls').update({
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', hallId).select('id');
    if (res.isEmpty) {
      throw Exception('Avatar update failed: no rows updated (check RLS / permissions)');
    }
  }

  /// Update hall banner URL
  Future<void> updateHallBanner(String hallId, String bannerUrl) async {
    final res = await _supabase.from('halls').update({
      'banner_url': bannerUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', hallId).select('id');
    if (res.isEmpty) {
      throw Exception('Banner update failed: no rows updated (check RLS / permissions)');
    }
  }

  /// Update hall pricing
  Future<void> updateHallPricing(String hallId, int priceCents) async {
    final res = await _supabase.from('halls').update({
      'price_cents': priceCents,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', hallId).select('id');
    if (res.isEmpty) {
      throw Exception('Pricing update failed: no rows updated (check RLS / permissions)');
    }
  }

  /// Check if user is the creator of a hall
  Future<bool> isUserHallCreator(String userId, String hallId) async {
    final response = await _supabase
        .from('creators')
        .select('id')
        .eq('profile_id', userId)
        .eq('hall_id', hallId)
        .maybeSingle();

    return response != null;
  }
}
