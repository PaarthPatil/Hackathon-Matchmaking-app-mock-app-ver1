import 'package:flutter_riverpod/flutter_riverpod.dart';

class Achievement {
  final String title;
  final String description;

  const Achievement({required this.title, required this.description});
}

class AchievementNotifier extends StateNotifier<Achievement?> {
  AchievementNotifier() : super(null);

  void trigger(String title, String description) {
    state = Achievement(title: title, description: description);
    Future.delayed(const Duration(seconds: 4), () {
      state = null;
    });
  }

  void clear() {
    state = null;
  }
}

final achievementProvider = StateNotifierProvider<AchievementNotifier, Achievement?>((ref) {
  return AchievementNotifier();
});
