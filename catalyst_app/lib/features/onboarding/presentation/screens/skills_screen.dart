import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:catalyst_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:catalyst_app/features/onboarding/presentation/widgets/skill_chip.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Map<String, List<String>> _skillCategories = {
    'Frontend': [
      'React',
      'Flutter',
      'Vue.js',
      'Angular',
      'Svelte',
      'Next.js',
      'HTML/CSS',
    ],
    'Backend': [
      'Node.js',
      'Python',
      'Go',
      'Rust',
      'Java',
      'Django',
      'FastAPI',
      'Express',
    ],
    'Mobile': ['Swift', 'Kotlin', 'React Native', 'Dart'],
    'Data / AI': [
      'TensorFlow',
      'PyTorch',
      'SQL',
      'MongoDB',
      'PostgreSQL',
      'Pandas',
    ],
    'DevOps': ['Docker', 'Kubernetes', 'AWS', 'Firebase', 'Git', 'CI/CD'],
    'Design': ['Figma', 'UI/UX Design', 'Prototyping'],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<String>>> _filteredCategories() {
    if (_searchQuery.isEmpty) return _skillCategories.entries.toList();
    return _skillCategories.entries
        .map((entry) {
          final filtered = entry.value
              .where(
                (s) => s.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
          return MapEntry(entry.key, filtered);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final categories = _filteredCategories();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you good at?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 8),
              Text(
                'Pick your top skills. This helps us match you with complementary teammates.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search skills...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Text(
                      category.key,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: category.value.map((skill) {
                      return SkillChip(
                        label: skill,
                        isSelected: state.selectedSkills.contains(skill),
                        onTap: () => notifier.toggleSkill(skill),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ).animate().fadeIn(
                delay: Duration(milliseconds: 100 * index),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    state.canProceedFromSkills
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: state.canProceedFromSkills
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${state.selectedSkills.length} of 3 minimum selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: state.canProceedFromSkills
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: state.canProceedFromSkills
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: state.canProceedFromSkills && !state.isLoading
                      ? () => notifier.saveSkillsStep()
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
