import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/profile_model.dart';
import 'package:catalyst_app/features/profile/data/profile_repository.dart';
import 'package:catalyst_app/shared/providers/achievement_provider.dart';
import 'package:catalyst_app/features/auth/presentation/providers/auth_provider.dart';

class ProfileNotifier extends StateNotifier<AsyncValue<Profile?>> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Listen to changes in auth status to automatically fetch profile
    _ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && next.user != null) {
        fetchProfile(next.user!.id);
      } else if (next.status == AuthStatus.unauthenticated) {
        state = const AsyncValue.data(null);
      }
    });

    // Initial fetch if already authenticated
    final authState = _ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      fetchProfile(authState.user!.id);
    }
  }

  Future<void> fetchProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      // PROTOTYPE MOCK: Fake Network Call
      await Future.delayed(const Duration(milliseconds: 600));
      final profile = Profile(
        id: userId,
        name: 'Alex Elite',
        username: 'alex_elite',
        bio: 'Senior Flutter Developer & System Architect. Love building cool stuff.',
        xp: 350,
        level: 4,
        skills: ['Flutter', 'Dart', 'Supabase', 'Python'],
        techStack: ['Flutter', 'Firebase', 'PostgreSQL'],
        hackathonsJoined: 14,
        wins: 4,
        teamsJoined: 10,
        avatarUrl: 'https://i.pravatar.cc/150?img=11',
      );
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      await _repository.updateProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadAvatar(File file) async {
    try {
       final url = await _repository.uploadAvatar(file);
       final currentProfile = state.value;
       if (currentProfile != null) {
         final updated = currentProfile.copyWith(avatarUrl: url);
         state = AsyncValue.data(updated);
       }
    } catch (e, st) {
       state = AsyncValue.error(e, st);
    }
  }
  Future<void> rewardXp(int amount) async {
    final current = state.value;
    if (current == null) return;

    final newXp = current.xp + amount;
    
    // CATALYST ELITE: Progression Mastery (Phase 11)
    // Simple logic: Level up every 100 XP
    final int newLevel = (newXp / 100).floor() + 1;
    final bool leveledUp = newLevel > current.level;

    final updated = current.copyWith(xp: newXp, level: newLevel);
    state = AsyncValue.data(updated);

    try {
      await _repository.rewardXp(current.id, amount);
      
      if (leveledUp) {
        _ref.read(achievementProvider.notifier).trigger(
          'Level $newLevel Reached!',
          'You are climbing the ranks of the elite!',
        );
      }
    } catch (e) {
      // Rollback UI on failure
      state = AsyncValue.data(current);
    }
  }
}

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<Profile?>>((ref) {
  return ProfileNotifier(ref.read(profileRepositoryProvider), ref);
});
