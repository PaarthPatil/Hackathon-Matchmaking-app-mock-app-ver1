import 'package:catalyst_app/models/team_model.dart';
import 'package:catalyst_app/core/services/api_service.dart';

class MatchingService {
  final _api = ApiService();

  Future<List<Team>> fetchRecommendedTeams(
    String _,
    String hackathonId, {
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _api.post(
        '/teams/recommendations',
        {
          'hackathon_id': hackathonId,
          'force_refresh': forceRefresh,
        },
      );
      if (response is! List) {
        return [];
      }
      return response
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => Team(
              id: json['team_id'] as String,
              hackathonId: hackathonId,
              creatorId: '',
              name: json['team_name'] as String?,
              requiredSkills: const [],
              membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
              matchingScore: ((json['compatibility_score'] as num?)?.toDouble() ?? 0) / 100.0,
              matchingExplanation: json['explanation'] as String?,
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
