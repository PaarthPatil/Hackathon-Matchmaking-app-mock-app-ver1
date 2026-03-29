import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/team_model.dart';
import 'package:catalyst_app/features/teams/data/team_repository.dart';
import 'package:catalyst_app/features/teams/data/matching_service.dart';
import 'package:catalyst_app/features/notifications/data/notification_repository.dart';
import 'package:catalyst_app/models/notification_model.dart';
import 'package:catalyst_app/features/notifications/presentation/providers/notification_provider.dart';

class TeamState {
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
    String? error,
  }) {
    return TeamState(
      recommendedTeams: recommendedTeams ?? this.recommendedTeams,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TeamNotifier extends StateNotifier<TeamState> {
  final TeamRepository _repository;
  final MatchingService _matchingService;
  final Ref _ref;

  TeamNotifier(this._repository, this._matchingService, this._ref) : super(TeamState.initial());

  Future<void> fetchRecommendations(String userId, String hackathonId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 800));
      final skillsPool = ['Flutter', 'Python', 'Go', 'React', 'UI/UX', 'NodeJS', 'Supabase', 'Dart', 'Figma', 'Solidity'];
      final teams = List.generate(100, (index) => Team(
        id: 'team-$index',
        hackathonId: hackathonId,
        creatorId: 'user-$index',
        name: 'Neon Titan ${index + 1}',
        description: 'Hardcore team aiming to win 1st place. Must have 5+ years building top tier agentic applications. Only Elites.',
        membersCount: (index % 3) + 1,
        maxMembers: 4,
        requiredSkills: [skillsPool[index % skillsPool.length], skillsPool[(index + 3) % skillsPool.length]],
        matchingScore: 0.98 - (index * 0.005).clamp(0.0, 0.98),
        matchingExplanation: 'You share 2 critical skills with this team.',
      ));
      state = state.copyWith(recommendedTeams: teams, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createTeam(Team team) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 500));
      
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
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 500));
      
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
  // PROTOTYPE MOCK
  return null;
});

final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>((ref) {
  return TeamNotifier(
    ref.read(teamRepositoryProvider),
    ref.read(matchingServiceProvider),
    ref,
  );
});
