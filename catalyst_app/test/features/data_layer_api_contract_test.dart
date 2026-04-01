import 'package:flutter_test/flutter_test.dart';

import 'package:catalyst_app/core/services/api_service.dart';
import 'package:catalyst_app/features/notifications/data/notification_repository.dart';
import 'package:catalyst_app/features/profile/data/profile_repository.dart';
import 'package:catalyst_app/features/teams/data/team_repository.dart';
import 'package:catalyst_app/models/notification_model.dart';
import 'package:catalyst_app/models/profile_model.dart';
import 'package:catalyst_app/models/team_model.dart';


class FakeApiService extends ApiService {
  final List<Map<String, dynamic>> postCalls = [];
  dynamic nextPostResponse = <String, dynamic>{};
  Object? postError;

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    postCalls.add({'path': path, 'body': body});
    if (postError != null) {
      throw postError!;
    }
    return nextPostResponse;
  }
}


void main() {
  group('TeamRepository API contract', () {
    test('createTeam sends normalized payload to /teams/create', () async {
      final fakeApi = FakeApiService();
      final repository = TeamRepository(api: fakeApi);
      final team = Team(
        id: 'temp-id',
        hackathonId: 'hack-1',
        creatorId: 'user-1',
        name: ' Team Alpha ',
        description: ' Build fast ',
        requiredSkills: const ['Flutter', 'FastAPI'],
        maxMembers: 4,
      );

      await repository.createTeam(team);

      expect(fakeApi.postCalls.length, 1);
      expect(fakeApi.postCalls.first['path'], '/teams/create');
      expect(
        fakeApi.postCalls.first['body'],
        {
          'hackathon_id': 'hack-1',
          'name': 'Team Alpha',
          'description': 'Build fast',
          'required_skills': const ['Flutter', 'FastAPI'],
          'max_members': 4,
        },
      );
    });

    test('joinTeam posts to /teams/join with team_id', () async {
      final fakeApi = FakeApiService();
      final repository = TeamRepository(api: fakeApi);

      await repository.joinTeam('team-42');

      expect(fakeApi.postCalls.length, 1);
      expect(fakeApi.postCalls.first['path'], '/teams/join');
      expect(fakeApi.postCalls.first['body'], {'team_id': 'team-42'});
    });

    test('fetchRecommendedTeams maps score from 0-100 to 0-1', () async {
      final fakeApi = FakeApiService();
      fakeApi.nextPostResponse = [
        {
          'team_id': 'team-1',
          'team_name': 'Winners',
          'members_count': 2,
          'compatibility_score': 85.5,
          'explanation': 'Great match',
        }
      ];
      final repository = TeamRepository(api: fakeApi);

      final items = await repository.fetchRecommendedTeams('hack-10');

      expect(items.length, 1);
      expect(items.first.id, 'team-1');
      expect(items.first.hackathonId, 'hack-10');
      expect(items.first.matchingScore, closeTo(0.855, 0.0001));
      expect(items.first.matchingExplanation, 'Great match');
    });
  });

  group('NotificationRepository API contract', () {
    test('markAllAsRead posts empty body to /notifications/mark_all_read', () async {
      final fakeApi = FakeApiService();
      final repository = NotificationRepository(api: fakeApi);

      await repository.markAllAsRead();

      expect(fakeApi.postCalls.length, 1);
      expect(fakeApi.postCalls.first['path'], '/notifications/mark_all_read');
      expect(fakeApi.postCalls.first['body'], <String, dynamic>{});
    });

    test('createNotification posts expected shape to /notifications/create', () async {
      final fakeApi = FakeApiService();
      final repository = NotificationRepository(api: fakeApi);
      final notification = NotificationModel(
        id: 'n1',
        userId: 'u1',
        type: 'post_liked',
        message: 'Someone liked your post.',
        read: false,
        referenceId: 'post-1',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      await repository.createNotification(notification);

      expect(fakeApi.postCalls.length, 1);
      expect(fakeApi.postCalls.first['path'], '/notifications/create');
      expect(
        fakeApi.postCalls.first['body'],
        {
          'type': 'post_liked',
          'message': 'Someone liked your post.',
          'reference_id': 'post-1',
        },
      );
    });
  });

  group('ProfileRepository API contract', () {
    test('updateProfile posts profile payload to /profile/update', () async {
      final fakeApi = FakeApiService();
      final repository = ProfileRepository(api: fakeApi);
      final profile = Profile(
        id: 'u-1',
        name: 'Alex',
        username: 'alex',
        bio: 'Builder',
        skills: const ['Flutter'],
      );

      await repository.updateProfile(profile);

      expect(fakeApi.postCalls.length, 1);
      expect(fakeApi.postCalls.first['path'], '/profile/update');
      final body = fakeApi.postCalls.first['body'] as Map<String, dynamic>;
      expect(body['id'], 'u-1');
      expect(body['name'], 'Alex');
      expect(body['username'], 'alex');
      expect(body['bio'], 'Builder');
    });

    test('rewardXp posts xp payload to /profile/reward', () async {
      final fakeApi = FakeApiService();
      final repository = ProfileRepository(api: fakeApi);

      await repository.rewardXp('user-99', 20);

      expect(fakeApi.postCalls.length, 1);
      expect(fakeApi.postCalls.first['path'], '/profile/reward');
      expect(
        fakeApi.postCalls.first['body'],
        {'user_id': 'user-99', 'xp': 20},
      );
    });
  });
}
