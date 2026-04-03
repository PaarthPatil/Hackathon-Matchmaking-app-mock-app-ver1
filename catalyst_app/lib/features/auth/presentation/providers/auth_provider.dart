import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/features/auth/data/auth_repository.dart';
import 'package:catalyst_app/core/services/auth_token_store.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  /// Returns the current user's ID or an empty string when not signed in.
  String get userId => user?.id ?? '';

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final AuthTokenStore _tokenStore = AuthTokenStore();
  StreamSubscription<dynamic>? _authSubscription;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    _init();
    _listenToAuthChanges();
  }

  void _init() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session?.user != null) {
      final token = session?.accessToken ?? '';
      if (token.isNotEmpty) {
        unawaited(_tokenStore.saveAccessToken(token));
      }
      debugPrint('Auth init session found. token_present=${token.isNotEmpty}');
      state = AuthState(status: AuthStatus.authenticated, user: session!.user);
      return;
    }
    unawaited(_tokenStore.clearAccessToken());
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final token = session.accessToken;
        if (token.isNotEmpty) {
          unawaited(_tokenStore.saveAccessToken(token));
        }
        debugPrint('Auth event signedIn. token_present=${token.isNotEmpty}');
        state = AuthState(status: AuthStatus.authenticated, user: session.user);
      } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
        final token = session.accessToken;
        if (token.isNotEmpty) {
          unawaited(_tokenStore.saveAccessToken(token));
        }
        debugPrint('Auth event tokenRefreshed. token_present=${token.isNotEmpty}');
      } else if (event == AuthChangeEvent.signedOut) {
        unawaited(_tokenStore.clearAccessToken());
        debugPrint('Auth event signedOut. token cleared.');
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.signIn(email: email, password: password);
      final token = response.session?.accessToken ?? '';
      if (token.isNotEmpty) {
        await _tokenStore.saveAccessToken(token);
      }
      debugPrint('Login completed. token_present=${token.isNotEmpty}');
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.signUp(email: email, password: password);
      final token = response.session?.accessToken ?? '';
      if (token.isNotEmpty) {
        await _tokenStore.saveAccessToken(token);
      }
      debugPrint('Register completed. token_present=${token.isNotEmpty}');
      // No immediate authenticated state if email confirmation is required
      if (response.user != null && response.session == null) {
        state = AuthState(status: AuthStatus.unauthenticated);
      } else {
        state = AuthState(status: AuthStatus.authenticated, user: response.user);
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
    await _tokenStore.clearAccessToken();
    debugPrint('Logout completed. token cleared.');
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
