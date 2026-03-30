import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../data/admin_repository.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_button.dart';

final adminCreatorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getAdminCreators();
});

class AdminCreatorsScreen extends ConsumerWidget {
  const AdminCreatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorsAsync = ref.watch(adminCreatorsProvider);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Admin · Creators',
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
          TextButton(onPressed: () => context.go('/admin/users'), child: const Text('Users', style: TextStyle(color: SFColors.gold))),
        ],
      ),
      body: creatorsAsync.when(
        data: (creators) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: creators.length,
          itemBuilder: (context, index) {
            final c = creators[index];
            final profileId = c['profile_id'] as String? ?? '';
            final profile = c['profiles'] as Map<String, dynamic>?;
            final email = profile?['email'] as String? ?? '—';
            final displayName = profile?['display_name'] as String? ?? '—';
            final approved = c['approved'] as bool? ?? false;
            final hall = c['halls'] as Map<String, dynamic>?;
            final hallName = hall?['name'] as String? ?? 'No hall';
            final hallSlug = hall?['slug'] as String?;
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
                              Text('Approved: $approved · Hall: $hallName', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        _CreatorActions(
                          profileId: profileId,
                          approved: approved,
                          hasHall: hall != null,
                          onUpdated: () => ref.invalidate(adminCreatorsProvider),
                        ),
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

class _CreatorActions extends ConsumerStatefulWidget {
  final String profileId;
  final bool approved;
  final bool hasHall;
  final VoidCallback onUpdated;

  const _CreatorActions({
    required this.profileId,
    required this.approved,
    required this.hasHall,
    required this.onUpdated,
  });

  @override
  ConsumerState<_CreatorActions> createState() => _CreatorActionsState();
}

class _CreatorActionsState extends ConsumerState<_CreatorActions> {
  bool _loading = false;
  bool _showCreateHall = false;
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _setApproved(bool approved) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.setCreatorApproved(widget.profileId, approved);
      widget.onUpdated();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createHall() async {
    final name = _nameController.text.trim();
    final slug = _slugController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
    if (name.isEmpty || slug.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.createHallForCreator(widget.profileId, name, slug);
      _nameController.clear();
      _slugController.clear();
      setState(() => _showCreateHall = false);
      widget.onUpdated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCreateHall) {
      return SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Hall name', isDense: true),
              style: const TextStyle(color: SFColors.cream),
            ),
            TextField(
              controller: _slugController,
              decoration: const InputDecoration(labelText: 'Slug', isDense: true),
              style: const TextStyle(color: SFColors.cream),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SFButton(label: 'Create', onPressed: _loading ? null : _createHall, isLoading: _loading),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _showCreateHall = false),
                  child: const Text('Cancel', style: TextStyle(color: SFColors.gold)),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.approved)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SFButton(
              label: 'Approve',
              onPressed: _loading ? null : () => _setApproved(true),
              isLoading: _loading,
            ),
          ),
        if (widget.approved)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SFButton(
              label: 'Deny',
              variant: SFButtonVariant.secondary,
              onPressed: _loading ? null : () => _setApproved(false),
              isLoading: _loading,
            ),
          ),
        if (!widget.hasHall)
          SFButton(
            label: 'Create hall',
            onPressed: _loading ? null : () => setState(() => _showCreateHall = true),
            isLoading: _loading,
          ),
      ],
    );
  }
}
