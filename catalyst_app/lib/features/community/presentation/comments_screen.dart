import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/comment_model.dart';
import 'package:catalyst_app/features/community/presentation/providers/community_provider.dart';
import 'package:catalyst_app/shared/skeletons/feature_skeletons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final commentsProvider = FutureProvider.family<List<Comment>, String>((ref, postId) async {
  return ref.read(communityRepositoryProvider).fetchComments(postId);
});

class CommentsScreen extends ConsumerStatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _commentController = TextEditingController();

  Future<void> _submit() async {
    if (_commentController.text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final comment = Comment(
      id: '', // Server-generated
      postId: widget.postId,
      userId: user.id,
      content: _commentController.text,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(communityProvider.notifier).createComment(comment);
      if (mounted) {
        _commentController.clear();
        ref.invalidate(commentsProvider(widget.postId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(child: Text('Nothing here yet. Come back later.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundImage: c.author?.avatarUrl != null ? NetworkImage(c.author!.avatarUrl!) : null,
                        child: c.author?.avatarUrl == null ? const Icon(Icons.person, size: 14) : null,
                      ),
                      title: Text(c.author?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(c.content),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                itemCount: 5,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) => const NotificationSkeleton(),
              ),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _submit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
