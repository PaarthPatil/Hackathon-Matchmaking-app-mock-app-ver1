import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:catalyst_app/core/constants/api_constants.dart';

class ApiService {
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.pythonBaseUrl}$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.pythonBaseUrl}$path'),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
