import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/post_model.dart';
import 'package:catalyst_app/models/comment_model.dart';
import 'package:catalyst_app/core/services/api_service.dart';
import 'package:catalyst_app/core/services/supabase_service.dart';
import 'package:catalyst_app/core/exceptions.dart' hide AuthException;

class CommunityRepository {
  final _supabase = SupabaseService().client;
  final _api = ApiService();

  // READ from Supabase is allowed
  Future<List<Post>> fetchPosts({int limit = 20, int offset = 0}) async {
    try {
      final data = await _supabase
          .from('posts')
          .select('*, profiles(*)')
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);
      
      return (data as List).map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch posts');
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
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw AuthException('User not authenticated');

      await _api.post('/community/vote', {
        'post_id': postId,
        'user_id': user.id,
        'direction': isUpvote ? 'up' : 'down',
      });
    } catch (e) {
      throw NetworkException('Failed to cast vote');
    }
  }

  // READ Comments from Supabase is allowed
  Future<List<Comment>> fetchComments(String postId) async {
    try {
      final data = await _supabase
          .from('comments')
          .select('*, profiles(*)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      
      return (data as List).map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch comments');
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
