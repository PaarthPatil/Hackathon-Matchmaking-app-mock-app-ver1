import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:catalyst_app/features/onboarding/presentation/providers/onboarding_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 40),
          Text(
                "Let's build your profile",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                delay: 200.ms,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 16),
          Text(
                "Answer a few quick questions so we can find your perfect hackathon teammates.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                delay: 400.ms,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
          const Spacer(flex: 2),
          SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).nextStep();
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Let's Go →",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 600.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Takes about 45 seconds',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(delay: 700.ms, duration: 300.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
