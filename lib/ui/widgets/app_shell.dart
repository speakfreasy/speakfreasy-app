import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_provider.dart';
import 'sf_bottom_tab_bar.dart';

/// Shell widget that wraps main navigation screens with persistent bottom tab bar
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: SFBottomTabBar(
        currentPath: location,
        hasAnyActiveSub: session.hasAnyActiveSub,
      ),
    );
  }
}
