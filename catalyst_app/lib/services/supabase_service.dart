import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  String? get currentUserId => supabase.auth.currentUser?.id;

  // Onboarding methods
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> updateOnboardingStep(Map<String, dynamic> data) async {
    if (currentUserId == null) throw Exception('Not authenticated');
    await supabase.from('profiles').update(data).eq('id', currentUserId!);
  }

  Future<void> completeOnboarding() async {
    await updateOnboardingStep({'onboarding_completed': true});
  }

  Future<String> uploadAvatar(String filePath, Uint8List fileBytes) async {
    if (currentUserId == null) throw Exception('Not authenticated');
    final path = 'avatars/$currentUserId.jpg';
    await supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return supabase.storage.from('avatars').getPublicUrl(path);
  }
}
