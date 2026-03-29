import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/team_model.dart';
import 'package:catalyst_app/core/services/supabase_service.dart';

class MatchingService {
  final _supabase = SupabaseService().client;

  // Supabase Edge Function: match-teams (Goal ph16)
  Future<List<Team>> fetchRecommendedTeams(String userId, String hackathonId) async {
    try {
      final response = await _supabase.functions.invoke(
        'match-teams',
        body: {'userId': userId, 'hackathonId': hackathonId},
      );

      if (response.status != 200 && response.status != 201) {
        throw Exception('Matching function failed');
      }

      final data = response.data as List;
      return data.map((json) => Team.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
