import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});

class SubscriptionRepository {
  final SupabaseClient _supabase = supabase;

  /// Get all user subscriptions
  /// FIX: user_access doesn't have hall relationship - use subscriptions table
  Future<List<Map<String, dynamic>>> getUserSubscriptions(String userId) async {
    final response = await _supabase
        .from('subscriptions')
        .select('''
          *,
          halls!inner(*)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Check if user is subscribed to a specific hall
  /// FIX: Use subscriptions table which has hall_id and status columns
  Future<bool> isSubscribedToHall(String userId, String hallId) async {
    final response = await _supabase
        .from('subscriptions')
        .select('id')
        .eq('user_id', userId)
        .eq('hall_id', hallId)
        .eq('status', 'active')
        .maybeSingle();
    
    return response != null;
  }

  /// Check if user has any active subscription (uses user_access for global flag)
  Future<bool> hasAnyActiveSubscription(String userId) async {
    // FIX: Column is 'has_any_active_sub', not 'active'
    final response = await _supabase
        .from('user_access')
        .select('user_id')
        .eq('user_id', userId)
        .eq('has_any_active_sub', true)
        .maybeSingle();
    
    return response != null;
  }

  // TODO: createSubscription will be implemented with Stripe integration
  // Future<void> createSubscription(String userId, String hallId) async {
  //   // Stripe checkout flow
  // }
}
