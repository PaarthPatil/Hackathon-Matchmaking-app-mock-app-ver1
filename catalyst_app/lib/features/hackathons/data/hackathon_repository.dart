
import 'package:catalyst_app/models/hackathon_model.dart';
import 'package:catalyst_app/core/services/api_service.dart';
import 'package:catalyst_app/core/exceptions.dart';

class HackathonRepository {
  final ApiService _api;

  HackathonRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<List<Hackathon>> fetchHackathons({required int limit, required int offset}) async {
    try {
      final page = (offset ~/ limit) + 1;
      final response = await _api.get(
        '/hackathons',
        queryParameters: {
          'page': page,
          'page_size': limit,
        },
      );
      final items = (response['items'] is List) ? response['items'] as List : const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((json) => Hackathon.fromJson(json))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to fetch hackathons: $e');
    }
  }

  Future<Hackathon> fetchHackathonById(String id) async {
    try {
      final data = await _api.get('/hackathons/$id');
      return Hackathon.fromJson(data);
    } catch (e) {
      throw NetworkException('Failed to fetch hackathon detail: $e');
    }
  }
}
