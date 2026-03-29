import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/features/auth/data/auth_repository.dart';

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
  StreamSubscription<AuthState>? _authSubscription;
  late final StreamSubscription<AuthState> _stateSubscription;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    _init();
    _listenToAuthChanges();
  }

  void _init() {
    // PROTOTYPE MODE: Bypass authentication checks and provide a mock user
    state = AuthState(
      status: AuthStatus.authenticated,
      user: const User(
        id: '11111111-1111-1111-1111-111111111111', // Dummy ID
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
    );
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        state = AuthState(status: AuthStatus.authenticated, user: session.user);
      } else if (event == AuthChangeEvent.signedOut || event == AuthChangeEvent.userDeleted) {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.signIn(email: email, password: password);
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
