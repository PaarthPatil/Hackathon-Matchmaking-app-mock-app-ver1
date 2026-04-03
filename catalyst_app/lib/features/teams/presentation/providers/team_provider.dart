import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/team_model.dart';
import 'package:catalyst_app/features/teams/data/team_repository.dart';
import 'package:catalyst_app/features/teams/data/matching_service.dart';
import 'package:catalyst_app/features/auth/presentation/providers/auth_provider.dart';

class TeamState {
  static const Object _noErrorChange = Object();
  final List<Team> recommendedTeams;
  final bool isLoading;
  final String? error;

  TeamState({
    required this.recommendedTeams,
    this.isLoading = false,
    this.error,
  });

  factory TeamState.initial() => TeamState(recommendedTeams: []);

  TeamState copyWith({
    List<Team>? recommendedTeams,
    bool? isLoading,
    Object? error = _noErrorChange,
  }) {
    return TeamState(
      recommendedTeams: recommendedTeams ?? this.recommendedTeams,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _noErrorChange) ? this.error : error as String?,
    );
  }
}

class TeamNotifier extends StateNotifier<TeamState> {
  final TeamRepository _repository;
  final MatchingService _matchingService;
  final Ref _ref;

  TeamNotifier(this._repository, this._matchingService, this._ref) : super(TeamState.initial());

  Future<void> fetchRecommendations(
    String userId,
    String hackathonId, {
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final teams = await _matchingService.fetchRecommendedTeams(
        userId,
        hackathonId,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(
        recommendedTeams: teams,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createTeam(Team team) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createTeam(team);
      
      // CATALYST ELITE: State Synchronization (Rule 88)
      _ref.invalidate(userTeamProvider(team.hackathonId));
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> joinTeam(Team team) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.joinTeam(team.id);
      
      // CATALYST ELITE: State Synchronization (Rule 90)
      _ref.invalidate(userTeamProvider(team.hackathonId));
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final teamRepositoryProvider = Provider((ref) => TeamRepository());
final matchingServiceProvider = Provider((ref) => MatchingService());

final userTeamProvider = FutureProvider.family<String?, String>((ref, hackathonId) async {
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated) {
    return null;
  }
  final userId = authState.userId;
  if (userId.isEmpty) {
    return null;
  }
  final teams = await ref.read(teamRepositoryProvider).fetchUserTeams(userId);
  for (final team in teams) {
    if (team.hackathonId == hackathonId) {
      return team.id;
    }
  }
  return null;
});

final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>((ref) {
  return TeamNotifier(
    ref.read(teamRepositoryProvider),
    ref.read(matchingServiceProvider),
    ref,
  );
});
