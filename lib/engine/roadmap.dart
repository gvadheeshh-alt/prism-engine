import '../data/seed_data.dart';
import '../models/models.dart';
import 'conflict.dart';
import 'format.dart';
import 'labels.dart';

String academicYear(int y) => '$y–${((y + 1) % 100).toString().padLeft(2, '0')}';

String streamAdvice(Career c) {
  if (c.eligibleStreams.isEmpty) return 'Any stream works; pick subjects you enjoy and score well in.';
  return 'Choose ${c.eligibleStreams.map(streamLabel).join(' or ')} in Class 11.';
}

/// Stage 3, step 8: year-by-year roadmap for one career.
Roadmap buildRoadmap(CareerScore cs, StudentVector s, SeedData seed, {int? startYear}) {
  final y0 = startYear ?? DateTime.now().year;
  final c = cs.career;
  final route = cs.finance.best;
  final routeDef = c.routes.firstWhere((r) => r.id == route.routeId, orElse: () => c.routes.first);
  final examIds = <String>{...routeDef.entryExamIds, ...c.relatedExamIds}.toList();
  final examNames = [for (final id in examIds) seed.examById[id]?.name ?? id];
  final examMonths = [
    for (final id in examIds)
      if (seed.examById[id] != null) '${seed.examById[id]!.name}: ${seed.examById[id]!.typicalMonths.join('/')}'
  ];
  final gapActions = [
    for (final g in cs.gaps.take(2))
      if (g.actions.isNotEmpty) 'Improve ${g.dimension.label.toLowerCase()}: ${g.actions.first.label} (${g.actions.first.resource})'
  ];
  final schemes = cs.finance.scholarships.take(3).map((m) => m.scholarship.name).toList();
  final topCities = cs.demand.where((d) => d.inRange).take(3).map((d) => d.region.name).toList();

  final steps = <RoadmapStep>[];
  final level = s.context.level;
  final wait = yearsUntilDegree(level);

  switch (level) {
    case StudyLevel.class9:
    case StudyLevel.class10:
      steps.add(RoadmapStep(
        periodLabel: 'Now (${academicYear(y0)})',
        title: 'Build foundations and pick your stream',
        actions: [streamAdvice(c), ...gapActions, 'Start one small project connected to ${c.name.toLowerCase()}'],
        examIds: const [],
      ));
      steps.add(RoadmapStep(
        periodLabel: '${academicYear(y0 + wait - 2)} to ${academicYear(y0 + wait - 1)}',
        title: 'Class 11–12: prepare for entrance exams',
        actions: [
          if (examNames.isNotEmpty) 'Prepare for: ${examNames.join(', ')}',
          if (examMonths.isNotEmpty) 'Usual exam months: ${examMonths.join('; ')}. Verify on the official website.',
          'Keep board marks strong; many scholarships use them',
        ],
        examIds: examIds,
      ));
    case StudyLevel.class11:
      steps.add(RoadmapStep(
        periodLabel: 'Now (${academicYear(y0)})',
        title: 'Class 11: strengthen key subjects',
        actions: [...gapActions, if (examNames.isNotEmpty) 'Start foundation preparation for ${examNames.first}'],
        examIds: const [],
      ));
      steps.add(RoadmapStep(
        periodLabel: academicYear(y0 + 1),
        title: 'Class 12: boards and entrance exams',
        actions: [
          if (examNames.isNotEmpty) 'Register for: ${examNames.join(', ')}',
          if (examMonths.isNotEmpty) 'Usual exam months: ${examMonths.join('; ')}. Verify on the official website.',
        ],
        examIds: examIds,
      ));
    case StudyLevel.class12:
      steps.add(RoadmapStep(
        periodLabel: 'Now (${academicYear(y0)})',
        title: 'Class 12: boards and entrance exams',
        actions: [
          if (examNames.isNotEmpty) 'Register for: ${examNames.join(', ')}',
          if (examMonths.isNotEmpty) 'Usual exam months: ${examMonths.join('; ')}. Verify on the official website.',
          ...gapActions,
        ],
        examIds: examIds,
      ));
    case StudyLevel.ug:
    case StudyLevel.pg:
      steps.add(RoadmapStep(
        periodLabel: 'Now (${academicYear(y0)})',
        title: 'Bridge into ${c.name.toLowerCase()} while you study',
        actions: [
          ...gapActions,
          'Build 2–3 portfolio projects you can show employers',
          if (topCities.isNotEmpty) 'Look for internships in ${topCities.first}',
        ],
        examIds: const [],
      ));
  }

  final degreeStart = y0 + wait;
  steps.add(RoadmapStep(
    periodLabel: route.years <= 1
        ? academicYear(degreeStart)
        : '${academicYear(degreeStart)} to ${academicYear(degreeStart + route.years - 1)}',
    title: 'Study: ${route.label} (${route.years} yr${route.years == 1 ? '' : 's'})',
    actions: [
      'Estimated total cost: ${inr(route.totalCostINR)} (${tierLabel(route.tier).toLowerCase()} route)',
      if (schemes.isNotEmpty) 'Apply for: ${schemes.join(', ')}',
      'Do at least one internship or real project every year',
    ],
    examIds: const [],
  ));
  steps.add(RoadmapStep(
    periodLabel: 'From ${degreeStart + route.years}',
    title: 'Start working as a ${c.name.toLowerCase()}',
    actions: [
      if (topCities.isNotEmpty) 'Strongest demand in your range: ${topCities.join(', ')}',
      'Typical starting salary: ${inr(c.startingSalaryINR)} a year (illustrative)',
    ],
    examIds: const [],
  ));

  return Roadmap(career: c, route: route, steps: steps, scholarships: cs.finance.scholarships);
}
