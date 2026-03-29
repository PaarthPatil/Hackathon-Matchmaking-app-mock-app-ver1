import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/profile_model.dart';
import 'package:catalyst_app/core/services/supabase_service.dart';
import 'package:catalyst_app/core/services/api_service.dart';

class ProfileRepository {
  final _supabase = SupabaseService().client;
  final _api = ApiService();

  Future<Profile> fetchProfile(String userId) async {
    try {
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      return Profile.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      // RULE 17: Business logic (updates) must go through Python API
      await _api.post('/profile/update', profile.toJson());
    } catch (e) {
      throw Exception('Failed to update profile via API: $e');
    }
  }

  Future<String> uploadAvatar(File file) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      await _supabase.storage.from('avatars').upload(
        path, 
        file, 
        fileOptions: const FileOptions(upsert: true)
      );
      
      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      
      // Update profile with new avatar URL via Python API
      await _api.post('/profile/update_avatar', {'userId': userId, 'avatarUrl': url});
      
      return url;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  Future<void> rewardXp(String userId, int xp) async {
    try {
      await _api.post('/profile/reward', {'user_id': userId, 'xp': xp});
    } catch (e) {
      throw Exception('Failed to reward XP: $e');
    }
  }
}
