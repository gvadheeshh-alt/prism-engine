import 'package:flutter_test/flutter_test.dart';
import 'package:prism_engine/engine/conflict.dart';
import 'package:prism_engine/engine/fit.dart';
import 'package:prism_engine/engine/market.dart';
import 'package:prism_engine/models/models.dart';

import 'helpers.dart';

void main() {
  final seed = loadSeed();
  Map<String, double> fits(StudentVector s) => {for (final c in seed.careers) c.id: fitScore(s.dims, c).value};

  test('no parent → no conflict result', () {
    final s = persona(seed, 'arjun').student;
    expect(parentStudentConflictIndex(s, null, seed.careerById, fits(s)), isNull);
  });

  test('identical choices, risk and expectations → aligned', () {
    final s = persona(seed, 'arjun').student;
    final p = ParentProfile(
      familyCode: s.familyCode,
      annualIncomeINR: 600000,
      savingsForEducationINR: 0,
      maxMonthlyEmiINR: 0,
      expectedSalaryAt25INR: 1,
      loanComfort: LoanComfort.none,
      riskAppetite: s.dims[Dimension.riskTolerance],
      preferredCareerIds: s.context.dreamCareerIds,
      preferredYearsToEarning: 10,
      relocationAcceptance: s.context.mobility,
      completedAt: DateTime(2026),
    );
    final c = parentStudentConflictIndex(s, p, seed.careerById, fits(s))!;
    expect(c.psci100, lessThan(5));
    expect(c.band, ConflictBand.aligned);
  });

  test('demo persona Priya shows significant conflict and a biomedical bridge', () {
    final pr = persona(seed, 'priya');
    final c = parentStudentConflictIndex(pr.student, pr.parent, seed.careerById, fits(pr.student))!;
    expect(c.psci100, greaterThan(50));
    expect(c.bridgeCareers.map((b) => b.career.id), contains('biomedical-engineer'));
    expect(c.drivers.length, inInclusiveRange(1, 2));
  });

  test('career similarity: same career 1, symmetric, within 0..1', () {
    final a = seed.careerById['architect']!, b = seed.careerById['civil-engineer']!;
    expect(careerSimilarity(a, a), 1);
    expect(careerSimilarity(a, b), closeTo(careerSimilarity(b, a), 1e-9));
    expect(careerSimilarity(a, b), inInclusiveRange(0, 1));
  });

  test('market score within 0..1; local mobility uses only the home city', () {
    final stats = MarketStats.from(seed.careers);
    final s = persona(seed, 'arjun').student;
    const local = StudentContext(
      level: StudyLevel.class10, stream: AcademicStream.undecided, marksBand: MarksBand.b60to75,
      state: 'Tamil Nadu', district: 'Coimbatore', mobility: Mobility.local, dreamCareerIds: []);
    for (final c in seed.careers) {
      final m = marketScore(c, s.context, seed.regions, stats);
      expect(m.value, inInclusiveRange(0, 1));
      final ml = marketScore(c, local, seed.regions, stats);
      expect(ml.geoDemand, c.market.regionalDemand['coimbatore']);
    }
  });
}
