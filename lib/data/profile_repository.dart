import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileRepository {
  final SupabaseClient _supabase = supabase;

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('id, role, display_name')
        .eq('id', userId)
        .maybeSingle();
    
    return response;
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _supabase
        .from('profiles')
        .update(data)
        .eq('id', userId);
  }

  /// Get comprehensive session state combining profile, user_access, and creator data
  Future<Map<String, dynamic>> getSessionState(String userId) async {
    // Get profile
    final profile = await getProfile(userId);
    if (profile == null) {
      return {'role': null, 'hasAnyActiveSub': false, 'isCreatorApproved': false};
    }

    // Role column (String): normalize to lowercase to avoid case-sensitivity bugs
    final roleRaw = profile['role'];
    final String? role = roleRaw == null ? null : roleRaw.toString().trim().toLowerCase();

    // Check for active subscriptions
    // FIX: Column is 'has_any_active_sub', not 'active'
    final userAccessResponse = await _supabase
        .from('user_access')
        .select('user_id, has_any_active_sub')
        .eq('user_id', userId)
        .eq('has_any_active_sub', true)
        .limit(1)
        .maybeSingle();
    
    final hasAnyActiveSub = userAccessResponse != null;

    // Check creator status
    final creatorResponse = await _supabase
        .from('creators')
        .select('approved, hall_id')
        .eq('profile_id', userId)
        .maybeSingle();
    
    final isCreatorApproved = creatorResponse?['approved'] as bool? ?? false;
    final creatorHallId = creatorResponse?['hall_id'] as String?;

    return {
      'role': role,
      'hasAnyActiveSub': hasAnyActiveSub,
      'isCreatorApproved': isCreatorApproved,
      'creatorHallId': creatorHallId,
    };
  }
}
