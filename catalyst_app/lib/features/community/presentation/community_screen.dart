import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/post_model.dart';
import 'package:catalyst_app/features/community/presentation/post_card.dart';
import 'package:catalyst_app/features/community/data/community_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import 'package:catalyst_app/shared/skeletons/skeleton_box.dart';
import 'package:catalyst_app/shared/widgets/empty_state_widget.dart';
import 'package:catalyst_app/shared/widgets/loading_overlay.dart';
import 'package:flutter/services.dart';

import 'package:catalyst_app/shared/widgets/animated_pressable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:catalyst_app/features/community/presentation/providers/community_provider.dart';
import 'package:catalyst_app/shared/skeletons/feature_skeletons.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent * 0.8) {
        ref.read(communityProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const CreatePostBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: state.isLoading 
        ? const _CommunitySkeletonList() 
        : RefreshIndicator(
            onRefresh: () => ref.read(communityProvider.notifier).fetchPosts(),
            child: state.posts.isEmpty 
              ? const EmptyStateWidget(
                  icon: Icons.forum_outlined,
                  title: 'No Posts Yet',
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.posts.length + (state.isListLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.posts.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: PostCardSkeleton(),
                      );
                    }
                    return Animate(
                      effects: [FadeEffect(duration: 300.ms), SlideEffect(begin: const Offset(0, 0.1), duration: 300.ms)],
                      delay: (index * 100).ms,
                      child: PostCard(post: state.posts[index]),
                    );
                  },
                ),
          ),
      floatingActionButton: AnimatedPressable(
        onTap: () => _showCreatePost(context),
        child: FloatingActionButton(
          onPressed: null, // Handled by AnimatedPressable
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class CreatePostBottomSheet extends ConsumerStatefulWidget {
  const CreatePostBottomSheet({super.key});

  @override
  ConsumerState<CreatePostBottomSheet> createState() => _CreatePostBottomSheetState();
}

class _CreatePostBottomSheetState extends ConsumerState<CreatePostBottomSheet> {
  final _contentController = TextEditingController();
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_contentController.text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final post = Post(
      id: '', // Server-generated
      userId: user.id,
      content: _contentController.text,
      createdAt: DateTime.now(),
    );

    try {
      setState(() => _isLoading = true);
      await ref.read(communityProvider.notifier).createPost(post);
      HapticFeedback.lightImpact();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Creating Post...',
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What is on your mind?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_image != null) ...[
              Image.file(_image!, height: 100),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedPressable(
                  onTap: _pickImage,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.photo_library),
                  ),
                ),
                AnimatedPressable(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CommunitySkeletonList extends StatelessWidget {
  const _CommunitySkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return const PostCardSkeleton();
      },
    );
  }
}
