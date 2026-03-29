import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/post_model.dart';
import 'package:catalyst_app/models/comment_model.dart';
import 'package:catalyst_app/features/community/data/community_repository.dart';
import 'package:catalyst_app/models/profile_model.dart';
import 'package:catalyst_app/features/profile/presentation/providers/profile_provider.dart';

class CommunityState {
  final List<Post> posts;
  final bool isLoading;
  final bool isListLoading;
  final Set<String> votedPostIds;
  final String? error;

  CommunityState({
    required this.posts,
    this.isLoading = false,
    this.isListLoading = false,
    this.votedPostIds = const {},
    this.error,
  });

  factory CommunityState.initial() => CommunityState(posts: [], votedPostIds: {});

  CommunityState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isListLoading,
    Set<String>? votedPostIds,
    String? error,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isListLoading: isListLoading ?? this.isListLoading,
      votedPostIds: votedPostIds ?? this.votedPostIds,
      error: error ?? this.error,
    );
  }
}

class CommunityNotifier extends StateNotifier<CommunityState> {
  final CommunityRepository _repository;
  final Ref _ref;

  CommunityNotifier(this._repository, this._ref) : super(CommunityState.initial()) {
    fetchPosts();
  }

  Future<void> fetchPosts({int limit = 20, int offset = 0, bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isListLoading: true, error: null);
    }

    try {
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 600));
      final posts = List.generate(100, (index) {
        final profileId = 'user-${index + 1}';
        return Post(
          id: 'post-$index',
          userId: profileId,
          content: 'Iteration $index: Building the future of Catalyst with intelligent hackathon matching. Anyone need a co-founder? #hackathon #catalyst',
          upvotes: 42 + index * 5,
          downvotes: index % 3,
          createdAt: DateTime.now().subtract(Duration(hours: index)),
          author: Profile(
             id: profileId,
             name: 'Elite Hacker $index',
             username: 'hacker_$index',
             avatarUrl: 'https://i.pravatar.cc/150?u=$profileId',
             xp: index * 100 + 50,
             level: (index % 10) + 1,
          ),
        );
      });
      if (refresh || state.posts.isEmpty) {
        state = state.copyWith(posts: posts, isLoading: false);
      } else {
        // Just return to avoid eternal lists
        state = state.copyWith(isListLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, isListLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isListLoading) return;
    await fetchPosts(offset: state.posts.length);
  }

  Future<void> createPost(Post post) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 600));
      
      // CATALYST ELITE: Gamification Loop (Rule 74)
      await _ref.read(profileProvider.notifier).rewardXp(10);
      
      state = state.copyWith(isLoading: false);
      fetchPosts(refresh: true); // Fully refresh list (Rule 93)
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
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 100));

      
      // CATALYST ELITE: Gamification (Rule 75)
      // Small XP reward for active voting
      await _ref.read(profileProvider.notifier).rewardXp(2);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(posts: originalPosts, error: 'Vote failed: $e');
    }
  }

  Future<List<Comment>> fetchComments(String postId) async {
    // PROTOTYPE MOCK
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Comment(
        id: 'c1',
        postId: postId,
        userId: 'user-2',
        content: 'I completely agree! Amazing.',
        createdAt: DateTime.now(),
      )
    ];
  }

  Future<void> createComment(Comment comment) async {
    // PROTOTYPE MOCK
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

final communityRepositoryProvider = Provider((ref) => CommunityRepository());

final communityProvider = StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  return CommunityNotifier(ref.read(communityRepositoryProvider), ref);
});
