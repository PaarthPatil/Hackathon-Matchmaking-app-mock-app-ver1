import 'package:flutter/material.dart';
import 'package:catalyst_app/shared/skeletons/skeleton_box.dart';

class HackathonCardSkeleton extends StatelessWidget {
  const HackathonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(height: 24, width: 200),
            const SizedBox(height: 12),
            const SkeletonBox(height: 150, width: double.infinity),
            const SizedBox(height: 12),
            Row(
              children: [
                const SkeletonBox(height: 16, width: 80),
                const Spacer(),
                const SkeletonBox(height: 24, width: 100),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(height: 36, width: 36, borderRadius: 18),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(height: 14, width: 100),
                    const SizedBox(height: 4),
                    const SkeletonBox(height: 10, width: 60),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonBox(height: 14, width: double.infinity),
            const SizedBox(height: 4),
            const SkeletonBox(height: 14, width: 200),
            const SizedBox(height: 12),
            const SkeletonBox(height: 150, width: double.infinity),
          ],
        ),
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SkeletonBox(height: 100, width: 100, borderRadius: 50),
          const SizedBox(height: 16),
          const SkeletonBox(height: 24, width: 150),
          const SizedBox(height: 8),
          const SkeletonBox(height: 16, width: 100),
          const SizedBox(height: 32),
          const SkeletonBox(height: 100, width: double.infinity),
          const SizedBox(height: 16),
          const SkeletonBox(height: 100, width: double.infinity),
        ],
      ),
    );
  }
}

class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SkeletonBox(height: 48, width: 48, borderRadius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 16, width: double.infinity),
                const SizedBox(height: 8),
                const SkeletonBox(height: 12, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
