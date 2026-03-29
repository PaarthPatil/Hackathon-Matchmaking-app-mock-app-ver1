import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catalyst_app/models/hackathon_model.dart';
import 'package:catalyst_app/features/hackathons/data/hackathon_repository.dart';

import 'package:catalyst_app/shared/skeletons/skeleton_box.dart';
import 'package:catalyst_app/shared/widgets/empty_state_widget.dart';

import 'package:catalyst_app/features/hackathons/presentation/providers/hackathon_provider.dart';
import 'package:catalyst_app/shared/skeletons/feature_skeletons.dart';
import 'package:catalyst_app/shared/widgets/premium_card.dart';

class HackathonScreen extends ConsumerStatefulWidget {
  const HackathonScreen({super.key});

  @override
  ConsumerState<HackathonScreen> createState() => _HackathonScreenState();
}

class _HackathonScreenState extends ConsumerState<HackathonScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent * 0.8) {
        ref.read(hackathonProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hackathonProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hackathons')),
      body: state.isLoading 
        ? const _HackathonsSkeletonList() 
        : RefreshIndicator(
            onRefresh: () => ref.read(hackathonProvider.notifier).fetchHackathons(refresh: true),
            child: state.items.isEmpty 
              ? const EmptyStateWidget(
                  icon: Icons.event_busy,
                  title: 'No Hackathons Found',
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length + (state.isListLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: HackathonCardSkeleton(),
                      );
                    }
                    final h = state.items[index];
                    return _HackathonCard(hackathon: h);
                  },
                ),
          ),
    );
  }
}

class _HackathonCard extends StatelessWidget {
  final Hackathon hackathon;

  const _HackathonCard({required this.hackathon});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => context.push('/hackathons/${hackathon.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'hackathon_title_${hackathon.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  hackathon.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'By ${hackathon.organizer ?? 'Unknown Organizer'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${hackathon.startDate?.day}/${hackathon.startDate?.month}/${hackathon.startDate?.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hackathon.mode ?? 'Online',
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: hackathon.tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HackathonsSkeletonList extends StatelessWidget {
  const _HackathonsSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return const HackathonCardSkeleton();
      },
    );
  }
}
