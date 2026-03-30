import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';

/// Shows [child] only when the current session role is in [allowedRoles].
/// Admin override: if session.role == 'admin', always shows [child] (master key).
/// All role comparisons use lowercase. Use ref.watch(sessionProvider) so UI reacts to role changes.
class RoleGate extends ConsumerWidget {
  /// Allowed roles: 'subscriber', 'creator', 'admin' (compared lowercase)
  final List<String> allowedRoles;
  final Widget child;
  /// Optional widget to show when role is not allowed (default: nothing)
  final Widget? fallback;

  const RoleGate({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final roleRaw = session.role;
    final role = roleRaw?.trim().toLowerCase();

    // Admin override: return child immediately, bypassing allowedRoles
    if (role == 'admin') return child;

    // Otherwise check if role is in allowed list (lowercase comparison)
    final allowed = role != null &&
        allowedRoles.any((r) => r.trim().toLowerCase() == role);

    if (allowed) return child;
    if (fallback != null) return fallback!;
    return const SizedBox.shrink();
  }
}
