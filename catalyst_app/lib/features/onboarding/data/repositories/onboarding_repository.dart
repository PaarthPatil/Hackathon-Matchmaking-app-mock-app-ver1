import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingRepository {
  final SupabaseClient _supabase;

  OnboardingRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<Map<String, dynamic>?> fetchProfile() async {
    if (_userId == null) return null;
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', _userId!)
        .maybeSingle();
    return response;
  }

  Future<void> saveStep(Map<String, dynamic> data) async {
    if (_userId == null) throw Exception('Not authenticated');
    await _supabase.from('profiles').update(data).eq('id', _userId!);
  }

  Future<String> uploadAvatar(File file) async {
    if (_userId == null) throw Exception('Not authenticated');
    final path = 'avatars/$_userId.jpg';
    await _supabase.storage
        .from('avatars')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> completeOnboarding() async {
    await saveStep({'onboarding_completed': true});
  }

  Future<void> updateStep(int step) async {
    await saveStep({'onboarding_step': step});
  }

  Future<void> saveSkills(List<String> skills) async {
    await saveStep({'skills': skills, 'onboarding_step': 2});
  }

  Future<void> saveInterests(List<String> interests) async {
    await saveStep({'interests': interests, 'onboarding_step': 3});
  }

  Future<void> saveEnrichment({
    String? experienceLevel,
    String? availability,
    String? bio,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{'onboarding_step': 4};
    if (experienceLevel != null) data['experience_level'] = experienceLevel;
    if (availability != null) data['availability'] = availability;
    if (bio != null) data['bio'] = bio;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    await saveStep(data);
  }
}
