import 'dart:io';

class OnboardingState {
  final int currentStep;
  final Set<String> selectedSkills;
  final Set<String> selectedInterests;
  final String? avatarUrl;
  final File? avatarFile;
  final String? experienceLevel;
  final String? availability;
  final String bio;
  final bool isCompleted;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.currentStep = 0,
    this.selectedSkills = const {},
    this.selectedInterests = const {},
    this.avatarUrl,
    this.avatarFile,
    this.experienceLevel,
    this.availability,
    this.bio = '',
    this.isCompleted = false,
    this.isLoading = false,
    this.error,
  });

  bool get canProceedFromSkills => selectedSkills.length >= 3;
  bool get canProceedFromInterests => selectedInterests.isNotEmpty;

  int get completeness {
    int score = 0;
    if (avatarUrl != null || avatarFile != null) score += 30;
    if (experienceLevel != null) score += 30;
    if (bio.isNotEmpty) score += 20;
    if (availability != null) score += 20;
    return score;
  }

  OnboardingState copyWith({
    int? currentStep,
    Set<String>? selectedSkills,
    Set<String>? selectedInterests,
    String? avatarUrl,
    File? avatarFile,
    String? experienceLevel,
    String? availability,
    String? bio,
    bool? isCompleted,
    bool? isLoading,
    String? error,
    bool clearAvatarFile = false,
    bool clearError = false,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedSkills: selectedSkills ?? this.selectedSkills,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarFile: clearAvatarFile ? null : (avatarFile ?? this.avatarFile),
      experienceLevel: experienceLevel ?? this.experienceLevel,
      availability: availability ?? this.availability,
      bio: bio ?? this.bio,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
