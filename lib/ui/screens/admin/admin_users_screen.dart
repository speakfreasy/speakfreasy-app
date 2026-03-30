import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../data/admin_repository.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_button.dart';

/// Lists users from profiles with role and access state (user_access filtered by user_id).
final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getAdminUsers();
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Admin · Users',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: SFColors.gold),
        ),
        backgroundColor: SFColors.charcoal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          TextButton(onPressed: () => context.go('/admin'), child: const Text('Dashboard', style: TextStyle(color: SFColors.gold))),
          TextButton(onPressed: () => context.go('/admin/halls'), child: const Text('Halls', style: TextStyle(color: SFColors.gold))),
          TextButton(onPressed: () => context.go('/admin/creators'), child: const Text('Creators', style: TextStyle(color: SFColors.gold))),
        ],
      ),
      body: usersAsync.when(
        data: (users) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final u = users[index];
            final id = u['id'] as String? ?? '';
            final email = u['email'] as String? ?? '—';
            final displayName = u['display_name'] as String? ?? '—';
            final role = u['role'] as String? ?? '—';
            final hasAccess = u['has_active_access'] as bool? ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: Theme.of(context).textTheme.titleMedium),
                              Text(email, style: Theme.of(context).textTheme.bodySmall),
                              Text('Role: $role · Access: ${hasAccess ? "Yes" : "No"}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        _RoleDropdown(userId: id, currentRole: role, onChanged: () => ref.invalidate(adminUsersProvider)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: SFColors.error))),
      ),
    );
  }
}

class _RoleDropdown extends ConsumerStatefulWidget {
  final String userId;
  final String currentRole;
  final VoidCallback onChanged;

  const _RoleDropdown({required this.userId, required this.currentRole, required this.onChanged});

  @override
  ConsumerState<_RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends ConsumerState<_RoleDropdown> {
  String? _selectedRole;
  bool _loading = false;

  String get _effectiveRole => _selectedRole ?? widget.currentRole;

  Future<void> _updateRole(String role) async {
    setState(() { _loading = true; _selectedRole = role; });
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.setUserRole(widget.userId, role);
      widget.onChanged();
    } finally {
      if (mounted) setState(() { _loading = false; _selectedRole = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: _effectiveRole,
      onSelected: _updateRole,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            if (!_loading) Text(_effectiveRole, style: const TextStyle(color: SFColors.gold)),
            const Icon(Icons.arrow_drop_down, color: SFColors.gold),
          ],
        ),
      ),
      itemBuilder: (context) => ['subscriber', 'creator', 'admin']
          .map((r) => PopupMenuItem(value: r, child: Text(r)))
          .toList(),
    );
  }
}
