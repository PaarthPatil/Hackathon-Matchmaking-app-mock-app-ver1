import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catalyst_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:catalyst_app/features/auth/presentation/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _userEmail = TextEditingController();
  final _userPassword = TextEditingController(text: 'mockpass123');
  final _userUsername = TextEditingController();
  final _userName = TextEditingController();
  final _userBio = TextEditingController();
  String _userRole = 'user';

  final _hackTitle = TextEditingController();
  final _hackDescription = TextEditingController();
  final _hackOrganizer = TextEditingController(text: 'Catalyst');
  final _hackLocation = TextEditingController(text: 'Global');
  final _hackPrize = TextEditingController(text: '\$5,000');
  final _hackTags = TextEditingController(text: 'ai,flutter');
  final _hackMaxTeamSize = TextEditingController(text: '5');
  String _hackMode = 'online';

  final _teamName = TextEditingController();
  final _teamDescription = TextEditingController();
  final _teamSkills = TextEditingController(text: 'flutter,backend');
  final _teamMaxMembers = TextEditingController(text: '4');
  String? _selectedHackathonId;
  String? _selectedCreatorUserId;

  final _eventMessage = TextEditingController(text: 'Admin-triggered test scenario.');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated) {
        ref.read(adminProvider.notifier).loadDashboard();
      }
    });
  }

  @override
  void dispose() {
    _userEmail.dispose();
    _userPassword.dispose();
    _userUsername.dispose();
    _userName.dispose();
    _userBio.dispose();
    _hackTitle.dispose();
    _hackDescription.dispose();
    _hackOrganizer.dispose();
    _hackLocation.dispose();
    _hackPrize.dispose();
    _hackTags.dispose();
    _hackMaxTeamSize.dispose();
    _teamName.dispose();
    _teamDescription.dispose();
    _teamSkills.dispose();
    _teamMaxMembers.dispose();
    _eventMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Control Center')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please sign in to access admin mode.'),
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

    ref.listen<AdminState>(adminProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.redAccent),
        );
      }
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green),
        );
      }
    });

    final state = ref.watch(adminProvider);
    final notifier = ref.read(adminProvider.notifier);

    final hackathonOptions = state.hackathons;
    final userOptions = state.users;

    if (_selectedHackathonId != null &&
        !hackathonOptions.any((h) => h['id']?.toString() == _selectedHackathonId)) {
      _selectedHackathonId = null;
    }
    if (_selectedCreatorUserId != null &&
        !userOptions.any((u) => u['id']?.toString() == _selectedCreatorUserId)) {
      _selectedCreatorUserId = null;
    }
    _selectedHackathonId ??=
        hackathonOptions.isNotEmpty ? hackathonOptions.first['id']?.toString() : null;
    _selectedCreatorUserId ??=
        userOptions.isNotEmpty ? userOptions.first['id']?.toString() : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading ? null : () => notifier.loadDashboard(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => notifier.loadDashboard(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _sectionTitle('Quick Admin Actions'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: state.isActionLoading
                                ? null
                                : () => notifier.seedMockData(
                                      userCount: 10,
                                      hackathonCount: 4,
                                      teamsPerHackathon: 3,
                                      includeSocialFeed: true,
                                    ),
                            icon: const Icon(Icons.dataset),
                            label: const Text('Seed Mock Data'),
                          ),
                          ElevatedButton.icon(
                            onPressed: state.isActionLoading
                                ? null
                                : () => notifier.triggerTestEvents(message: _eventMessage.text.trim()),
                            icon: const Icon(Icons.bolt),
                            label: const Text('Trigger Test Events'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _eventMessage,
                        decoration: const InputDecoration(
                          labelText: 'Test event message',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Create User'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: _userEmail,
                                decoration: const InputDecoration(labelText: 'Email'),
                              ),
                              TextField(
                                controller: _userPassword,
                                decoration: const InputDecoration(labelText: 'Password'),
                              ),
                              TextField(
                                controller: _userUsername,
                                decoration: const InputDecoration(labelText: 'Username'),
                              ),
                              TextField(
                                controller: _userName,
                                decoration: const InputDecoration(labelText: 'Name'),
                              ),
                              TextField(
                                controller: _userBio,
                                decoration: const InputDecoration(labelText: 'Bio'),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _userRole,
                                items: const [
                                  DropdownMenuItem(value: 'user', child: Text('User')),
                                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                ],
                                onChanged: (value) {
                                  if (value != null) setState(() => _userRole = value);
                                },
                                decoration: const InputDecoration(labelText: 'Role'),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: state.isActionLoading
                                      ? null
                                      : () => notifier.createUser({
                                            'email': _userEmail.text.trim(),
                                            'password': _userPassword.text.trim(),
                                            'username': _userUsername.text.trim(),
                                            'name': _userName.text.trim(),
                                            'bio': _userBio.text.trim(),
                                            'role': _userRole,
                                            'skills': ['Flutter'],
                                            'tech_stack': ['Supabase', 'FastAPI'],
                                            'experience_level': 'intermediate',
                                            'looking_for_team': true,
                                          }),
                                  child: const Text('Create User'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Create Hackathon'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: _hackTitle,
                                decoration: const InputDecoration(labelText: 'Title'),
                              ),
                              TextField(
                                controller: _hackDescription,
                                decoration: const InputDecoration(labelText: 'Description'),
                              ),
                              TextField(
                                controller: _hackOrganizer,
                                decoration: const InputDecoration(labelText: 'Organizer'),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _hackMode,
                                items: const [
                                  DropdownMenuItem(value: 'online', child: Text('Online')),
                                  DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                                  DropdownMenuItem(value: 'offline', child: Text('Offline')),
                                ],
                                onChanged: (value) {
                                  if (value != null) setState(() => _hackMode = value);
                                },
                                decoration: const InputDecoration(labelText: 'Mode'),
                              ),
                              TextField(
                                controller: _hackLocation,
                                decoration: const InputDecoration(labelText: 'Location'),
                              ),
                              TextField(
                                controller: _hackPrize,
                                decoration: const InputDecoration(labelText: 'Prize pool'),
                              ),
                              TextField(
                                controller: _hackMaxTeamSize,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Max team size'),
                              ),
                              TextField(
                                controller: _hackTags,
                                decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: state.isActionLoading
                                      ? null
                                      : () {
                                          final start = DateTime.now().add(const Duration(days: 7));
                                          final end = start.add(const Duration(days: 2));
                                          final tags = _hackTags.text
                                              .split(',')
                                              .map((item) => item.trim())
                                              .where((item) => item.isNotEmpty)
                                              .toList();
                                          notifier.createHackathon({
                                            'title': _hackTitle.text.trim(),
                                            'description': _hackDescription.text.trim(),
                                            'organizer': _hackOrganizer.text.trim(),
                                            'start_date': start.toIso8601String(),
                                            'end_date': end.toIso8601String(),
                                            'mode': _hackMode,
                                            'location': _hackLocation.text.trim(),
                                            'prize_pool': _hackPrize.text.trim(),
                                            'max_team_size':
                                                int.tryParse(_hackMaxTeamSize.text.trim()) ?? 4,
                                            'tags': tags,
                                          });
                                        },
                                  child: const Text('Create Hackathon'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Create Team'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedHackathonId,
                                items: hackathonOptions
                                    .where((h) => h['id'] != null)
                                    .map(
                                      (h) => DropdownMenuItem<String>(
                                        value: h['id'].toString(),
                                        child: Text(h['title']?.toString() ?? 'Untitled hackathon'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setState(() => _selectedHackathonId = value),
                                decoration: const InputDecoration(labelText: 'Hackathon'),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedCreatorUserId,
                                items: userOptions
                                    .where((u) => u['id'] != null)
                                    .map(
                                      (u) => DropdownMenuItem<String>(
                                        value: u['id'].toString(),
                                        child: Text(
                                          '${u['username'] ?? 'user'} (${u['id']?.toString().substring(0, 8) ?? '-'})',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setState(() => _selectedCreatorUserId = value),
                                decoration: const InputDecoration(labelText: 'Creator user'),
                              ),
                              TextField(
                                controller: _teamName,
                                decoration: const InputDecoration(labelText: 'Team name'),
                              ),
                              TextField(
                                controller: _teamDescription,
                                decoration: const InputDecoration(labelText: 'Description'),
                              ),
                              TextField(
                                controller: _teamSkills,
                                decoration:
                                    const InputDecoration(labelText: 'Required skills (comma separated)'),
                              ),
                              TextField(
                                controller: _teamMaxMembers,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Max members'),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: state.isActionLoading ||
                                          _selectedHackathonId == null ||
                                          _selectedCreatorUserId == null
                                      ? null
                                      : () {
                                          final skills = _teamSkills.text
                                              .split(',')
                                              .map((item) => item.trim())
                                              .where((item) => item.isNotEmpty)
                                              .toList();
                                          notifier.createTeam({
                                            'hackathon_id': _selectedHackathonId,
                                            'creator_user_id': _selectedCreatorUserId,
                                            'name': _teamName.text.trim(),
                                            'description': _teamDescription.text.trim(),
                                            'required_skills': skills,
                                            'max_members': int.tryParse(_teamMaxMembers.text.trim()) ?? 4,
                                            'commitment_level': 'medium',
                                            'availability': 'weeknights',
                                          });
                                        },
                                  child: const Text('Create Team'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Pending Hackathon Requests'),
                      state.requests.isEmpty
                          ? const Text('No pending requests.')
                          : Column(
                              children: state.requests
                                  .map((request) => _requestCard(context, notifier, request))
                                  .toList(),
                            ),
                      const SizedBox(height: 24),
                      _sectionTitle('Data Snapshot'),
                      Text('Users: ${state.users.length}'),
                      Text('Hackathons: ${state.hackathons.length}'),
                      Text('Teams: ${state.teams.length}'),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
                if (state.isActionLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _requestCard(
    BuildContext context,
    AdminNotifier notifier,
    Map<String, dynamic> request,
  ) {
    final requestId = request['id']?.toString() ?? '';
    final title = request['title']?.toString() ?? 'Untitled';
    final description = request['description']?.toString() ?? '';
    final organizer = request['organizer']?.toString() ?? 'Unknown organizer';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 8),
            Text('Organizer: $organizer'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: requestId.isEmpty
                      ? null
                      : () {
                          _showRejectDialog(context, notifier, requestId);
                        },
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('Reject'),
                ),
                ElevatedButton(
                  onPressed: requestId.isEmpty
                      ? null
                      : () {
                          notifier.approveRequest(requestId, {
                            'title': request['title'],
                            'description': request['description'],
                            'organizer': request['organizer'],
                            'start_date': request['expected_start_date'],
                            'end_date': request['expected_end_date'],
                            'mode': request['mode'] ?? 'online',
                            'location': request['location'] ?? 'Global',
                            'prize_pool': request['prize_pool'] ?? '\$2,000',
                            'max_team_size': request['max_team_size'] ?? 4,
                            'tags': request['tags'] ?? const [],
                          });
                        },
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    AdminNotifier notifier,
    String requestId,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Request'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                notifier.rejectRequest(requestId, reasonController.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }
}
