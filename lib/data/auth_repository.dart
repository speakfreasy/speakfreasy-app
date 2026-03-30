import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final SupabaseClient _supabase = supabase;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> onAuthStateChange() {
    return _supabase.auth.onAuthStateChange;
  }
}
