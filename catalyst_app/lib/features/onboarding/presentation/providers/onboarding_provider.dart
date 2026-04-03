import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/features/onboarding/data/models/onboarding_state.dart';
import 'package:catalyst_app/features/onboarding/data/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(Supabase.instance.client);
});

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier(ref.watch(onboardingRepositoryProvider));
    });

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingRepository _repo;

  OnboardingNotifier(this._repo) : super(const OnboardingState()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final profile = await _repo.fetchProfile();
    if (profile != null) {
      state = OnboardingState(
        currentStep: profile['onboarding_step'] ?? 0,
        selectedSkills: Set<String>.from(profile['skills'] ?? []),
        selectedInterests: Set<String>.from(profile['interests'] ?? []),
        experienceLevel: profile['experience_level'],
        availability: profile['availability'],
        bio: profile['bio'] ?? '',
        avatarUrl: profile['avatar_url'],
        isCompleted: profile['onboarding_completed'] ?? false,
      );
    }
  }

  void nextStep() {
    state = state.copyWith(
      currentStep: state.currentStep + 1,
      clearError: true,
    );
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
      );
    }
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step, clearError: true);
  }

  void toggleSkill(String skill) {
    final skills = Set<String>.from(state.selectedSkills);
    if (skills.contains(skill)) {
      skills.remove(skill);
    } else {
      skills.add(skill);
    }
    state = state.copyWith(selectedSkills: skills, clearError: true);
  }

  void toggleInterest(String interest) {
    final interests = Set<String>.from(state.selectedInterests);
    if (interests.contains(interest)) {
      interests.remove(interest);
    } else {
      interests.add(interest);
    }
    state = state.copyWith(selectedInterests: interests, clearError: true);
  }

  void setExperienceLevel(String level) {
    state = state.copyWith(experienceLevel: level);
  }

  void setAvailability(String availability) {
    state = state.copyWith(availability: availability);
  }

  void setBio(String bio) {
    state = state.copyWith(bio: bio);
  }

  void setAvatarFile(File file) {
    state = state.copyWith(avatarFile: file);
  }

  Future<bool> saveSkillsStep() async {
    if (!state.canProceedFromSkills) {
      state = state.copyWith(error: 'Select at least 3 skills');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.saveSkills(state.selectedSkills.toList());
      state = state.copyWith(isLoading: false);
      nextStep();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save skills. Please try again.',
      );
      return false;
    }
  }

  Future<bool> saveInterestsStep() async {
    if (!state.canProceedFromInterests) {
      state = state.copyWith(error: 'Pick at least 1 interest');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.saveInterests(state.selectedInterests.toList());
      state = state.copyWith(isLoading: false);
      nextStep();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save interests. Please try again.',
      );
      return false;
    }
  }

  Future<bool> saveEnrichmentStep() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      String? avatarUrl;
      if (state.avatarFile != null) {
        avatarUrl = await _repo.uploadAvatar(state.avatarFile!);
      }
      await _repo.saveEnrichment(
        experienceLevel: state.experienceLevel,
        availability: state.availability,
        bio: state.bio.isNotEmpty ? state.bio : null,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(
        isLoading: false,
        avatarUrl: avatarUrl,
        clearAvatarFile: true,
      );
      nextStep();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save profile. Please try again.',
      );
      return false;
    }
  }

  Future<bool> completeOnboarding() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.completeOnboarding();
      state = state.copyWith(isCompleted: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete setup. Please try again.',
      );
      return false;
    }
  }

  void skipEnrichment() {
    nextStep();
  }
}
