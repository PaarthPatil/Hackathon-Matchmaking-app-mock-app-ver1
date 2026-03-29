import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catalyst_app/models/post_model.dart';
import 'package:catalyst_app/features/community/presentation/providers/community_provider.dart';
import 'package:catalyst_app/shared/widgets/premium_card.dart';
import 'package:catalyst_app/shared/widgets/animated_pressable.dart';
import 'package:lottie/lottie.dart';

class PostCard extends ConsumerWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        PremiumCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => context.push('/community/comments/${post.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: post.author?.avatarUrl != null ? NetworkImage(post.author!.avatarUrl!) : null,
                      child: post.author?.avatarUrl == null ? const Icon(Icons.person, size: 18) : null,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.author?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('@${post.author?.username ?? 'no_user'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const Spacer(),
                    Text('${post.createdAt.day}/${post.createdAt.month}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(post.content),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  Image.network(post.imageUrl!, fit: BoxFit.cover),
                ],
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  children: [
                    AnimatedPressable(
                      onTap: () => ref.read(communityProvider.notifier).vote(post.id, true),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.arrow_upward),
                      ),
                    ),
                    Text('${post.upvotes - post.downvotes}'),
                    AnimatedPressable(
                      onTap: () => ref.read(communityProvider.notifier).vote(post.id, false),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.arrow_downward),
                      ),
                    ),
                    const Spacer(),
                    AnimatedPressable(
                      onTap: () => context.push('/community/comments/${post.id}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: const [
                            Icon(Icons.chat_bubble_outline, size: 20),
                            SizedBox(width: 4),
                            Text('Comment'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Confetti animation when high upvotes
                if (post.upvotes > 100)
                  Positioned.fill(
                    child: Lottie.asset('assets/confetti.json', repeat: false),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
