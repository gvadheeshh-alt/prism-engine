import 'dart:math' as math;

import '../engine/engine.dart';
import '../models/models.dart';
import 'seed_data.dart';

/// Aggregates for the school dashboard.
class CohortStats {
  final int size;
  final Map<Dimension, double> avgDims;
  final Map<String, int> topCareerCounts; // careerId -> students for whom it is #1
  final Map<ConflictBand, int> conflictBands;
  final Map<Dimension, int> commonGaps;
  final int notViableTopChoice;
  const CohortStats({
    required this.size,
    required this.avgDims,
    required this.topCareerCounts,
    required this.conflictBands,
    required this.commonGaps,
    required this.notViableTopChoice,
  });
}

/// Builds a SIMULATED cohort from the demo personas plus random variation (fixed seed, so it is repeatable),
/// runs the real engine for every student, and aggregates. Replace with real submissions in production.
CohortStats simulateCohort(SeedData seed, {int size = 60, int randomSeed = 7}) {
  final rng = math.Random(randomSeed);
  final districts = ['Chennai', 'Coimbatore', 'Madurai', 'Tiruppur', 'Thanjavur', 'Thoothukkudi', 'Krishnagiri', 'Kancheepuram', 'Salem'];
  final careerIds = seed.careers.map((c) => c.id).toList();
  final avg = {for (final d in Dimension.values) d: 0.0};
  final top = <String, int>{};
  final bands = {for (final b in ConflictBand.values) b: 0};
  final gaps = <Dimension, int>{};
  var notViable = 0;

  double jitter(double v) => (v + (rng.nextDouble() - 0.5) * 0.5).clamp(0.05, 0.98).toDouble();
  String pick(List<String> l) => l[rng.nextInt(l.length)];

  for (var i = 0; i < size; i++) {
    final base = seed.personas[i % seed.personas.length];
    final dims = Vector15({for (final d in Dimension.values) d: jitter(base.student.dims[d])});
    final level = StudyLevel.values[2 + rng.nextInt(3)]; // class11, class12, ug
    final stream = [AcademicStream.sciencePcm, AcademicStream.sciencePcb, AcademicStream.sciencePcmb, AcademicStream.commerce, AcademicStream.humanities][rng.nextInt(5)];
    final ctx = StudentContext(
      level: level,
      stream: stream,
      marksBand: MarksBand.values[1 + rng.nextInt(4)],
      state: 'Tamil Nadu',
      district: pick(districts),
      mobility: Mobility.values[rng.nextInt(4)],
      dreamCareerIds: [pick(careerIds), pick(careerIds)],
      gender: rng.nextBool() ? Gender.female : Gender.male,
    );
    final student = StudentVector(
        studentId: 'sim-$i', familyCode: 'SIM${i.toString().padLeft(3, '0')}', name: 'Student ${i + 1}', dims: dims, context: ctx, completedAt: DateTime(2026));
    final income = [150000, 375000, 650000, 1150000, 2250000][rng.nextInt(5)];
    final parent = ParentProfile(
      familyCode: student.familyCode,
      annualIncomeINR: income,
      savingsForEducationINR: (income * (0.1 + rng.nextDouble() * 0.6)).round(),
      maxMonthlyEmiINR: (income / 12 * 0.2).round(),
      expectedSalaryAt25INR: 400000 + rng.nextInt(10) * 100000,
      loanComfort: LoanComfort.values[rng.nextInt(3)],
      riskAppetite: rng.nextDouble() * 0.7,
      preferredCareerIds: [pick(careerIds), pick(careerIds)],
      preferredYearsToEarning: 3 + rng.nextInt(5),
      relocationAcceptance: Mobility.values[rng.nextInt(3)],
      completedAt: DateTime(2026),
    );
    final r = runEngine(student: student, parent: parent, seed: seed);
    for (final d in Dimension.values) {
      avg[d] = avg[d]! + dims[d] / size;
    }
    final first = r.rankings.first;
    top[first.careerId] = (top[first.careerId] ?? 0) + 1;
    if (r.conflict != null) bands[r.conflict!.band] = bands[r.conflict!.band]! + 1;
    for (final g in first.gaps) {
      gaps[g.dimension] = (gaps[g.dimension] ?? 0) + 1;
    }
    if (first.finance.notViableWithoutAid) notViable++;
  }
  return CohortStats(
    size: size,
    avgDims: avg,
    topCareerCounts: top,
    conflictBands: bands,
    commonGaps: gaps,
    notViableTopChoice: notViable,
  );
}
