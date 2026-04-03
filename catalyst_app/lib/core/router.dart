import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/features/home/presentation/home_shell.dart';
import 'package:catalyst_app/features/auth/presentation/login_screen.dart';
import 'package:catalyst_app/features/auth/presentation/register_screen.dart';
import 'package:catalyst_app/features/auth/presentation/otp_screen.dart';
import 'package:catalyst_app/features/onboarding/presentation/screens/onboarding_shell.dart';
import 'package:catalyst_app/features/hackathons/presentation/hackathon_detail_screen.dart';
import 'package:catalyst_app/features/teams/presentation/create_team_screen.dart';
import 'package:catalyst_app/features/teams/presentation/join_team_screen.dart';
import 'package:catalyst_app/features/community/presentation/comments_screen.dart';
import 'package:catalyst_app/features/chat/presentation/chat_screen.dart';
import 'package:catalyst_app/features/notifications/presentation/notification_screen.dart';
import 'package:catalyst_app/features/admin/presentation/admin_dashboard_screen.dart';

CustomTransitionPage<T> _fadeSlideTransition<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}

final GoRouter router = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final client = Supabase.instance.client;
    final isAuthenticated = client.auth.currentSession?.user != null;
    final path = state.uri.path;
    final requiresAuth =
        path == '/admin' ||
        path == '/notifications' ||
        path.endsWith('/create-team') ||
        path.endsWith('/join-team');

    if (requiresAuth && !isAuthenticated) {
      return '/login';
    }
    if ((path == '/login' || path == '/register') && isAuthenticated) {
      return '/home';
    }
    if (path == '/home' && isAuthenticated) {
      final user = client.auth.currentUser;
      if (user != null) {
        final metadata = user.userMetadata;
        final onboardingCompleted = metadata?['onboarding_completed'] == true;
        if (!onboardingCompleted) {
          return '/onboarding';
        }
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          _fadeSlideTransition(key: state.pageKey, child: const LoginScreen()),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/otp',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: OtpScreen(email: state.extra as String? ?? ''),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: const OnboardingShell(),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: HomeShell()),
    ),
    GoRoute(
      path: '/hackathons/:id',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: HackathonDetailScreen(hackathonId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/hackathons/:id/create-team',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: CreateTeamScreen(hackathonId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/hackathons/:id/join-team',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: JoinTeamScreen(hackathonId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/community/comments/:postId',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: CommentsScreen(
          postId: state.pathParameters['postId']!,
          postAuthorId: state.extra as String? ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/chat/:teamId',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: ChatScreen(teamId: state.pathParameters['teamId']!),
      ),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: const NotificationScreen(),
      ),
    ),
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: const AdminDashboardScreen(),
      ),
    ),
  ],
);
