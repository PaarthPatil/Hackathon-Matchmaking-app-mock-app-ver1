import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:catalyst_app/features/home/presentation/home_shell.dart';
import 'package:catalyst_app/features/auth/presentation/login_screen.dart';
import 'package:catalyst_app/features/auth/presentation/register_screen.dart';
import 'package:catalyst_app/features/auth/presentation/otp_screen.dart';
import 'package:catalyst_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:catalyst_app/features/hackathons/presentation/hackathon_detail_screen.dart';
import 'package:catalyst_app/features/teams/presentation/create_team_screen.dart';
import 'package:catalyst_app/features/teams/presentation/join_team_screen.dart';
import 'package:catalyst_app/features/community/presentation/comments_screen.dart';
import 'package:catalyst_app/features/chat/presentation/chat_screen.dart';
import 'package:catalyst_app/features/notifications/presentation/notification_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

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
            begin: const Offset(0.05, 0), // Slight slide from right
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
    final isLoggedIn = Supabase.instance.client.auth.currentSession?.user != null;
    final authRoutes = <String>{'/login', '/register', '/otp'};
    final isAuthRoute = authRoutes.contains(state.matchedLocation);

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    if (isLoggedIn && isAuthRoute) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _fadeSlideTransition(
        key: state.pageKey,
        child: const LoginScreen(),
      ),
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
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => const NoTransitionPage(child: HomeShell()),
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
        child: CommentsScreen(postId: state.pathParameters['postId']!),
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
  ],
);
