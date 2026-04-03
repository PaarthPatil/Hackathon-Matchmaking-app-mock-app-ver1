import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:catalyst_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:catalyst_app/features/onboarding/presentation/widgets/interest_card.dart';

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  static const List<Map<String, String>> _interests = [
    {'label': 'AI / ML', 'emoji': '🤖'},
    {'label': 'Web3', 'emoji': '🔗'},
    {'label': 'HealthTech', 'emoji': '🏥'},
    {'label': 'FinTech', 'emoji': '💰'},
    {'label': 'EdTech', 'emoji': '🎓'},
    {'label': 'Climate', 'emoji': '🌍'},
    {'label': 'Gaming', 'emoji': '🎮'},
    {'label': 'Social Impact', 'emoji': '💡'},
    {'label': 'Dev Tools', 'emoji': '🛠️'},
    {'label': 'Open Source', 'emoji': '🌐'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What excites you?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 8),
              Text(
                'Choose the domains you want to build in. We\'ll surface relevant hackathons and teams.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: _interests.length,
            itemBuilder: (context, index) {
              final interest = _interests[index];
              return InterestCard(
                label: interest['label']!,
                emoji: interest['emoji']!,
                isSelected: state.selectedInterests.contains(interest['label']),
                onTap: () => notifier.toggleInterest(interest['label']!),
              ).animate().fadeIn(
                delay: Duration(milliseconds: 80 * index),
                duration: 300.ms,
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '${state.selectedInterests.length} selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: state.canProceedFromInterests
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: state.canProceedFromInterests
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: state.canProceedFromInterests && !state.isLoading
                      ? () => notifier.saveInterestsStep()
                      : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: state.isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          'Continue →',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
