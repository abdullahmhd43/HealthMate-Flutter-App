import 'package:flutter/material.dart';

/// How well a day's value compares with the user's goal.
enum HealthLevel {
  low('Low', Color(0xFFE53935), Icons.trending_down_rounded),
  moderate('Moderate', Color(0xFFF59E0B), Icons.trending_flat_rounded),
  good('Good', Color(0xFF43A047), Icons.trending_up_rounded),
  excellent('Excellent', Color(0xFF00897B), Icons.emoji_events_rounded);

  const HealthLevel(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  /// Level for [value] against [goal]:
  /// below 40% = Low, 40-74% = Moderate, 75-99% = Good, 100%+ = Excellent.
  /// A missing goal (0 or less) is treated as Low.
  static HealthLevel fromProgress(double progress) {
    if (progress.isNaN || progress < 0.4) return HealthLevel.low;
    if (progress < 0.75) return HealthLevel.moderate;
    if (progress < 1.0) return HealthLevel.good;
    return HealthLevel.excellent;
  }

  static HealthLevel of(num value, int goal) =>
      goal <= 0 ? HealthLevel.low : fromProgress(value / goal);
}
