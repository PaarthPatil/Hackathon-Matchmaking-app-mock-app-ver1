
import 'package:catalyst_app/models/post_model.dart';
import 'package:catalyst_app/models/comment_model.dart';
import 'package:catalyst_app/core/services/api_service.dart';
import 'package:catalyst_app/core/exceptions.dart' hide AuthException;

class CommunityRepository {
  final _api = ApiService();

  // READ via backend API to keep data flow consistent with RLS.
  Future<List<Post>> fetchPosts({int limit = 20, int offset = 0}) async {
    try {
      final response = await _api.get('/community/posts', queryParameters: {
        'limit': limit,
        'offset': offset,
        'sort': 'latest',
      });
      final items = (response['items'] is List) ? response['items'] as List : const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((json) => Post.fromJson(json))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to fetch posts: $e');
    }
  }

  // WRITE (Business Logic Rule 17) via Python API
  Future<void> createPost(Post post) async {
    try {
      await _api.post('/community/posts', post.toJson());
    } catch (e) {
      throw NetworkException('Failed to create post');
    }
  }

  // Voting (Business Logic Rule 17) via Python API
  Future<void> vote(String postId, bool isUpvote) async {
    // Validate UUID format before sending to backend
    if (!_isValidUuid(postId)) {
      throw NetworkException('Invalid post ID format');
    }
    
    try {
      await _api.post('/community/vote', {
        'post_id': postId,
        'direction': isUpvote ? 'up' : 'down',
      });
    } catch (e) {
      throw NetworkException('Failed to cast vote');
    }
  }

  // Helper method to validate UUID format
  bool _isValidUuid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(uuid);
  }

  // READ via backend API to avoid direct Supabase table access.
  Future<List<Comment>> fetchComments(String postId) async {
    try {
      final response = await _api.get('/community/comments', queryParameters: {
        'post_id': postId,
        'limit': 100,
        'offset': 0,
      });
      final items = (response['items'] is List) ? response['items'] as List : const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((json) => Comment.fromJson(json))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to fetch comments: $e');
    }
  }

  // CREATE Comment via Python API (Rule 17)
  Future<void> createComment(Comment comment) async {
    try {
      await _api.post('/community/comments', comment.toJson());
    } catch (e) {
      throw NetworkException('Failed to create comment');
    }
  }
}
