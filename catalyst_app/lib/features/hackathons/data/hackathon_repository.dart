import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/hackathon_model.dart';
import 'package:catalyst_app/core/services/supabase_service.dart';
import 'package:catalyst_app/core/exceptions.dart';

class HackathonRepository {
  final _supabase = SupabaseService().client;

  Future<List<Hackathon>> fetchHackathons({required int limit, required int offset}) async {
    try {
      final data = await _supabase
          .from('hackathons')
          .select()
          .range(offset, offset + limit - 1)
          .order('start_date', ascending: true);
      
      return (data as List).map((json) => Hackathon.fromJson(json)).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch hackathons');
    }
  }

  Future<Hackathon> fetchHackathonById(String id) async {
    try {
      final data = await _supabase
          .from('hackathons')
          .select()
          .eq('id', id)
          .single();
      
      return Hackathon.fromJson(data);
    } catch (e) {
      throw NetworkException('Failed to fetch hackathon detail: $e');
    }
  }
}
