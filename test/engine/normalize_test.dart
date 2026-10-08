import 'package:flutter_test/flutter_test.dart';
import 'package:prism_engine/engine/normalize.dart';
import 'package:prism_engine/models/models.dart';

import 'helpers.dart';

void main() {
  final seed = loadSeed();
  const ctx = StudentContext(
    level: StudyLevel.class12,
    stream: AcademicStream.sciencePcm,
    marksBand: MarksBand.b75to90,
    state: 'Tamil Nadu',
    district: 'Chennai',
    mobility: Mobility.state,
    dreamCareerIds: [],
  );

  StudentVector run(StudentAnswers a) => normalizeStudent(
      studentId: 's', familyCode: 'ABC123', name: 'T', questions: seed.questions, answers: a, context: ctx);

  test('all "not sure" answers give 0.5 on every interest dimension', () {
    final a = StudentAnswers();
    for (final q in seed.questions.where((q) => q.type == QuestionType.likert)) {
      a.likert[q.id] = 3;
    }
    final v = run(a);
    for (final d in Dimension.values.where((d) => d.group != DimGroup.aptitude)) {
      expect(v.dims[d], closeTo(0.5, 1e-9), reason: d.name);
    }
  });

  test('reverse-scored items are flipped', () {
    final a = StudentAnswers();
    for (final q in seed.questions.where((q) => q.type == QuestionType.likert && q.dimension == Dimension.realistic)) {
      a.likert[q.id] = q.reverse ? 1 : 5; // maximally "realistic" either way
    }
    expect(run(a).dims[Dimension.realistic], closeTo(1.0, 1e-9));
  });

  test('perfect aptitude + top self-rating = 1.0; no answers = neutral 0.5', () {
    final a = StudentAnswers();
    for (final q in seed.questions) {
      if (q.type == QuestionType.aptitude) a.aptitude[q.id] = true;
      if (q.type == QuestionType.selfRating) a.selfRating[q.id] = 5;
    }
    final v = run(a);
    expect(v.dims[Dimension.numerical], closeTo(1.0, 1e-9));
    expect(v.dims[Dimension.openness], 0.5); // no likert answers given
  });

  test('every dimension stays within 0..1', () {
    final a = StudentAnswers();
    for (final q in seed.questions) {
      if (q.type == QuestionType.likert) a.likert[q.id] = 5;
      if (q.type == QuestionType.aptitude) a.aptitude[q.id] = false;
      if (q.type == QuestionType.selfRating) a.selfRating[q.id] = 1;
    }
    final v = run(a);
    for (final d in Dimension.values) {
      expect(v.dims[d], inInclusiveRange(0, 1));
    }
  });

  test('forced choices separate interests even when every statement gets "agree"', () {
    final a = StudentAnswers();
    for (final q in seed.questions.where((q) => q.type == QuestionType.likert)) {
      a.likert[q.id] = 4;
    }
    for (final q in seed.questions.where((q) => q.type == QuestionType.choice)) {
      final i = q.optionDims.indexOf(Dimension.artistic);
      a.choice[q.id] = i >= 0 ? i : 0;
    }
    final v = run(a);
    expect(v.dims[Dimension.artistic], greaterThan(v.dims[Dimension.conventional] + 0.2));
  });

  test('every choice question offers two different interest types', () {
    for (final q in seed.questions.where((q) => q.type == QuestionType.choice)) {
      expect(q.options.length, 2, reason: q.id);
      expect(q.optionDims.length, 2, reason: q.id);
      expect(q.optionDims.toSet().length, 2, reason: q.id);
    }
  });
}
