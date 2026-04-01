import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/post_model.dart';
import 'package:catalyst_app/models/comment_model.dart';
import 'package:catalyst_app/features/community/data/community_repository.dart';

class CommunityState {
  static const Object _noErrorChange = Object();
  final List<Post> posts;
  final bool isLoading;
  final bool isListLoading;
  final bool hasMore;
  final Set<String> votedPostIds;
  final String? error;

  CommunityState({
    required this.posts,
    this.isLoading = false,
    this.isListLoading = false,
    this.hasMore = true,
    this.votedPostIds = const {},
    this.error,
  });

  factory CommunityState.initial() => CommunityState(posts: [], votedPostIds: {});

  CommunityState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isListLoading,
    bool? hasMore,
    Set<String>? votedPostIds,
    Object? error = _noErrorChange,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isListLoading: isListLoading ?? this.isListLoading,
      hasMore: hasMore ?? this.hasMore,
      votedPostIds: votedPostIds ?? this.votedPostIds,
      error: identical(error, _noErrorChange) ? this.error : error as String?,
    );
  }
}

class CommunityNotifier extends StateNotifier<CommunityState> {
  final CommunityRepository _repository;
  static const int _pageSize = 20;

  CommunityNotifier(this._repository) : super(CommunityState.initial()) {
    fetchPosts();
  }

  Future<void> fetchPosts({int limit = _pageSize, int offset = 0, bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, error: null, hasMore: true);
    } else {
      state = state.copyWith(isListLoading: true, error: null);
    }

    try {
      final posts = await _repository.fetchPosts(limit: limit, offset: offset);
      if (refresh || offset == 0) {
        state = state.copyWith(
          posts: posts,
          isLoading: false,
          isListLoading: false,
          hasMore: posts.length >= limit,
          votedPostIds: {},
          error: null,
        );
      } else {
        state = state.copyWith(
          posts: [...state.posts, ...posts],
          isLoading: false,
          isListLoading: false,
          hasMore: posts.length >= limit,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, isListLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isListLoading || !state.hasMore) return;
    await fetchPosts(offset: state.posts.length, limit: _pageSize);
  }

  Future<void> createPost(Post post) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createPost(post);
      
      state = state.copyWith(isLoading: false);
      await fetchPosts(refresh: true); // Fully refresh list (Rule 93)
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // CATALYST ELITE: Optimistic Voting
  Future<void> vote(String postId, bool isUpvote) async {
    if (state.votedPostIds.contains(postId)) return; // RULE 160: Prevent spam

    final originalPosts = [...state.posts];
    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = state.posts[postIndex];
    final optimisticPost = post.copyWith(
      upvotes: isUpvote ? post.upvotes + 1 : post.upvotes,
      downvotes: !isUpvote ? post.downvotes + 1 : post.downvotes,
    );

    // Update state with voted ID
    final updatedPosts = [...state.posts];
    updatedPosts[postIndex] = optimisticPost;

    state = state.copyWith(
      posts: updatedPosts,
      votedPostIds: {...state.votedPostIds, postId},
    );

    try {
      await _repository.vote(postId, isUpvote);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(
        posts: originalPosts,
        votedPostIds: Set<String>.from(state.votedPostIds)..remove(postId),
        error: 'Vote failed: $e',
      );
    }
  }

  Future<List<Comment>> fetchComments(String postId) async {
    return _repository.fetchComments(postId);
  }

  Future<void> createComment(Comment comment) async {
    await _repository.createComment(comment);
  }
}

final communityRepositoryProvider = Provider((ref) => CommunityRepository());

final communityProvider = StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  return CommunityNotifier(ref.read(communityRepositoryProvider));
});
