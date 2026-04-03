import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catalyst_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:catalyst_app/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:catalyst_app/features/onboarding/presentation/screens/skills_screen.dart';
import 'package:catalyst_app/features/onboarding/presentation/screens/interests_screen.dart';
import 'package:catalyst_app/features/onboarding/presentation/screens/enrichment_screen.dart';
import 'package:catalyst_app/features/onboarding/presentation/screens/completion_screen.dart';
import 'package:catalyst_app/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';

class OnboardingShell extends ConsumerStatefulWidget {
  const OnboardingShell({super.key});

  @override
  ConsumerState<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends ConsumerState<OnboardingShell> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    ref.listen(onboardingProvider, (prev, next) {
      if (prev?.currentStep != next.currentStep) {
        _animateToPage(next.currentStep);
      }
      if (next.isCompleted) {
        context.go('/home');
      }
    });

    return Theme(
      data: Theme.of(context),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  OnboardingProgressBar(
                    currentStep: state.currentStep,
                    totalSteps: 5,
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {},
                      children: const [
                        WelcomeScreen(),
                        SkillsScreen(),
                        InterestsScreen(),
                        EnrichmentScreen(),
                        CompletionScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
