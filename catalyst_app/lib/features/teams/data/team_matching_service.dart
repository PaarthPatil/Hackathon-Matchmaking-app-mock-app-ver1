import 'package:catalyst_app/models/team_model.dart';
import 'package:catalyst_app/models/profile_model.dart';
import 'package:catalyst_app/core/services/api_service.dart';

class TeamMatchingService {
  final ApiService _api = ApiService();

  // As per ph17: Matching logic happens on Python Backend.
  // This Dart service acts as a client for Step 102 requirements.
  Future<List<Team>> getMatches(Profile user) async {
    try {
      // Step 6: Output Format (team_id, score, explanation) is handled 
      // by the Team model's matching fields.
      final data = await _api.getList('/matches?user_id=${user.id}');
      
      return (data as List).map((json) => Team.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
