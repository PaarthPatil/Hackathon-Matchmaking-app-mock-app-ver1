import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:catalyst_app/models/profile_model.dart';
import 'package:catalyst_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:catalyst_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:catalyst_app/features/teams/presentation/providers/team_provider.dart';
import 'package:catalyst_app/shared/skeletons/feature_skeletons.dart';
import 'package:catalyst_app/models/team_model.dart';
import 'package:catalyst_app/core/state/theme_provider.dart';
import 'package:go_router/go_router.dart';

final userTeamsProvider = FutureProvider.family<List<Team>, String>((
  ref,
  userId,
) {
  return ref.read(teamRepositoryProvider).fetchUserTeams(userId);
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
  }

  IconData _getThemeIcon(WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  void _setupControllers(Profile profile) {
    _nameController.text = profile.name ?? '';
    _usernameController.text = profile.username ?? '';
    _bioController.text = profile.bio ?? '';
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      await ref.read(profileProvider.notifier).uploadAvatar(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);

    if (authState.status != AuthStatus.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please sign in to view your profile.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isLoading && state.value == null) {
      return const _ProfileSkeletonWrapper();
    }

    if (state.hasError && state.value == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 68,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                state.error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (authState.status == AuthStatus.authenticated)
                ElevatedButton(
                  onPressed: () => ref
                      .read(profileProvider.notifier)
                      .fetchProfile(authState.userId),
                  child: const Text('Retry'),
                ),
              if (authState.status != AuthStatus.authenticated)
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Sign In'),
                ),
            ],
          ),
        ),
      );
    }

    final profile = state.value;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No profile data available.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Sign in or register to view and edit your profile.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_getThemeIcon(ref)),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveProfile(profile);
              } else {
                _setupControllers(profile);
                setState(() => isEditing = true);
              }
            },
          ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => setState(() => isEditing = false),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(profile),
          const Divider(),
          _buildSkills(profile),
          const Divider(),
          _buildTechStack(profile),
          const Divider(),
          _buildLinks(profile),
          const Divider(),
          _buildStats(profile),
          const Divider(),
          _buildAchievements(profile),
          const Divider(),
          _buildPreferences(profile),
          const Divider(),
          if (profile.roles.contains('admin')) ...[
            _buildAdminDashboardButton(context),
            const Divider(),
          ],
          _buildMyTeams(profile.id),
        ],
      ),
    );
  }

  void _saveProfile(Profile current) {
    final updated = Profile(
      id: current.id,
      name: _nameController.text,
      username: _usernameController.text,
      bio: _bioController.text,
      avatarUrl: current.avatarUrl,
      xp: current.xp,
      level: current.level,
      skills: current.skills,
      techStack: current.techStack,
      githubLink: current.githubLink,
      linkedinLink: current.linkedinLink,
      portfolioLink: current.portfolioLink,
      hackathonsJoined: current.hackathonsJoined,
      wins: current.wins,
      teamsJoined: current.teamsJoined,
      roles: current.roles,
      availability: current.availability,
      lookingForTeam: current.lookingForTeam,
    );
    ref.read(profileProvider.notifier).updateProfile(updated).then((_) {
      setState(() => isEditing = false);
    });
  }

  Widget _buildHeader(Profile profile) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profile.avatarUrl != null
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            if (isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 16),
                    onPressed: _pickAvatar,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isEditing) ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
        ] else ...[
          Text(
            profile.name ?? 'No Name',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Text(
            '@${profile.username ?? 'no_username'}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(profile.bio ?? 'No bio yet', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _buildXpBar(profile),
        ],
      ],
    );
  }

  Widget _buildXpBar(Profile profile) {
    const double xpPerLevel = 100.0;
    final double progress = (profile.xp % xpPerLevel) / xpPerLevel;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level ${profile.level}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              '${(profile.xp % xpPerLevel).toInt()} / ${xpPerLevel.toInt()} XP',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildSkills(Profile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skills', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        profile.skills.isEmpty
            ? const Text(
                'No skills added yet.',
                style: TextStyle(color: Colors.grey),
              )
            : Wrap(
                spacing: 8,
                children: profile.skills
                    .map((s) => Chip(label: Text(s)))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildTechStack(Profile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tech Stack', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        profile.techStack.isEmpty
            ? const Text(
                'No tech stack information yet.',
                style: TextStyle(color: Colors.grey),
              )
            : Wrap(
                spacing: 8,
                children: profile.techStack
                    .map((t) => Chip(label: Text(t)))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildLinks(Profile profile) {
    final hasLinks =
        profile.githubLink.isNotEmpty ||
        profile.linkedinLink.isNotEmpty ||
        profile.portfolioLink.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Links', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (!hasLinks)
          const Text(
            'No links added yet.',
            style: TextStyle(color: Colors.grey),
          )
        else ...[
          if (profile.githubLink.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.link),
              title: Text('GitHub: ${profile.githubLink.join(", ")}'),
            ),
          if (profile.linkedinLink.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.link),
              title: Text('LinkedIn: ${profile.linkedinLink.join(", ")}'),
            ),
          if (profile.portfolioLink.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.link),
              title: Text('Portfolio: ${profile.portfolioLink.join(", ")}'),
            ),
        ],
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildStats(Profile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem('Hackathons', profile.hackathonsJoined.toString()),
        _statItem('Wins', profile.wins.toString()),
        _statItem('Teams', profile.teamsJoined.toString()),
      ],
    );
  }

  Widget _buildAchievements(Profile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Achievements', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            color: Colors.grey[800],
            child: const Icon(Icons.emoji_events),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferences(Profile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferences', style: Theme.of(context).textTheme.headlineSmall),
        SwitchListTile(
          title: const Text('Looking for Team'),
          value: profile.lookingForTeam,
          onChanged: (val) {},
        ),
        ListTile(
          title: const Text('Availability'),
          subtitle: Text(profile.availability),
        ),
      ],
    );
  }

  Widget _buildMyTeams(String userId) {
    final teamsAsync = ref.watch(userTeamsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Teams', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        teamsAsync.when(
          data: (teams) {
            if (teams.isEmpty) {
              return const Text('Nothing here yet. Come back later.');
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.group)),
                  title: Text(team.name ?? 'Unnamed Team'),
                  subtitle: Text(team.description ?? ''),
                  trailing: const Icon(Icons.chat_bubble_outline),
                  onTap: () => context.push('/chat/${team.id}'),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child:
                NotificationSkeleton(), // Reusing notification skeleton for list item shimmer
          ),
          error: (e, st) => Text('Error loading teams: $e'),
        ),
      ],
    );
  }

  Widget _buildAdminDashboardButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.admin_panel_settings, color: Colors.amber),
      title: const Text(
        'Admin Dashboard',
        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('Review hackathon requests and manage events'),
      trailing: const Icon(Icons.chevron_right, color: Colors.amber),
      onTap: () => context.push('/admin'),
    );
  }
}

class _ProfileSkeletonWrapper extends StatelessWidget {
  const _ProfileSkeletonWrapper();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ProfileSkeleton(), // From feature_skeletons.dart
    );
  }
}
