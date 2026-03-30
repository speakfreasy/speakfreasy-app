import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/signup_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/halls_screen.dart';
import '../ui/screens/hall_interior_screen.dart';
import '../ui/screens/hall_posts_tab.dart';
import '../ui/screens/hall_videos_tab.dart';
import '../ui/screens/hall_chat_tab.dart';
import '../ui/screens/feed_screen.dart';
import '../ui/screens/discover_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/paywall_screen.dart';
import '../ui/screens/creator/creator_dashboard_screen.dart';
import '../ui/screens/creator/creator_new_post_screen.dart';
import '../ui/screens/creator/creator_notifications_screen.dart';
import '../ui/screens/creator/creator_video_upload_screen.dart';
import '../ui/screens/video_player_screen.dart';
import '../ui/screens/creator/hall_settings_screen.dart';
import '../ui/screens/admin/admin_dashboard_screen.dart';
import '../ui/screens/admin/admin_halls_screen.dart';
import '../ui/screens/admin/admin_users_screen.dart';
import '../ui/screens/admin/admin_creators_screen.dart';
import '../ui/widgets/app_shell.dart';
import '../core/session/session_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final sessionState = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = sessionState.isAuthenticated;
      final location = state.matchedLocation;

      // Public routes
      if (location == '/splash' || location == '/login' || location == '/signup') {
        if (isAuthenticated && location == '/login') {
          return '/home';
        }
        return null;
      }

      // Protected routes - require authentication
      if (!isAuthenticated) {
        return '/login';
      }

      // Role-based redirects (all role comparisons lowercase)
      final role = sessionState.role?.trim().toLowerCase();
      if (location.startsWith('/creator')) {
        if (role != 'creator' || !sessionState.isCreatorApproved) {
          return '/home';
        }
      }
      if (location.startsWith('/admin')) {
        if (role != 'admin') {
          return '/home';
        }
      }

      // Feed and Discover require active subscription
      if (location == '/feed' || location == '/discover') {
        if (!sessionState.hasAnyActiveSub) {
          return '/paywall?redirect=$location';
        }
      }

      return null;
    },
    routes: [
      // Public routes without bottom nav
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return PaywallScreen(redirect: redirect);
        },
      ),

      // Main navigation with persistent bottom nav bar
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/halls',
            builder: (context, state) => const HallsScreen(),
          ),
          GoRoute(
            path: '/feed',
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          // Hall interior screens
          GoRoute(
            path: '/hall/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              return HallInteriorScreen(slug: slug);
            },
            routes: [
              GoRoute(
                path: 'posts',
                builder: (context, state) {
                  final slug = state.pathParameters['slug']!;
                  return HallPostsTab(slug: slug);
                },
              ),
              GoRoute(
                path: 'videos',
                builder: (context, state) {
                  final slug = state.pathParameters['slug']!;
                  return HallVideosTab(slug: slug);
                },
              ),
              GoRoute(
                path: 'chat',
                builder: (context, state) {
                  final slug = state.pathParameters['slug']!;
                  return HallChatTab(slug: slug);
                },
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) {
                  final slug = state.pathParameters['slug']!;
                  final hallId = state.uri.queryParameters['hallId'] ?? '';
                  return HallSettingsScreen(
                    hallId: hallId,
                    slug: slug,
                  );
                },
              ),
            ],
          ),
          // Creator routes
          GoRoute(
            path: '/creator',
            builder: (context, state) => const CreatorDashboardScreen(),
          ),
          GoRoute(
            path: '/creator/post/new',
            builder: (context, state) => const CreatorNewPostScreen(),
          ),
          GoRoute(
            path: '/creator/video/upload',
            builder: (context, state) => const CreatorVideoUploadScreen(),
          ),
          GoRoute(
            path: '/creator/notifications',
            builder: (context, state) => const CreatorNotificationsScreen(),
          ),
          // Admin routes (admin role only)
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/halls',
            builder: (context, state) => const AdminHallsScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/creators',
            builder: (context, state) => const AdminCreatorsScreen(),
          ),
        ],
      ),
      // Video player (fullscreen, no bottom nav)
      GoRoute(
        path: '/video/:libraryId/:videoId',
        builder: (context, state) {
          final libraryId = state.pathParameters['libraryId']!;
          final videoId = state.pathParameters['videoId']!;
          final title = state.uri.queryParameters['title'] ?? '';
          return VideoPlayerScreen(
            libraryId: libraryId,
            videoId: videoId,
            title: title,
          );
        },
      ),
    ],
  );
});
