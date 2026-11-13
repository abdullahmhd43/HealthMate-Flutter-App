import 'package:flutter/material.dart';

/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'HealthMate';
  static const String tagline = 'Your Daily Health Companion';
  static const String version = '1.0.0';
  static const String courseInfo = 'CI6330 Mobile Application Development - Coursework 1';

  // Database
  static const String databaseName = 'healthmate.db';
  static const int databaseVersion = 3;
  static const String recordsTable = 'health_records';
  static const String weightTable = 'weight_logs';
  static const String sleepTable = 'sleep_logs';
  static const String workoutTable = 'workout_logs';
  static const String moodTable = 'mood_logs';

  // Default daily goals
  static const int defaultStepGoal = 10000;
  static const int defaultWaterGoal = 2500;
  static const int defaultCalorieGoal = 500;
  static const double sleepGoalHours = 8;
  static const int workoutGoalMinutes = 30;

  // Rough average energy used per step for an adult (kcal).
  static const double caloriesPerStep = 0.04;

  // Validation limits (sanity bounds for a single day)
  static const int maxSteps = 200000;
  static const int maxCalories = 20000;
  static const int maxWater = 20000;

  // Earliest date a record may be stored for
  static final DateTime earliestDate = DateTime(2000, 1, 1);
}

/// Semantic colours used across the UI.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0D47A1); // deep blue
  static const Color secondary = Color(0xFF00897B); // teal
  static const Color steps = Color(0xFF2E9E5B); // green
  static const Color calories = Color(0xFFF2711C); // orange
  static const Color water = Color(0xFF1E88E5); // blue
  static const Color sleep = Color(0xFF5C6BC0); // indigo
  static const Color workout = Color(0xFF8E24AA); // purple
  static const Color mood = Color(0xFFF9A825); // amber
  static const Color lightBackground = Color(0xFFF4F7FB);
  static const Color darkBackground = Color(0xFF0E1420);
}
