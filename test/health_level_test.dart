import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/health_level.dart';

void main() {
  group('HealthLevel thresholds', () {
    test('below 40% of goal is Low', () {
      expect(HealthLevel.of(0, 10000), HealthLevel.low);
      expect(HealthLevel.of(3999, 10000), HealthLevel.low);
    });

    test('40% to 74% is Moderate', () {
      expect(HealthLevel.of(4000, 10000), HealthLevel.moderate);
      expect(HealthLevel.of(7499, 10000), HealthLevel.moderate);
    });

    test('75% to 99% is Good', () {
      expect(HealthLevel.of(7500, 10000), HealthLevel.good);
      expect(HealthLevel.of(9999, 10000), HealthLevel.good);
    });

    test('goal reached or beaten is Excellent', () {
      expect(HealthLevel.of(10000, 10000), HealthLevel.excellent);
      expect(HealthLevel.of(15000, 10000), HealthLevel.excellent);
    });

    test('a missing goal is Low and never divides by zero', () {
      expect(HealthLevel.of(500, 0), HealthLevel.low);
    });

    test('works for water and calories goals too', () {
      expect(HealthLevel.of(2000, 2500), HealthLevel.good);
      expect(HealthLevel.of(250, 500), HealthLevel.moderate);
    });
  });
}
