import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      if (next.status == AuthStatus.authenticated) {
        fetchProfile(next.userId);
      } else if (next.status == AuthStatus.unauthenticated) {
        state = const AsyncValue.data(null);
      }
    });

    // Initial fetch only for authenticated users.
    final authState = _ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      fetchProfile(authState.userId);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> fetchProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.fetchProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      await _repository.updateProfile(profile);
      final refreshed = await _repository.fetchProfile(profile.id);
      state = AsyncValue.data(refreshed);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadAvatar(File file) async {
    try {
       final url = await _repository.uploadAvatar(file);
       final currentProfile = state.value;
       if (currentProfile != null) {
         final refreshed = await _repository.fetchProfile(currentProfile.id);
         state = AsyncValue.data(refreshed.copyWith(avatarUrl: refreshed.avatarUrl ?? url));
       }
    } catch (e, st) {
       state = AsyncValue.error(e, st);
    }
  }
  Future<void> rewardXp(int amount) async {
    final current = state.value;
    if (current == null) return;

    try {
      await _repository.rewardXp(current.id, amount);
      final refreshed = await _repository.fetchProfile(current.id);
      final bool leveledUp = refreshed.level > current.level;
      state = AsyncValue.data(refreshed);
      
      if (leveledUp) {
        _ref.read(achievementProvider.notifier).trigger(
          'Level ${refreshed.level} Reached!',
          'You are climbing the ranks of the elite!',
        );
      }
    } catch (e) {
      state = AsyncValue.data(current);
    }
  }
}

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<Profile?>>((ref) {
  return ProfileNotifier(ref.read(profileRepositoryProvider), ref);
});
