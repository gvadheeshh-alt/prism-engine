import '../data/seed_data.dart';
import '../models/models.dart';
import 'conflict.dart';
import 'eligibility.dart';
import 'finance.dart';
import 'fit.dart';
import 'hyperlocal.dart';
import 'labels.dart';
import 'market.dart';
import 'math_utils.dart';
import 'roadmap.dart';
import 'swot.dart';

const engineVersion = '1.0.0';
const dataDisclaimer =
    'Demo data: salaries, costs, job-growth and demand figures are ILLUSTRATIVE estimates for this prototype, '
    'not official statistics. Always verify exam dates, fees and scholarships on official websites.';

/// The whole PRISM pipeline (stages 2 and 3). Pure and deterministic: same inputs, same output.
///
/// PRISM = 100 × (α·Fit + β·Market + γ·Feasibility + δ·ROI_norm) / (α+β+γ+δ)
///         − λ × (PSCI / 100) × (1 − parent alignment)
EngineResult runEngine({
  required StudentVector student,
  ParentProfile? parent,
  required SeedData seed,
  ScoreWeights weights = const ScoreWeights(),
  Map<String, double> velocityOverrides = const {},
  int? startYear,
}) {
  final careers = [
    for (final c in seed.careers)
      velocityOverrides.containsKey(c.id) ? c.withMarket(c.market.copyWith(jobVelocity: velocityOverrides[c.id])) : c
  ];
  final byId = {for (final c in careers) c.id: c};
  final stats = MarketStats.from(careers);

  final fits = {for (final c in careers) c.id: fitScore(student.dims, c)};
  final fitValues = fits.map((k, v) => MapEntry(k, v.value));
  final conflict = parentStudentConflictIndex(student, parent, byId, fitValues);
  final sumW = weights.sum <= 0 ? 1.0 : weights.sum;

  final scores = <CareerScore>[];
  for (final c in careers) {
    final fit = fits[c.id]!;
    final fin = financialConstraintSolver(c, student, parent, seed.scholarships);
    final mkt = marketScore(c, student.context, seed.regions, stats);
    final flags = <String>[];

    var feasibility = fin.result.best.feasibility;
    if (needsStreamSwitch(c, student.context)) {
      feasibility *= 0.3;
      flags.add('Needs a different stream: ${c.eligibleStreams.map(streamLabel).join(' or ')}');
    }
    if (fin.result.notViableWithoutAid) flags.add('Not viable without extra aid');

    final roiN = roiNormalized(fin.result.best.roi);
    final alignment = parent == null ? 1.0 : parentAlignment(c, parent, byId);
    final penalty = conflict == null ? 0.0 : weights.lambda * (conflict.psci100 / 100) * (1 - alignment);
    final weighted =
        (weights.alpha * fit.value + weights.beta * mkt.value + weights.gamma * feasibility + weights.delta * roiN) / sumW;
    final prism = (100 * weighted - penalty).clamp(0.0, 100.0).toDouble();

    final composite = Trace(
      metric: 'PRISM score',
      formula: 'PRISM = 100 × (α·Fit + β·Market + γ·Feasibility + δ·ROI) / (α+β+γ+δ) − λ × PSCI/100 × (1 − parent alignment)',
      inputs: {
        'Fit × α': '${round2(fit.value)} × ${weights.alpha.toStringAsFixed(2)}',
        'Market × β': '${round2(mkt.value)} × ${weights.beta.toStringAsFixed(2)}',
        'Feasibility × γ': '${round2(feasibility)} × ${weights.gamma.toStringAsFixed(2)}',
        'ROI (normalised) × δ': '${round2(roiN)} × ${weights.delta.toStringAsFixed(2)}',
        'Parent alignment': round2(alignment),
        'Conflict penalty (points)': round2(penalty),
      },
      value: prism,
    );

    scores.add(CareerScore(
      career: c,
      prism100: prism,
      components:
          ScoreComponents(fit: fit.value, market: mkt.value, feasibility: feasibility, roiNorm: roiN, conflictPenalty: penalty),
      finance: fin.result,
      gaps: gapAnalysis(student.dims, c),
      demand: mkt.demand,
      flags: flags,
      traces: [composite, fit.trace, mkt.trace, fin.trace],
    ));
  }
  scores.sort((a, b) => b.prism100.compareTo(a.prism100));

  final local = hyperLocalIdeas(student, seed.localIndustries, fitValues);
  final swot = buildSwot(
    student: student,
    rankings: scores,
    conflict: conflict,
    ideas: local.ideas,
    area: local.area,
  );
  final roadmaps = [for (final s in scores.take(3)) buildRoadmap(s, student, seed, startYear: startYear)];

  return EngineResult(
    version: engineVersion,
    familyCode: student.familyCode,
    disclaimer: dataDisclaimer,
    generatedAt: DateTime.now(),
    weights: weights,
    student: student,
    parent: parent,
    rankings: scores,
    conflict: conflict,
    swot: swot,
    roadmaps: roadmaps,
    hyperLocal: local.ideas,
    hyperLocalArea: local.area,
  );
}
