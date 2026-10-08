import '../models/models.dart';
import 'format.dart';

/// Rule-based scholarship eligibility. Returns matches with the rules that were satisfied.
/// Students below Class 12 are matched against Class 12 / UG schemes they will become eligible for.
List<ScholarshipMatch> matchScholarships(StudentVector s, ParentProfile? p, List<Scholarship> all, {Career? career}) {
  final ctx = s.context;
  final gender = p?.childGender ?? ctx.gender;
  final category = p?.category ?? ctx.category;
  final out = <ScholarshipMatch>[];
  for (final sc in all) {
    final matched = <String>[];
    if (sc.maxIncomeINR != null) {
      if (p == null || p.annualIncomeINR > sc.maxIncomeINR!) continue;
      matched.add('Family income under ${inr(sc.maxIncomeINR!)}');
    }
    if (sc.states.isNotEmpty) {
      if (!sc.states.contains(ctx.state)) continue;
      matched.add('Resident of ${ctx.state}');
    }
    if (sc.genders.isNotEmpty) {
      if (gender == null || !sc.genders.contains(gender)) continue;
      matched.add('Gender: ${gender.name}');
    }
    if (sc.categories.isNotEmpty) {
      if (category == null || !sc.categories.contains(category)) continue;
      matched.add('Category: ${category.name.toUpperCase()}');
    }
    if (sc.minMarksBand != null) {
      if (ctx.marksBand.index < sc.minMarksBand!.index) continue;
      matched.add('Marks band meets the cut-off');
    }
    if (sc.levels.isNotEmpty) {
      final future = ctx.level.index < StudyLevel.class12.index;
      if (!sc.levels.contains(ctx.level) && !future) continue;
    }
    if (sc.requiresFirstGen) {
      if (p == null || !p.firstGenerationLearner) continue;
      matched.add('First graduate in the family');
    }
    if (sc.requiresDisability) {
      if (p == null || !p.disability) continue;
      matched.add('Disability criteria');
    }
    if (sc.clusters.isNotEmpty) {
      if (career == null || !sc.clusters.contains(career.cluster)) continue;
      matched.add('Course type fits this scheme');
    }
    out.add(ScholarshipMatch(sc, matched));
  }
  out.sort((a, b) => b.scholarship.amountINR.compareTo(a.scholarship.amountINR));
  return out;
}
