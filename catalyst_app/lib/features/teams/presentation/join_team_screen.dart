import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/team_model.dart';
import 'package:catalyst_app/features/teams/presentation/providers/team_provider.dart';
import 'package:catalyst_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:catalyst_app/shared/widgets/empty_state_widget.dart';
import 'package:catalyst_app/shared/widgets/loading_overlay.dart';
import 'package:catalyst_app/shared/skeletons/feature_skeletons.dart';
import 'package:catalyst_app/shared/widgets/animated_pressable.dart';
import 'package:flutter/services.dart';
import 'package:catalyst_app/features/teams/presentation/skill_radar_chart.dart';

class JoinTeamScreen extends ConsumerStatefulWidget {
  final String hackathonId;

  const JoinTeamScreen({super.key, required this.hackathonId});

  @override
  ConsumerState<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends ConsumerState<JoinTeamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(teamProvider.notifier).fetchRecommendations(user.id, widget.hackathonId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamProvider);

    return LoadingOverlay(
      isLoading: state.isLoading && state.recommendedTeams.isNotEmpty,
      message: 'Processing...',
      child: Scaffold(
        appBar: AppBar(title: const Text('Recommended Teams')),
        body: state.isLoading && state.recommendedTeams.isEmpty
          ? ListView.builder(
              itemCount: 5,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => const HackathonCardSkeleton(),
            )
          : state.error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.error}', style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final user = ref.read(authProvider).user;
                        if (user != null) {
                          ref.read(teamProvider.notifier).fetchRecommendations(user.id, widget.hackathonId);
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : state.recommendedTeams.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: 'No Teams Found',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.recommendedTeams.length,
                  itemBuilder: (context, index) {
                    final team = state.recommendedTeams[index];
                    return _MatchCard(team: team);
                  },
                ),
      ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final Team team;

  const _MatchCard({required this.team});

  Future<void> _joinTeam(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(teamProvider.notifier).joinTeam(team);
      HapticFeedback.lightImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request sent!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compatibility = (team.matchingScore ?? 0) * 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(team.name ?? 'Untitled Team',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${compatibility.toInt()}% Match',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${team.membersCount} members • ${team.maxMembers ?? 'N/A'} max',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Text(team.matchingExplanation ?? 'Based on your skills complementarity.',
                style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            Center(
              child: SkillRadarChart(
                skills: {
                  for (var s in team.requiredSkills.take(5)) s: 0.5 + (0.1 * team.requiredSkills.indexOf(s)),
                  if (team.requiredSkills.isEmpty) 'General': 0.8,
                },
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: team.requiredSkills.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 10)))).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AnimatedPressable(
                onTap: () => _joinTeam(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Request to Join',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
