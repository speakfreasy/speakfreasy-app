import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../ui/widgets/sf_card.dart';
import '../../ui/widgets/sf_button.dart';
import '../../ui/widgets/sf_bottom_tab_bar.dart';
import '../../core/session/session_provider.dart';

class PaywallScreen extends ConsumerWidget {
  final String? redirect;

  const PaywallScreen({super.key, this.redirect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        backgroundColor: SFColors.charcoal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: SFColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock,
                  size: 64,
                  color: SFColors.black,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Subscribe to Unlock',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: SFColors.gold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Join a hall to access exclusive content, interact with creators, and be part of the community.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SFCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BENEFITS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: SFColors.gold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BenefitItem(
                    icon: Icons.video_library,
                    title: 'Exclusive Videos',
                    description: 'Access creator-only video content',
                  ),
                  const SizedBox(height: 16),
                  _BenefitItem(
                    icon: Icons.chat_bubble,
                    title: 'Direct Chat',
                    description: 'Message creators and community members',
                  ),
                  const SizedBox(height: 16),
                  _BenefitItem(
                    icon: Icons.dynamic_feed,
                    title: 'Freasy Feed',
                    description: 'See posts from all your subscribed halls',
                  ),
                  const SizedBox(height: 16),
                  _BenefitItem(
                    icon: Icons.explore,
                    title: 'Discover',
                    description: 'Find new creators and content',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SFButton(
              label: 'Browse Halls',
              onPressed: () {
                if (redirect != null) {
                  context.go('/halls?redirect=$redirect');
                } else {
                  context.go('/halls');
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Maybe Later',
                style: TextStyle(color: SFColors.creamMuted),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SFBottomTabBar(
        currentPath: '/paywall',
        hasAnyActiveSub: session.hasAnyActiveSub,
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SFColors.gold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: SFColors.gold, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
