import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catalyst_app/models/hackathon_model.dart';
import 'package:catalyst_app/features/hackathons/presentation/providers/hackathon_provider.dart';
import 'package:catalyst_app/features/teams/presentation/providers/team_provider.dart';
import 'package:catalyst_app/shared/widgets/animated_pressable.dart';
import 'package:intl/intl.dart';

import 'package:catalyst_app/shared/skeletons/skeleton_box.dart';

class HackathonDetailScreen extends ConsumerWidget {
  final String hackathonId;

  const HackathonDetailScreen({super.key, required this.hackathonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hackathonAsync = ref.watch(hackathonByIdProvider(hackathonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Hackathon Details')),
      body: hackathonAsync.when(
        data: (h) => _buildDetail(context, h, ref),
        loading: () => const _DetailSkeleton(),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Hackathon h, WidgetRef ref) {
    final userTeamAsync = ref.watch(userTeamProvider(h.id));
    final isEnded = h.endDate != null && h.endDate!.isBefore(DateTime.now());

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Hero(
                tag: 'hackathon_title_${h.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(h.title, style: Theme.of(context).textTheme.headlineMedium),
                ),
              ),
              const SizedBox(height: 8),
              Text('By ${h.organizer}', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 24),
              _section('Description', h.description ?? 'No description provided.'),
              _section('Prize Pool', h.prizePool ?? 'No prize information.'),
              _section('Location', h.location ?? 'Online'),
              _section('Max Team Size', '${h.maxTeamSize ?? 'N/A'} members'),
              _section('Timeline', '${h.startDate != null ? DateFormat('MMM dd, yyyy').format(h.startDate!) : 'N/A'} - ${h.endDate != null ? DateFormat('MMM dd, yyyy').format(h.endDate!) : 'N/A'}'),
            ],
          ),
        ),
        userTeamAsync.when(
          data: (teamId) => _buildBottomBar(context, h, teamId, isEnded),
          loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => _buildBottomBar(context, h, null, isEnded),
        ),
      ],
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Hackathon h, String? userTeamId, bool isEnded) {
    final String? statusLabel = isEnded 
        ? 'Hackathon ended' 
        : (userTeamId != null ? 'Already in a team' : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                statusLabel,
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: AnimatedPressable(
              onTap: (isEnded || userTeamId != null) 
                  ? null 
                  : () => context.push('/hackathons/${h.id}/create-team'),
              child: Opacity(
                opacity: (isEnded || userTeamId != null) ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Create Team',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AnimatedPressable(
              onTap: (isEnded || userTeamId != null) 
                  ? null 
                  : () => context.push('/hackathons/${h.id}/join-team'),
              child: Opacity(
                opacity: (isEnded || userTeamId != null) ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Join Team',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (userTeamId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AnimatedPressable(
                onTap: () => context.push('/chat/$userTeamId'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Go to My Team Chat',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 32, width: 250),
          const SizedBox(height: 12),
          const SkeletonBox(height: 16, width: 150),
          const SizedBox(height: 32),
          const SkeletonBox(height: 20, width: 100),
          const SizedBox(height: 12),
          const SkeletonBox(height: 100, width: double.infinity),
          const SizedBox(height: 32),
          const SkeletonBox(height: 20, width: 100),
          const SizedBox(height: 12),
          const SkeletonBox(height: 60, width: double.infinity),
        ],
      ),
    );
  }
}
