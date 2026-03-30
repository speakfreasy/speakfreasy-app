/// Session state model
class SessionState {
  final bool isAuthenticated;
  final String? userId;
  final String? displayName;
  final String? role; // 'subscriber', 'creator', 'admin'
  final bool hasAnyActiveSub;
  final bool isCreatorApproved;
  final String? creatorHallId;

  const SessionState({
    required this.isAuthenticated,
    this.userId,
    this.displayName,
    this.role,
    this.hasAnyActiveSub = false,
    this.isCreatorApproved = false,
    this.creatorHallId,
  });

  SessionState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? displayName,
    String? role,
    bool? hasAnyActiveSub,
    bool? isCreatorApproved,
    String? creatorHallId,
  }) {
    return SessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      hasAnyActiveSub: hasAnyActiveSub ?? this.hasAnyActiveSub,
      isCreatorApproved: isCreatorApproved ?? this.isCreatorApproved,
      creatorHallId: creatorHallId ?? this.creatorHallId,
    );
  }

  static const SessionState initial = SessionState(
    isAuthenticated: false,
  );
}
