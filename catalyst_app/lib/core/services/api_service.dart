import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/core/constants/api_constants.dart';
import 'package:catalyst_app/core/services/auth_token_store.dart';

class ApiService {
  final AuthTokenStore _tokenStore = AuthTokenStore();

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = Supabase.instance.client.auth.currentSession?.accessToken ??
        await _tokenStore.readAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final masked = token == null || token.isEmpty
        ? 'none'
        : '${token.substring(0, token.length > 12 ? 12 : token.length)}...';
    debugPrint('API auth token attached: $masked');
    return headers;
  }

  void _logRequest(String method, Uri uri) {
    debugPrint('API -> $method $uri');
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    final body = response.body;
    final preview = body.length > 400 ? '${body.substring(0, 400)}...' : body;
    debugPrint('API <- $method $uri status=${response.statusCode} body=$preview');
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.pythonBaseUrl}$path');
    final headers = await _buildHeaders();
    _logRequest('POST', uri);
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    _logResponse('POST', uri, response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = Uri.parse('${ApiConstants.pythonBaseUrl}$path').replace(
      queryParameters: queryParameters?.map((k, v) => MapEntry(k, v.toString())),
    );
    final headers = await _buildHeaders();
    _logRequest('GET', uri);
    final response = await http.get(
      uri,
      headers: headers,
    );
    _logResponse('GET', uri, response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = Uri.parse('${ApiConstants.pythonBaseUrl}$path').replace(
      queryParameters: queryParameters?.map((k, v) => MapEntry(k, v.toString())),
    );
    final headers = await _buildHeaders();
    _logRequest('GET', uri);
    final response = await http.get(
      uri,
      headers: headers,
    );
    _logResponse('GET', uri, response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('${ApiConstants.pythonBaseUrl}$path');
    final headers = await _buildHeaders();
    _logRequest('DELETE', uri);
    final response = await http.delete(
      uri,
      headers: headers,
    );
    _logResponse('DELETE', uri, response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
