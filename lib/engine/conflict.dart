import '../models/models.dart';
import 'eligibility.dart';
import 'finance.dart';
import 'format.dart';
import 'math_utils.dart';

/// Similarity between two careers (0..1): same career = 1, otherwise
/// 0.3 × same-cluster + 0.7 × max(0, Pearson of requirement vectors).
double careerSimilarity(Career a, Career b) {
  if (a.id == b.id) return 1;
  final cluster = a.cluster == b.cluster ? 1.0 : 0.0;
  final r = weightedPearson(a.requirement, b.requirement, onesVector);
  return 0.3 * cluster + 0.7 * (r > 0 ? r : 0.0);
}

/// How close a career is to what the parents prefer (0..1). 0.5 if they named nothing.
double parentAlignment(Career c, ParentProfile p, Map<String, Career> byId) {
  final prefs = [for (final id in p.preferredCareerIds) if (byId[id] != null) byId[id]!];
  if (prefs.isEmpty) return 0.5;
  return prefs.map<double>((x) => careerSimilarity(c, x)).reduce((a, b) => a > b ? a : b);
}

const _yearsUntilDegree = {
  StudyLevel.class9: 4,
  StudyLevel.class10: 3,
  StudyLevel.class11: 2,
  StudyLevel.class12: 1,
  StudyLevel.ug: 0,
  StudyLevel.pg: 0,
};

int yearsUntilDegree(StudyLevel l) => _yearsUntilDegree[l] ?? 1;

/// Stage 2, step 4: Parent–Student Conflict Index (0..100).
/// PSCI = 100 × [0.35 × (1 − preference overlap) + 0.25 × |risk_student − risk_parent|
///              + 0.20 × salary-expectation gap + 0.20 × relocation/timeline mismatch]
ConflictResult? parentStudentConflictIndex(
  StudentVector s,
  ParentProfile? p,
  Map<String, Career> byId,
  Map<String, double> fitByCareer,
) {
  if (p == null) return null;
  final dreams = [for (final id in s.context.dreamCareerIds) if (byId[id] != null) byId[id]!];
  final prefs = [for (final id in p.preferredCareerIds) if (byId[id] != null) byId[id]!];

  // 1. Preference overlap, symmetric average of best matches in both directions.
  double preference;
  if (dreams.isNotEmpty && prefs.isNotEmpty) {
    double best(Career a, List<Career> others) =>
        others.map<double>((o) => careerSimilarity(a, o)).reduce((x, y) => x > y ? x : y);
    final o1 = dreams.map((d) => best(d, prefs)).reduce((a, b) => a + b) / dreams.length;
    final o2 = prefs.map((x) => best(x, dreams)).reduce((a, b) => a + b) / prefs.length;
    preference = clamp01(1 - (o1 + o2) / 2);
  } else {
    preference = 0.5;
  }

  // 2. Risk appetite gap.
  final studentRisk = s.dims[Dimension.riskTolerance];
  final risk = (studentRisk - p.riskAppetite).abs();

  // 3. Salary expectation gap: how far the dream careers fall short of what parents expect at 25.
  final projected = dreams.isEmpty ? 0.0 : dreams.map(salaryAt25).reduce((a, b) => a + b) / dreams.length;
  final expected = p.expectedSalaryAt25INR.toDouble();
  final salaryGap = (expected <= 0 || dreams.isEmpty) ? 0.0 : clamp01((expected - projected) / expected);

  // 4. Relocation + timeline mismatch.
  final relocation = (s.context.mobility.index - p.relocationAcceptance.index).abs() / 3;
  final pathYears = yearsUntilDegree(s.context.level) +
      (dreams.isEmpty
          ? 4.0
          : dreams.map<int>((d) => d.routes.map<int>((r) => r.years).reduce((a, b) => a < b ? a : b)).reduce((a, b) => a + b) /
              dreams.length);
  final timeline = clamp01((pathYears - p.preferredYearsToEarning) / 4);
  final relocationTimeline = (relocation + timeline) / 2;

  final psci = 100 * (0.35 * preference + 0.25 * risk + 0.20 * salaryGap + 0.20 * relocationTimeline);

  // Plain-language drivers, ranked by their weighted contribution.
  final drivers = <MapEntry<double, String>>[
    MapEntry(0.35 * preference,
        'Your dream careers and your parents\' preferred careers are in quite different fields.'),
    MapEntry(
        0.25 * risk,
        studentRisk > p.riskAppetite
            ? 'You are more comfortable with risk than your parents, who prefer a safer, stable path.'
            : 'Your parents are more open to a risky path than you are.'),
    MapEntry(0.20 * salaryGap,
        'Your parents expect about ${inr(expected)} a year by age 25; your chosen careers usually pay about ${inr(projected)} at that point.'),
    MapEntry(
        0.20 * relocationTimeline,
        timeline > relocation
            ? 'Your path takes about ${pathYears.toStringAsFixed(0)} years before earning; your parents hoped for ${p.preferredYearsToEarning}.'
            : 'You are willing to move further for work (${s.context.mobility.name}) than your parents prefer (${p.relocationAcceptance.name}).'),
  ]..sort((a, b) => b.key.compareTo(a.key));

  // Bridge careers: good for the student AND close to parents' wishes (harmonic mean).
  final exclude = {...p.preferredCareerIds, ...s.context.dreamCareerIds};
  final bridges = <BridgeCareer>[];
  for (final c in byId.values) {
    if (exclude.contains(c.id) || needsStreamSwitch(c, s.context)) continue;
    final f = fitByCareer[c.id] ?? 0;
    final a = parentAlignment(c, p, byId);
    final h = (f + a) == 0 ? 0.0 : 2 * f * a / (f + a);
    bridges.add(BridgeCareer(c, f, a, h));
  }
  bridges.sort((a, b) => b.combined.compareTo(a.combined));

  return ConflictResult(
    psci100: psci,
    preference: preference,
    risk: risk,
    salaryGap: salaryGap,
    relocationTimeline: relocationTimeline,
    drivers: drivers.where((d) => d.key > 0.02).take(2).map((d) => d.value).toList(),
    bridgeCareers: bridges.take(3).toList(),
    trace: Trace(
      metric: 'Parent–Student Conflict Index',
      formula: 'PSCI = 100 × [0.35 × (1 − preference overlap) + 0.25 × risk gap + 0.20 × salary gap + 0.20 × relocation/timeline]',
      inputs: {
        'Preference mismatch': round2(preference),
        'Risk gap': round2(risk),
        'Salary-expectation gap': round2(salaryGap),
        'Relocation / timeline mismatch': round2(relocationTimeline),
      },
      value: psci,
    ),
  );
}
