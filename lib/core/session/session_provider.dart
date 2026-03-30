import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../session/session_state.dart';
import '../../data/profile_repository.dart';

/// Provider for current session state
final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(ref),
);

class SessionNotifier extends StateNotifier<SessionState> {
  final Ref _ref;
  SessionNotifier(this._ref) : super(SessionState.initial) {
    _initialize();
    _listenToAuthChanges();
  }

  void _initialize() async {
    await loadSession();
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        loadSession();
      } else if (data.event == AuthChangeEvent.signedOut) {
        state = SessionState.initial;
      }
    });
  }

  Future<void> loadSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user == null) {
      state = SessionState.initial;
      return;
    }

    final profileRepo = _ref.read(profileRepositoryProvider);
    // Always fetch profile first so we never lose role (e.g. if user_access/creators throw)
    Map<String, dynamic>? profile;
    try {
      profile = await profileRepo.getProfile(user.id);
    } catch (_) {}

    // Normalize role: .trim().toLowerCase() to avoid case-sensitivity (profiles.role is String)
    String? role;
    String? displayName;
    if (profile != null) {
      final roleRaw = profile['role'];
      role = roleRaw == null ? null : roleRaw.toString().trim().toLowerCase();
      displayName = profile['display_name'] as String?;
    }

    try {
      final sessionData = await profileRepo.getSessionState(user.id);
      // getSessionState returns: role, hasAnyActiveSub, isCreatorApproved, creatorHallId (user_access/creators use user_id/profile_id)
      final sessionRole = sessionData['role'] as String?;
      final normalizedRole = sessionRole == null ? role : sessionRole.trim().toLowerCase();
      state = SessionState(
        isAuthenticated: true,
        userId: user.id,
        displayName: displayName,
        role: normalizedRole,
        hasAnyActiveSub: sessionData['hasAnyActiveSub'] as bool? ?? false,
        isCreatorApproved: sessionData['isCreatorApproved'] as bool? ?? false,
        creatorHallId: sessionData['creatorHallId'] as String?,
      );
    } catch (e) {
      // Use role from profile so we don't lose it when user_access/creators fail
      state = SessionState(
        isAuthenticated: true,
        userId: user.id,
        displayName: displayName,
        role: role,
        hasAnyActiveSub: false,
        isCreatorApproved: false,
        creatorHallId: null,
      );
    }
  }

  void refresh() {
    loadSession();
  }
}
