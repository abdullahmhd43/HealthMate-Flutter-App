import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/calorie_estimator.dart';
import 'package:healthmate/core/utils/validators.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/profile/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const adult = UserProfile(
      name: 'Sam', age: 30, gender: Gender.male, heightCm: 170, weightKg: 70);

  group('BMI', () {
    test('is weight divided by height squared', () {
      expect(adult.bmi, closeTo(24.22, 0.01));
      expect(adult.bmiCategory, BmiCategory.healthy);
    });

    test('is null without height and weight', () {
      expect(const UserProfile().bmi, isNull);
      expect(const UserProfile().bmiCategory, isNull);
      expect(const UserProfile().isComplete, isFalse);
    });

    test('category boundaries', () {
      expect(BmiCategory.fromBmi(18.4), BmiCategory.underweight);
      expect(BmiCategory.fromBmi(18.5), BmiCategory.healthy);
      expect(BmiCategory.fromBmi(24.9), BmiCategory.healthy);
      expect(BmiCategory.fromBmi(25), BmiCategory.overweight);
      expect(BmiCategory.fromBmi(30), BmiCategory.obese);
    });
  });

  group('recommended goals', () {
    test('for a 30-year-old, 70 kg, 170 cm', () {
      expect(adult.isComplete, isTrue);
      expect(adult.recommendedSteps, 10000);
      expect(adult.recommendedWater, 2450);
      expect(adult.recommendedCalories, 370);
    });

    test('steps depend on age', () {
      expect(const UserProfile(age: 12).recommendedSteps, 12000);
      expect(const UserProfile(age: 40).recommendedSteps, 10000);
      expect(const UserProfile(age: 70).recommendedSteps, 7000);
    });

    test('water is limited to a sensible range', () {
      expect(const UserProfile(weightKg: 30).recommendedWater, 1500);
      expect(const UserProfile(weightKg: 200).recommendedWater, 5000);
    });

    test('calories per step grows with weight', () {
      const light = UserProfile(heightCm: 170, weightKg: 50);
      const heavy = UserProfile(heightCm: 170, weightKg: 100);
      expect(heavy.kcalPerStep, greaterThan(light.kcalPerStep));
      expect(adult.kcalPerStep, closeTo(0.037, 0.001));
    });

    test('falls back to the default without a profile', () {
      expect(const UserProfile().kcalPerStep, 0.04);
    });
  });

  group('calorie estimator with a profile', () {
    test('uses the profile rate', () {
      final estimate =
          CalorieEstimator.fromSteps(10000, kcalPerStep: adult.kcalPerStep);
      expect(estimate, 370);
    });
  });

  group('profile validation', () {
    test('age', () {
      expect(Validators.age(''), 'Age is required');
      expect(Validators.age('abc'), contains('whole number'));
      expect(Validators.age('3'), contains('between'));
      expect(Validators.age('121'), contains('between'));
      expect(Validators.age('30'), isNull);
    });

    test('height and weight accept decimals with dot or comma', () {
      expect(Validators.height('170.5'), isNull);
      expect(Validators.weight('70,5'), isNull);
      expect(Validators.parseDecimal('70,5'), 70.5);
    });

    test('height and weight reject bad values', () {
      expect(Validators.height(''), 'Height is required');
      expect(Validators.height('50'), contains('between'));
      expect(Validators.height('abc'), contains('number'));
      expect(Validators.weight('10'), contains('between'));
      expect(Validators.weight('400'), contains('between'));
      expect(Validators.weight('-70'), contains('between'));
    });

    test('name is optional but limited', () {
      expect(Validators.name(''), isNull);
      expect(Validators.name('A' * 31), contains('30'));
    });
  });

  group('ProfileProvider', () {
    test('persists and reloads the profile', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final a = ProfileProvider(prefs);
      expect(a.profile.isComplete, isFalse);

      await a.save(adult);

      final b = ProfileProvider(prefs);
      expect(b.profile.name, 'Sam');
      expect(b.profile.age, 30);
      expect(b.profile.gender, Gender.male);
      expect(b.profile.heightCm, 170);
      expect(b.profile.weightKg, 70);
    });

    test('updateWeight changes only the weight', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = ProfileProvider(prefs);
      await provider.save(adult);

      await provider.updateWeight(68.5);

      expect(provider.profile.weightKg, 68.5);
      expect(provider.profile.heightCm, 170);
      expect(provider.profile.name, 'Sam');
    });
  });
}
