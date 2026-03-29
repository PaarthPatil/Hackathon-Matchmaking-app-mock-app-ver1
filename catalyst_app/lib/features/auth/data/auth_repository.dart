import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/core/exceptions.dart' hide AuthException;
import 'package:catalyst_app/core/services/supabase_service.dart';

class AuthRepository {
  final _supabase = SupabaseService().client;

  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      return await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw AuthException('Invalid email or password');
      }
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<AuthResponse> signUp({required String email, required String password}) async {
    try {
      return await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> verifyOtp({required String email, required String token}) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
    } catch (e) {
      throw AuthException('Incorrect OTP, try again');
    }
  }

  User? getCurrentUser() => _supabase.auth.currentUser;

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException(e.toString());
    }
  }
}
