import 'package:flutter/material.dart';

/// One badge. It is unlocked when [current] reaches [target].
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.current,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int current;
  final int target;

  bool get unlocked => current >= target;

  /// 0.0 to 1.0.
  double get progress =>
      target <= 0 ? 1.0 : (current / target).clamp(0.0, 1.0).toDouble();

  /// Progress shown to the user, never above the target.
  int get shownCurrent => current > target ? target : current;
}

/// All badges plus the streak numbers shown next to them.
class AchievementSummary {
  const AchievementSummary({
    required this.badges,
    required this.currentStreak,
    required this.bestStreak,
  });

  final List<Achievement> badges;
  final int currentStreak;
  final int bestStreak;

  int get unlockedCount => badges.where((b) => b.unlocked).length;
  int get total => badges.length;
}
