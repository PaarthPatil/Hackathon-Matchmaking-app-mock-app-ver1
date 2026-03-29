import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Sign in placeholder
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email, password: password,
    );
  }

  // Example of other methods for Phase 1
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
