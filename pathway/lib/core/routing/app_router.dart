import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pathway/core/widgets/app_scaffold.dart'; 
import 'package:pathway/features/auth/presentation/login_screen.dart';
import 'package:pathway/features/auth/presentation/signup_screen.dart';
import 'package:pathway/features/auth/presentation/forgot_password_screen.dart';

import 'package:pathway/features/home/presentation/pages/home_page.dart';
import 'package:pathway/features/auth/presentation/map_screen.dart';
import 'package:pathway/features/venues/presentation/pages/venue_detail_page.dart';
import 'package:pathway/features/messaging/presentation/pages/conversations_page.dart';
import 'package:pathway/features/profile/presentation/pages/profile_page.dart';
import 'package:pathway/features/profile/presentation/pages/edit_profile_information_page.dart';
import 'package:pathway/features/profile/presentation/pages/accessibility_settings_page.dart'; 
import 'package:pathway/features/profile/presentation/pages/blocked_muted_users_page.dart'; 
import 'package:pathway/features/profile/presentation/pages/contact_us_page.dart'; 
import 'package:pathway/features/profile/presentation/pages/favorites_page.dart'; 
import 'package:pathway/features/profile/presentation/pages/follow_list_page.dart'; 
import 'package:pathway/features/profile/presentation/pages/help_page.dart'; 
import 'package:pathway/features/profile/presentation/pages/notification_settings_page.dart'; 
import 'package:pathway/features/profile/presentation/pages/other_user_profile.dart'; 
import 'package:pathway/features/profile/presentation/pages/privacy_policy_page.dart'; 
import 'package:pathway/features/profile/presentation/pages/security_settings_page.dart'; 
import 'package:pathway/features/admin/presentation/mod_dashboard.dart'; 

import 'package:pathway/features/gamification/presentation/pages/badges_page.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey = 
    GlobalKey<NavigatorState>();

  static final GlobalKey<NavigatorState> homeNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'homeNav');

  static final GlobalKey<NavigatorState> mapNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'mapNav');

  static final GlobalKey<NavigatorState> badgesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'badgesNav');

  static final GlobalKey<NavigatorState> messagesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'messagesNav');

  static final GlobalKey<NavigatorState> profileNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'profileNav');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;
      final location = state.matchedLocation;

      const authRoutes = {
        '/login',
        '/signup',
        '/forgot-password',
      };

      final sharedReviewRegex = RegExp(r'^/map/venue/[^/]+/reviews/[^/]+$');
      final isSharedReview = sharedReviewRegex.hasMatch(location);
      final isAuthRoute = authRoutes.contains(location);
      
      if (!loggedIn && !isAuthRoute && !isSharedReview) {
        return '/login';
      }

      if (loggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // LoginScreen.dart
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return PathwayNavShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder:(context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: mapNavigatorKey,
            routes: [
              GoRoute(
                path: '/map',
                name: 'map',
                builder: (context, state) => const MapScreen(),
                routes: [
                  GoRoute(
                    path: 'venue/:venueId',
                    name: 'venue-detail',
                    builder: (context, state) {
                      final venueIdString = state.pathParameters['venueId']!;
                      final venueId = int.parse(venueIdString);
                      return VenueDetailPage(venueId: venueId);
                    },
                    routes: [
                      GoRoute(
                        path: 'reviews/:reviewId',
                        name: 'shared-review',
                        builder: (context, state) {
                          final venueId = int.parse(state.pathParameters['venueId']!);
                          final reviewId = state.pathParameters['reviewId']!;

                          return VenueDetailPage(
                            venueId: venueId,
                            initialTabIndex: 1,
                            highlightReviewId: reviewId,
                          );
                        }
                      )
                    ]
                  )
                ]
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: badgesNavigatorKey,
            routes: [
              GoRoute(
                path: '/badges',
                name: 'badges',
                builder: (context, state) => const BadgesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: messagesNavigatorKey,
            routes: [
              GoRoute(
                path: '/messages',
                name: 'messages',
                builder: (context, state) => const ConversationsPage(),
                routes: [
                  // TODO: Add conversation detail route here when implemented
                ]
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'edit-profile',
                    builder: (context, state) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: '/notification',
                    name: 'notification-settings',
                    builder: (context, state) => const NotificationSettingsPage(),
                  ),
                  GoRoute(
                    path: '/accessibility',
                    name: 'accessibility-settings',
                    builder: (context, state) => const AccessibilitySettingsPage(),
                  ),
                  GoRoute(
                    path: '/favorites',
                    name: 'favorites',
                    builder: (context, state) => const FavoritesPage(),
                  ),
                  GoRoute(
                    path: '/security',
                    name: 'security-settings',
                    builder: (context, state) => const SecuritySettingsPage(),
                  ),
                  GoRoute(
                    path: '/blocked-muted',
                    name: 'blocked-muted-users',
                    builder: (context, state) => const BlockedMutedPage(),
                  ),
                  GoRoute(
                    path: '/moderator',
                    name: 'moderator-dashboard',
                    builder: (context, state) => const ModeratorDashboard(),
                  ),
                  GoRoute(
                    path: '/help',
                    name: 'help-page',
                    builder: (context, state) => const HelpPage(),
                  ),
                  GoRoute(
                    path: '/contact-us',
                    name: 'contact-us',
                    builder: (context, state) => const ContactUsPage(),
                  ),
                  GoRoute(
                    path: '/privacy-policy',
                    name: 'privacy-policy',
                    builder: (context, state) => const PrivacyPolicyPage(),
                  ),
                ]
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('No route found for ${state.uri}'),
      ),
    ),
  );
}