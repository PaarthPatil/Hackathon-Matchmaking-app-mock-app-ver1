import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/core/constants/api_constants.dart';
import 'package:catalyst_app/core/services/auth_token_store.dart';

class CommunityApiService {
  final AuthTokenStore _tokenStore = AuthTokenStore();
  final SupabaseClient supabase = Supabase.instance.client;

  String get baseUrl => ApiConstants.pythonBaseUrl;

  // Helper to get auth headers for Python API
  Future<Map<String, String>> _getHeaders() async {
    final token = supabase.auth.currentSession?.accessToken ??
        await _tokenStore.readAccessToken();
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _logRequest(String method, Uri uri) {
    debugPrint('Community API -> $method $uri');
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    final body = response.body;
    final preview = body.length > 200 ? '${body.substring(0, 200)}...' : body;
    debugPrint('Community API <- $method $uri status=${response.statusCode} body=$preview');
  }

  // 1. Fetch Feed (Returns standard Future for pull-to-refresh)
  Future<List<dynamic>> fetchFeed({int limit = 20, int offset = 0}) async {
    final uri = Uri.parse('$baseUrl/community/posts').replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'sort': 'latest',
      },
    );
    
    final headers = await _getHeaders();
    _logRequest('GET', uri);
    
    final response = await http.get(uri, headers: headers);
    _logResponse('GET', uri, response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['items'] is List ? data['items'] as List : [];
    }
    throw Exception('Failed to load feed: ${response.statusCode}');
  }

  // 2. Upload Image Directly to Supabase Storage (The missing piece!)
  Future<String?> uploadImageToSupabase(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}.jpg';
      
      // Upload to Supabase Storage
      await supabase.storage.from('post_images').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: false),
      );
      
      // Return the public URL to send to Python
      final publicUrl = supabase.storage.from('post_images').getPublicUrl(fileName);
      debugPrint('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint("Image upload failed: $e");
      return null;
    }
  }

  // 3. Create Post
  Future<Map<String, dynamic>> createPost(String content, File? imageFile) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImageToSupabase(imageFile);
    }

    final uri = Uri.parse('$baseUrl/community/posts');
    final headers = await _getHeaders();
    
    final body = {
      'content': content,
      'image_url': imageUrl,
    };

    _logRequest('POST', uri);
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    _logResponse('POST', uri, response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create post: ${response.body}');
  }

  // 4. Toggle Like (Upvote/Downvote)
  Future<void> toggleLike(String postId, bool isUpvote) async {
    final uri = Uri.parse('$baseUrl/community/vote');
    final headers = await _getHeaders();
    
    final body = {
      'post_id': postId,
      'direction': isUpvote ? 'up' : 'down',
    };

    _logRequest('POST', uri);
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    _logResponse('POST', uri, response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('Failed to toggle like: ${response.body}');
  }

  // 5. Add Comment
  Future<Map<String, dynamic>> addComment(String postId, String content) async {
    final uri = Uri.parse('$baseUrl/community/comments');
    final headers = await _getHeaders();
    
    final body = {
      'post_id': postId,
      'content': content,
    };

    _logRequest('POST', uri);
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    _logResponse('POST', uri, response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to add comment: ${response.body}');
  }

  // 6. Soft Delete Post
  Future<void> deletePost(String postId) async {
    // Note: You'll need to add this endpoint to your backend
    final uri = Uri.parse('$baseUrl/community/posts/$postId');
    final headers = await _getHeaders();

    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: headers);
    _logResponse('DELETE', uri, response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('Failed to delete post: ${response.body}');
  }

  // 7. Fetch Comments for a Post
  Future<List<dynamic>> fetchComments(String postId, {int limit = 20, int offset = 0}) async {
    final uri = Uri.parse('$baseUrl/community/comments').replace(
      queryParameters: {
        'post_id': postId,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    
    final headers = await _getHeaders();
    _logRequest('GET', uri);
    
    final response = await http.get(uri, headers: headers);
    _logResponse('GET', uri, response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['items'] is List ? data['items'] as List : [];
    }
    throw Exception('Failed to load comments: ${response.statusCode}');
  }
}
