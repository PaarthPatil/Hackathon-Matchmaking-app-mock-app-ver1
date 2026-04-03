import 'package:catalyst_app/core/services/api_service.dart';

class AdminRepository {
  final ApiService _api;

  AdminRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<List<Map<String, dynamic>>> fetchHackathonRequests({String? status}) async {
    final Map<String, String> queryParams = {};
    if (status != null) queryParams['status'] = status;

    final response = await _api.get('/admin/hackathon-requests', queryParameters: queryParams);
    return List<Map<String, dynamic>>.from(response['items']);
  }

  Future<void> approveRequest(String requestId, Map<String, dynamic> payload) async {
    await _api.post('/admin/hackathon-requests/$requestId/approve', payload);
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    await _api.post('/admin/hackathon-requests/$requestId/reject', {'reason': reason});
  }

  Future<void> deleteHackathon(String hackathonId) async {
    await _api.delete('/admin/hackathons/$hackathonId');
  }

  Future<Map<String, dynamic>> fetchCatalog() async {
    return _api.get('/admin/catalog');
  }

  Future<List<Map<String, dynamic>>> fetchUsers({int limit = 50, int offset = 0}) async {
    final response = await _api.get(
      '/admin/users',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(response['items'] ?? const []);
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> payload) async {
    final response = await _api.post('/admin/users/create', payload);
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> createHackathon(Map<String, dynamic> payload) async {
    final response = await _api.post('/admin/hackathons/create', payload);
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> payload) async {
    final response = await _api.post('/admin/teams/create', payload);
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> seedMockData({
    int userCount = 8,
    int hackathonCount = 3,
    int teamsPerHackathon = 2,
    bool includeSocialFeed = true,
  }) async {
    final response = await _api.post('/admin/testing/seed', {
      'user_count': userCount,
      'hackathon_count': hackathonCount,
      'teams_per_hackathon': teamsPerHackathon,
      'include_social_feed': includeSocialFeed,
    });
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> triggerTestEvents({
    String? targetUserId,
    String? targetTeamId,
    String? targetPostId,
    String? message,
    bool createNotification = true,
    bool createPost = true,
    bool createComment = true,
    bool createJoinRequest = true,
    bool createChatMessage = true,
  }) async {
    final response = await _api.post('/admin/testing/trigger-events', {
      'target_user_id': targetUserId,
      'target_team_id': targetTeamId,
      'target_post_id': targetPostId,
      'message': message,
      'create_notification': createNotification,
      'create_post': createPost,
      'create_comment': createComment,
      'create_join_request': createJoinRequest,
      'create_chat_message': createChatMessage,
    });
    return Map<String, dynamic>.from(response);
  }
}
