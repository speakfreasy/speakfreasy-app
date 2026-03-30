import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

/// Admin-only data. Uses same Supabase client; RLS must allow admin role.
class AdminRepository {
  final SupabaseClient _supabase = supabase;

  /// Simple counts for dashboard (user_access PK: user_id; creators PK: profile_id)
  Future<Map<String, int>> getCounts() async {
    final profilesList = await _supabase.from('profiles').select('id');
    final hallsList = await _supabase.from('halls').select('id');
    final creatorsList = await _supabase.from('creators').select('profile_id');
    // FIX: Column is 'has_any_active_sub', not 'active'
    final accessList = await _supabase.from('user_access').select('user_id').eq('has_any_active_sub', true);

    return {
      'users': (profilesList as List).length,
      'halls': (hallsList as List).length,
      'creators': (creatorsList as List).length,
      'activeSubscriptions': (accessList as List).length,
    };
  }

  /// All halls with owner and subscriber count
  Future<List<Map<String, dynamic>>> getAdminHalls() async {
    // FIX: profiles table doesn't have 'email' column - email is in auth.users
    // We need to select only columns that exist in profiles
    final halls = await _supabase
        .from('halls')
        .select('''
          id,
          name,
          slug,
          created_at,
          creators!inner(
            profile_id,
            approved,
            profiles!inner(
              id,
              display_name,
              avatar_url
            )
          )
        ''')
        .order('created_at', ascending: false);

    final list = List<Map<String, dynamic>>.from(halls);
    for (final hall in list) {
      final creatorsList = hall['creators'];
      Map<String, dynamic>? owner;
      if (creatorsList is List && creatorsList.isNotEmpty) {
        owner = creatorsList.first as Map<String, dynamic>;
      } else if (creatorsList is Map) {
        owner = creatorsList as Map<String, dynamic>;
      }
      hall['owner'] = owner?['profiles'] ?? owner;
      // FIX: Column is 'has_any_active_sub', not 'active'
      // Also, user_access doesn't have hall_id for per-hall filtering
      // For now, count subscriptions table instead
      final subList = await _supabase
          .from('subscriptions')
          .select('user_id')
          .eq('hall_id', hall['id'])
          .eq('status', 'active');
      hall['sub_count'] = (subList as List).length;
    }
    return list;
  }

  /// All users with role and access state
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    // FIX: profiles doesn't have 'email' - remove it from select
    // We can get email via a join with auth.users if needed, but that requires
    // a database function. For MVP, we'll work without email display.
    final res = await _supabase
        .from('profiles')
        .select('id, display_name, role, created_at')
        .order('created_at', ascending: false);

    final list = List<Map<String, dynamic>>.from(res);
    for (final u in list) {
      // FIX: Column is 'has_any_active_sub', not 'active'
      final access = await _supabase
          .from('user_access')
          .select('user_id')
          .eq('user_id', u['id'])
          .eq('has_any_active_sub', true)
          .limit(1)
          .maybeSingle();
      u['has_active_access'] = access != null;
    }
    return list;
  }

  /// Update user role
  Future<void> setUserRole(String userId, String role) async {
    await _supabase.from('profiles').update({'role': role}).eq('id', userId);
  }

  /// All creators with profile and hall, approved status
  Future<List<Map<String, dynamic>>> getAdminCreators() async {
    // FIX: profiles doesn't have 'email' - remove it from select
    final res = await _supabase
        .from('creators')
        .select('''
          profile_id,
          hall_id,
          slug,
          approved,
          created_at,
          profiles!inner(
            id,
            display_name,
            avatar_url
          ),
          halls(
            id,
            name,
            slug
          )
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  /// Approve or deny a creator
  Future<void> setCreatorApproved(String profileId, bool approved) async {
    await _supabase.from('creators').update({'approved': approved}).eq('profile_id', profileId);
  }

  /// Create a hall and assign to creator (minimal: name, slug from profile)
  Future<Map<String, dynamic>> createHallForCreator(String profileId, String name, String slug) async {
    // halls.creator_id is a FK → profiles (stores profileId = auth.uid()).
    // Active RLS policies check creator_id = auth.uid() directly.
    final hallRes = await _supabase
        .from('halls')
        .insert({
          'name': name,
          'slug': slug,
          'creator_id': profileId,
        })
        .select()
        .single();
    final hall = hallRes as Map<String, dynamic>;
    final hallId = hall['id'] as String;

    await _supabase.from('creators').update({'hall_id': hallId}).eq('profile_id', profileId);
    return hall;
  }
}
