import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/team_model.dart';
import 'package:catalyst_app/core/services/supabase_service.dart';
import 'package:catalyst_app/core/services/api_service.dart';
import 'package:catalyst_app/core/exceptions.dart' hide AuthException;

class TeamRepository {
  final ApiService _api;

  TeamRepository({ApiService? api}) : _api = api ?? ApiService();

  SupabaseClient get _supabase => SupabaseService().client;

  Map<String, dynamic> _toCreateTeamPayload(Team team) {
    return {
      'hackathon_id': team.hackathonId,
      'name': (team.name ?? '').trim(),
      'description': (team.description ?? '').trim(),
      'required_skills': team.requiredSkills,
      'max_members': team.maxMembers ?? 4,
    };
  }

  Team _fromRecommendationJson(Map<String, dynamic> json, String hackathonId) {
    return Team(
      id: json['team_id'] as String,
      hackathonId: hackathonId,
      creatorId: '',
      name: json['team_name'] as String?,
      description: null,
      requiredSkills: const [],
      maxMembers: null,
      matchingScore: ((json['compatibility_score'] as num?)?.toDouble() ?? 0) / 100.0,
      matchingExplanation: json['explanation'] as String?,
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> createTeam(Team team) async {
    try {
      await _api.post('/teams/create', _toCreateTeamPayload(team));
    } catch (e) {
      throw NetworkException('Failed to create team. Ensure you have unique skillsets.');
    }
  }

  Future<void> joinTeam(String teamId) async {
    try {
      await _api.post('/teams/join', {'team_id': teamId});
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<List<Team>> fetchRecommendedTeams(String hackathonId) async {
    try {
      final data = await _api.post('/teams/recommendations', {'hackathon_id': hackathonId});
      final items = (data is List)
          ? data
          : (data is Map<String, dynamic> && data['items'] is List
              ? data['items'] as List
              : const []);
      return items
          .whereType<Map<String, dynamic>>()
          .map((json) => _fromRecommendationJson(json, hackathonId))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to fetch recommended teams');
    }
  }

  // Fetch User Teams -> Supabase read is allowed
  Future<List<Team>> fetchUserTeams(String userId) async {
    try {
      final data = await _supabase
          .from('team_members')
          .select('*, teams(*)')
          .eq('user_id', userId)
          .eq('status', 'accepted');
      
      return (data as List).map((json) => Team.fromJson(json['teams'])).toList();
    } catch (e) {
      throw NetworkException('Failed to load your team data');
    }
  }
}
