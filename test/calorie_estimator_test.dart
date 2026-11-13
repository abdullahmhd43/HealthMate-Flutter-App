import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/calorie_estimator.dart';

void main() {
  test('estimates about 0.04 kcal per step', () {
    expect(CalorieEstimator.fromSteps(10000), 400);
    expect(CalorieEstimator.fromSteps(7850), 314);
    expect(CalorieEstimator.fromSteps(0), 0);
  });

  test('parses text safely', () {
    expect(CalorieEstimator.fromText('5000'), 200);
    expect(CalorieEstimator.fromText(' 2500 '), 100);
    expect(CalorieEstimator.fromText(''), isNull);
    expect(CalorieEstimator.fromText('abc'), isNull);
    expect(CalorieEstimator.fromText('-5'), isNull);
    expect(CalorieEstimator.fromText('12.5'), isNull);
  });
}
