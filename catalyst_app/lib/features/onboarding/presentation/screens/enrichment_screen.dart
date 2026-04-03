import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:catalyst_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:catalyst_app/features/onboarding/presentation/widgets/segmented_selector.dart';
import 'package:catalyst_app/features/onboarding/presentation/widgets/avatar_picker.dart';

class EnrichmentScreen extends ConsumerStatefulWidget {
  const EnrichmentScreen({super.key});

  @override
  ConsumerState<EnrichmentScreen> createState() => _EnrichmentScreenState();
}

class _EnrichmentScreenState extends ConsumerState<EnrichmentScreen> {
  final TextEditingController _bioController = TextEditingController();

  static const Map<String, String> _experienceLevels = {
    'Beginner': 'Beginner',
    'Intermediate': 'Intermediate',
    'Advanced': 'Advanced',
  };

  static const Map<String, String> _availabilityOptions = {
    'Full-time': 'Full-time',
    'Part-time': 'Part-time',
    'Weekends': 'Weekends only',
  };

  @override
  void initState() {
    super.initState();
    final bio = ref.read(onboardingProvider).bio;
    if (bio.isNotEmpty) {
      _bioController.text = bio;
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us a bit more',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 8),
                Text(
                  'Optional, but helps teammates know what to expect.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                const SizedBox(height: 32),
                Center(
                  child: AvatarPicker(
                    selectedFile: state.avatarFile,
                    existingUrl: state.avatarUrl,
                    onPick: (file) => notifier.setAvatarFile(file),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                const SizedBox(height: 32),
                Text(
                  'Experience level',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                const SizedBox(height: 12),
                SegmentedSelector<String>(
                  options: _experienceLevels,
                  selected: state.experienceLevel,
                  onChanged: (level) => notifier.setExperienceLevel(level),
                ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
                const SizedBox(height: 24),
                Text(
                  'Availability',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                const SizedBox(height: 12),
                Row(
                  children: _availabilityOptions.entries.map((entry) {
                    final isSelected = state.availability == entry.key;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => notifier.setAvailability(entry.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.3)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline.withValues(
                                        alpha: 0.3,
                                      ),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              entry.value,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 450.ms, duration: 300.ms),
                const SizedBox(height: 24),
                Text(
                  'Bio (optional)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioController,
                  maxLength: 150,
                  maxLines: 3,
                  onChanged: (value) => notifier.setBio(value),
                  decoration: InputDecoration(
                    hintText: 'I love building...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ).animate().fadeIn(delay: 550.ms, duration: 300.ms),
                const SizedBox(height: 24),
              ],
            ),
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
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: !state.isLoading
                      ? () => notifier.saveEnrichmentStep()
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => notifier.skipEnrichment(),
                child: Text(
                  'Skip this step',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
