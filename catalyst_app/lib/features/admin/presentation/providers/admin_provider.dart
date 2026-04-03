import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/features/admin/data/admin_repository.dart';

class AdminState {
  final List<Map<String, dynamic>> requests;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> hackathons;
  final List<Map<String, dynamic>> teams;
  final bool isLoading;
  final bool isActionLoading;
  final String? error;
  final String? successMessage;

  const AdminState({
    this.requests = const [],
    this.users = const [],
    this.hackathons = const [],
    this.teams = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.error,
    this.successMessage,
  });

  AdminState copyWith({
    List<Map<String, dynamic>>? requests,
    List<Map<String, dynamic>>? users,
    List<Map<String, dynamic>>? hackathons,
    List<Map<String, dynamic>>? teams,
    bool? isLoading,
    bool? isActionLoading,
    Object? error = _sentinel,
    Object? successMessage = _sentinel,
  }) {
    return AdminState(
      requests: requests ?? this.requests,
      users: users ?? this.users,
      hackathons: hackathons ?? this.hackathons,
      teams: teams ?? this.teams,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      successMessage: identical(successMessage, _sentinel)
          ? this.successMessage
          : successMessage as String?,
    );
  }
}

const Object _sentinel = Object();

class AdminNotifier extends StateNotifier<AdminState> {
  final AdminRepository _repository;

  AdminNotifier(this._repository) : super(const AdminState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final results = await Future.wait([
        _repository.fetchHackathonRequests(status: 'pending'),
        _repository.fetchUsers(limit: 100, offset: 0),
        _repository.fetchCatalog(),
      ]);

      final requests = results[0] as List<Map<String, dynamic>>;
      final users = results[1] as List<Map<String, dynamic>>;
      final catalog = results[2] as Map<String, dynamic>;

      state = state.copyWith(
        isLoading: false,
        requests: requests,
        users: users,
        hackathons: List<Map<String, dynamic>>.from(catalog['hackathons'] ?? const []),
        teams: List<Map<String, dynamic>>.from(catalog['teams'] ?? const []),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshCatalog() async {
    try {
      final catalog = await _repository.fetchCatalog();
      state = state.copyWith(
        hackathons: List<Map<String, dynamic>>.from(catalog['hackathons'] ?? const []),
        teams: List<Map<String, dynamic>>.from(catalog['teams'] ?? const []),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> approveRequest(String requestId, Map<String, dynamic> payload) async {
    state = state.copyWith(isActionLoading: true, error: null, successMessage: null);
    try {
      await _repository.approveRequest(requestId, payload);
      await loadDashboard();
      state = state.copyWith(
        isActionLoading: false,
        successMessage: 'Hackathon request approved successfully.',
      );
    } catch (e) {
      state = state.copyWith(isActionLoading: false, error: e.toString());
    }
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    state = state.copyWith(isActionLoading: true, error: null, successMessage: null);
    try {
      await _repository.rejectRequest(requestId, reason);
      await loadDashboard();
      state = state.copyWith(
        isActionLoading: false,
        successMessage: 'Hackathon request rejected.',
      );
    } catch (e) {
      state = state.copyWith(isActionLoading: false, error: e.toString());
    }
  }

  Future<void> createUser(Map<String, dynamic> payload) async {
    state = state.copyWith(isActionLoading: true, error: null, successMessage: null);
    try {
      final result = await _repository.createUser(payload);
      await loadDashboard();
      state = state.copyWith(
        isActionLoading: false,
        successMessage: 'User created: ${result['user_id']}',
      );
    } catch (e) {
      state = state.copyWith(isActionLoading: false, error: e.toString());
    }
  }

  Future<void> createHackathon(Map<String, dynamic> payload) async {
    state = state.copyWith(isActionLoading: true, error: null, successMessage: null);
    try {
      final result = await _repository.createHackathon(payload);
      await loadDashboard();
      state = state.copyWith(
        isActionLoading: false,
        successMessage: 'Hackathon created: ${result['hackathon_id']}',
      );
    } catch (e) {
      state = state.copyWith(isActionLoading: false, error: e.toString());
    }
  }

  Future<void> createTeam(Map<String, dynamic> payload) async {
    state = state.copyWith(isActionLoading: true, error: null, successMessage: null);
    try {
      final result = await _repository.createTeam(payload);
      await loadDashboard();
      state = state.copyWith(
        isActionLoading: false,
        successMessage: 'Team created: ${result['team_id']}',
      );
    } catch (e) {
      state = state.copyWith(isActionLoading: false, error: e.toString());
    }
  }

  Future<void> seedMockData({
    int userCount = 8,
    int hackathonCount = 3,
    int teamsPerHackathon = 2,
    bool includeSocialFeed = true,
  }) async {
    state = state.copyWith(isActionLoading: true, error: null, successMessage: null);
    try {
      final result = await _repository.seedMockData(
        userCount: userCount,
        hackathonCount: hackathonCount,
        teamsPerHackathon: teamsPerHackathon,
        includeSocialFeed: includeSocialFeed,
      );
      await loadDashboard();
      state = state.copyWith(
        isActionLoading: false,
        successMessage:
            'Seed done: users ${result['created_users']}, hackathons ${result['created_hackathons']}, teams ${result['created_teams']}.',
      );
    } catch (e) {
      state = state.copyWith(isActionLoading: false, error: e.toString());
    }
  }

  Future<void> triggerTestEvents({
    String? targetUserId,
    String? targetTeamId,
    String? targetPostId,
    String? message,
  }) async {
    state = state.copyWith(isActionLoading: true, error: null, successMessage: null);
    try {
      final result = await _repository.triggerTestEvents(
        targetUserId: targetUserId,
        targetTeamId: targetTeamId,
        targetPostId: targetPostId,
        message: message,
      );
      final summary = Map<String, dynamic>.from(result['summary'] ?? const {});
      state = state.copyWith(
        isActionLoading: false,
        successMessage:
            'Events: ${summary['success'] ?? 0} success, ${summary['failed'] ?? 0} failed, ${summary['skipped'] ?? 0} skipped.',
      );
    } catch (e) {
      state = state.copyWith(isActionLoading: false, error: e.toString());
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final adminRepositoryProvider = Provider((ref) => AdminRepository());

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref.watch(adminRepositoryProvider));
});
