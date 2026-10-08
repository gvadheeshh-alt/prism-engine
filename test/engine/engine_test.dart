import 'package:flutter_test/flutter_test.dart';
import 'package:prism_engine/engine/engine.dart';
import 'package:prism_engine/models/models.dart';

import 'helpers.dart';

void main() {
  final seed = loadSeed();

  for (final p in seed.personas) {
    test('persona ${p.id}: complete, sorted, bounded result', () {
      final r = runEngine(student: p.student, parent: p.parent, seed: seed, startYear: 2026);
      expect(r.rankings.length, seed.careers.length);
      for (var i = 1; i < r.rankings.length; i++) {
        expect(r.rankings[i - 1].prism100, greaterThanOrEqualTo(r.rankings[i].prism100));
      }
      for (final s in r.rankings) {
        expect(s.prism100, inInclusiveRange(0, 100));
        expect(s.traces, isNotEmpty);
      }
      expect(r.roadmaps.length, 3);
      expect(r.hyperLocal.length, 3);
      expect(r.swot.strengths, isNotEmpty);
      expect(r.swot.threats, isNotEmpty);
      expect(r.conflict, isNotNull);
    });
  }

  test('deterministic: same inputs give identical scores', () {
    final p = persona(seed, 'priya');
    final a = runEngine(student: p.student, parent: p.parent, seed: seed);
    final b = runEngine(student: p.student, parent: p.parent, seed: seed);
    expect(a.rankings.map((s) => s.prism100).toList(), b.rankings.map((s) => s.prism100).toList());
  });

  test('Arjun (hands-on + creative, Coimbatore) gets robotics or EV in his top 3 and local ideas', () {
    final p = persona(seed, 'arjun');
    final r = runEngine(student: p.student, parent: p.parent, seed: seed);
    final top3 = r.rankings.take(3).map((s) => s.careerId);
    expect(top3.any((id) => id == 'robotics-engineer' || id == 'ev-engineer'), isTrue);
    expect(r.hyperLocalArea, 'Coimbatore');
  });

  test('Sneha (commerce UG) gets a data career first and a stream flag on engineering', () {
    final p = persona(seed, 'sneha');
    final r = runEngine(student: p.student, parent: p.parent, seed: seed);
    expect(r.rankings.first.careerId, anyOf('data-analyst', 'data-scientist'));
    expect(r.scoreFor('ai-ml-engineer')!.flags.any((f) => f.contains('stream')), isTrue);
  });

  test('weights matter: fit-only weighting ranks the best-fit career first', () {
    final p = persona(seed, 'priya');
    final r = runEngine(
      student: p.student,
      parent: p.parent,
      seed: seed,
      weights: const ScoreWeights(alpha: 1, beta: 0, gamma: 0, delta: 0, lambda: 0),
    );
    final bestFit = r.rankings.map((s) => s.components.fit).reduce((a, b) => a > b ? a : b);
    expect(r.rankings.first.components.fit, bestFit);
  });

  test('student-only mode works without a parent', () {
    final p = persona(seed, 'arjun');
    final r = runEngine(student: p.student, seed: seed);
    expect(r.conflict, isNull);
    expect(r.rankings.every((s) => s.components.conflictPenalty == 0), isTrue);
  });

  test('all-max student does not crash and stays bounded', () {
    final p = persona(seed, 'arjun');
    final s = StudentVector(
        studentId: 'x', familyCode: 'MAXMAX', name: 'Max', dims: uniform(1), context: p.student.context, completedAt: DateTime(2026));
    final r = runEngine(student: s, parent: p.parent, seed: seed);
    expect(r.rankings.first.prism100, inInclusiveRange(0, 100));
  });

  test('live velocity override changes the market component', () {
    final p = persona(seed, 'arjun');
    final base = runEngine(student: p.student, parent: p.parent, seed: seed).scoreFor('teacher')!.components.market;
    final boosted = runEngine(student: p.student, parent: p.parent, seed: seed, velocityOverrides: {'teacher': 40})
        .scoreFor('teacher')!
        .components
        .market;
    expect(boosted, greaterThan(base));
  });

  test('each dominant interest type gets a top career that matches it, and they differ', () {
    final p = persona(seed, 'arjun');
    final interests = Dimension.values.where((d) => d.group == DimGroup.riasec).toList();
    final tops = <String>{};
    for (final t in interests) {
      final dims = Vector15({
        for (final d in Dimension.values) d: d.group == DimGroup.riasec ? (d == t ? 0.9 : 0.3) : 0.6,
      });
      final s = StudentVector(studentId: 't', familyCode: 'TYPE${t.index}', name: t.name, dims: dims, context: p.student.context, completedAt: DateTime(2026));
      final top = runEngine(student: s, parent: p.parent, seed: seed).rankings.first.career;
      final strongest = interests.reduce((a, b) => top.requirement[a] >= top.requirement[b] ? a : b);
      expect(strongest, t, reason: '${t.name} student got ${top.id}');
      tops.add(top.id);
    }
    expect(tops.length, interests.length);
  });
}
