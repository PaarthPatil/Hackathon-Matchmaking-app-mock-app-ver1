import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/team_model.dart';
import 'package:catalyst_app/core/services/supabase_service.dart';
import 'package:catalyst_app/core/services/api_service.dart';
import 'package:catalyst_app/core/exceptions.dart' hide AuthException;

class TeamRepository {
  final _supabase = SupabaseService().client;
  final _api = ApiService();

  // Create Team -> Python API (Business Logic Rule 17)
  Future<void> createTeam(Team team) async {
    try {
      await _api.post('/teams/create', team.toJson());
    } catch (e) {
      throw NetworkException('Failed to create team. Ensure you have unique skillsets.');
    }
  }

  // Supabase Edge Function: team-join-request (Goal ph16)
  Future<void> joinTeam(String teamId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw AuthException('User not authenticated');

      final response = await _supabase.functions.invoke(
        'team-join-request',
        body: {'userId': user.id, 'teamId': teamId},
      );

      if (response.status != 200 && response.status != 201) {
        throw NetworkException(response.data['error'] ?? 'Join request failed');
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // Fetch Recommended Teams for Hackathon -> Supabase read is allowed
  Future<List<Team>> fetchTeamsForHackathon(String hackathonId) async {
    try {
      final data = await _supabase
          .from('teams')
          .select()
          .eq('hackathon_id', hackathonId);
      
      return (data as List).map((json) => Team.fromJson(json)).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch teams');
    }
  }

  // Fetch User Teams -> Supabase read is allowed
  Future<List<Team>> fetchUserTeams(String userId) async {
    try {
      final data = await _supabase
          .from('team_members')
          .select('*, teams(*)')
          .eq('user_id', userId);
      
      return (data as List).map((json) => Team.fromJson(json['teams'])).toList();
    } catch (e) {
      throw NetworkException('Failed to load your team data');
    }
  }
}
