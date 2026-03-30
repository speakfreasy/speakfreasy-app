import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../ui/widgets/sf_card.dart';
import '../../ui/widgets/sf_avatar.dart';
import '../../ui/widgets/sf_bottom_tab_bar.dart';
import '../../ui/widgets/sf_button.dart';
import '../../ui/widgets/role_gate.dart';
import '../../data/hall_repository.dart';
import '../../core/session/session_provider.dart';

class HallsScreen extends ConsumerWidget {
  const HallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hallsAsync = ref.watch(allHallsProvider);
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: Text(
          'Halls',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: SFColors.gold,
          ),
        ),
        backgroundColor: SFColors.charcoal,
        actions: [
          RoleGate(
            allowedRoles: ['admin'],
            child: IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: SFColors.gold),
              tooltip: 'Manage halls',
              onPressed: () => context.push('/admin/halls'),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://rtbjubzgvsedfnumjksu.supabase.co/storage/v1/object/public/SPEAKFREASY/splash.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: SFColors.black),
          ),
          hallsAsync.when(
        data: (halls) {
          if (halls.isEmpty) {
            return Center(
              child: Text(
                'No halls available',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: halls.length,
            itemBuilder: (context, index) {
              final hall = halls[index];
              final creators = hall['creators'] as List<dynamic>?;
              final creator = creators?.isNotEmpty == true ? creators![0] : null;
              final profile = creator?['profiles'] as Map<String, dynamic>?;
              
              final slug = hall['slug'] as String?;
              if (slug == null || slug.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SFCard(
                  onTap: () => context.push('/hall/$slug'),
                  backgroundColor: SFColors.charcoal.withOpacity(0.6),
                  child: Row(
                    children: [
                      SFAvatar(
                        imageUrl: hall['avatar_url'] as String? ?? profile?['avatar_url'] as String?,
                        displayName: hall['name'] as String?,
                        size: 120,
                        showCreatorRing: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    hall['name'] as String? ?? 'Unknown Hall',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  profile?['display_name'] as String? ?? 'Unknown Creator',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SFColors.creamMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@$slug • ${hall['subscriber_count'] ?? 0} subscribers',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: SFColors.creamMuted,
                              ),
                            ),
                            if (hall['description'] != null && (hall['description'] as String).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                hall['description'] as String,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: SFColors.gold,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: SFColors.error),
          ),
        ),
          ),
        ],
      ),
    );
  }
}

final allHallsProvider = FutureProvider((ref) async {
  final hallRepo = ref.read(hallRepositoryProvider);
  return await hallRepo.getAllHalls();
});
