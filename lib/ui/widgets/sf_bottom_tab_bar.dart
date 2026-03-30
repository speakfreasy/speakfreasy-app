import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

/// Bottom tab bar for subscriber navigation
class SFBottomTabBar extends StatelessWidget {
  final String currentPath;
  final bool hasAnyActiveSub;

  const SFBottomTabBar({
    super.key,
    required this.currentPath,
    required this.hasAnyActiveSub,
  });

  bool _isActive(String path) {
    if (path == '/home') {
      return currentPath == '/home';
    }
    if (path == '/halls') {
      return currentPath.startsWith('/halls') || currentPath.startsWith('/hall/');
    }
    return currentPath.startsWith(path);
  }

  void _navigate(BuildContext context, String path, bool requiresSub) {
    if (requiresSub && !hasAnyActiveSub) {
      context.go('/paywall?redirect=$path');
    } else {
      context.go(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SFColors.charcoal,
        border: Border(
          top: BorderSide(color: SFColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TabItem(
              icon: Icons.home,
              label: 'Home',
              isActive: _isActive('/home'),
              onTap: () => _navigate(context, '/home', false),
            ),
            _TabItem(
              icon: Icons.storefront,
              label: 'Halls',
              isActive: _isActive('/halls'),
              onTap: () => _navigate(context, '/halls', false),
            ),
_TabItem(
              icon: Icons.settings,
              label: 'Settings',
              isActive: _isActive('/settings'),
              onTap: () => _navigate(context, '/settings', false),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? SFColors.gold : SFColors.creamMuted;
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(icon, color: color, size: 24),
                  if (isLocked)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Icon(
                        Icons.lock,
                        color: SFColors.gold,
                        size: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
