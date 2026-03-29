import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catalyst_app/features/community/presentation/community_screen.dart';
import 'package:catalyst_app/features/hackathons/presentation/hackathon_screen.dart';
import 'package:catalyst_app/features/profile/presentation/profile_screen.dart';
import 'package:catalyst_app/features/notifications/presentation/notification_screen.dart';
import 'package:catalyst_app/shared/widgets/connectivity_banner.dart';
import 'package:catalyst_app/shared/widgets/achievement_overlay.dart';
import 'package:catalyst_app/shared/providers/achievement_provider.dart';
import 'package:catalyst_app/features/notifications/presentation/providers/notification_provider.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int currentIndex = 2; // Profile default as per ph2
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 2);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.notifications.where((n) => !n.read).length;
    final achievement = ref.watch(achievementProvider);

    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        title: const Text('Catalyst'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount.toString()),
              child: const Icon(Icons.notifications_none),
            ),
            onPressed: () => context.push('/notifications'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0), 
          child: ConnectivityBanner(isConnected: true), // Mock for Ph10 demonstration
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        children: const [
          CommunityScreen(),
          HackathonScreen(),
          ProfileScreen(),
        ],
      ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Community',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events),
              label: 'Hackathons',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      if (achievement != null)
        AchievementOverlay(
          title: achievement.title,
          description: achievement.description,
          onDismiss: () => ref.read(achievementProvider.notifier).clear(),
        ),
      ],
    );
  }
}
