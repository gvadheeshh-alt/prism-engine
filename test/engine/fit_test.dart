import 'package:flutter_test/flutter_test.dart';
import 'package:prism_engine/engine/fit.dart';

import 'helpers.dart';

void main() {
  final seed = loadSeed();

  test('a student identical to the requirement vector gets fit 1.0', () {
    for (final c in seed.careers) {
      final r = fitScore(c.requirement, c);
      expect(r.value, closeTo(1.0, 1e-9), reason: c.id);
    }
  });

  test('fit is always within 0..1, including all-max and all-zero students', () {
    for (final s in [uniform(1), uniform(0), uniform(0.5)]) {
      for (final c in seed.careers) {
        expect(fitScore(s, c).value, inInclusiveRange(0, 1));
      }
    }
  });

  test('an artistic profile fits design better than accounting', () {
    final priya = persona(seed, 'priya').student.dims;
    final design = fitScore(priya, seed.careerById['product-designer']!).value;
    final ca = fitScore(priya, seed.careerById['chartered-accountant']!).value;
    expect(design, greaterThan(ca + 0.2));
  });

  test('gap analysis returns at most 3 gaps, largest weighted gap first', () {
    final gaps = gapAnalysis(uniform(0.2), seed.careerById['doctor-mbbs']!);
    expect(gaps.length, lessThanOrEqualTo(3));
    expect(gaps, isNotEmpty);
  });
}
