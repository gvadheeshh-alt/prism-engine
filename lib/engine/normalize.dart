import '../models/models.dart';
import 'math_utils.dart';

/// Stage 2, step 1: turn raw quiz answers into a normalised 15-dim Student Vector S.
///
/// - Likert items (1..5) → (v - 1) / 4, reversed items → 1 - that, averaged per dimension.
/// - Choice items: share of the times a type was picked when offered; blended 50/50 with Likert.
/// - Aptitude dims → 0.7 × accuracy on timed items + 0.3 × self-rating (each 0..1).
/// - A dimension with no answers defaults to 0.5 (neutral) so it neither helps nor hurts.
StudentVector normalizeStudent({
  required String studentId,
  required String familyCode,
  required String name,
  required List<Question> questions,
  required StudentAnswers answers,
  required StudentContext context,
  DateTime? now,
}) {
  final likertSum = <Dimension, double>{};
  final likertCount = <Dimension, int>{};
  final aptCorrect = <Dimension, int>{};
  final aptTotal = <Dimension, int>{};
  final selfRating = <Dimension, double>{};

  final choiceWins = <Dimension, int>{};
  final choiceSeen = <Dimension, int>{};

  for (final q in questions) {
    if (q.type == QuestionType.likert) {
      final v = answers.likert[q.id];
      if (v != null) {
        var score = clamp01((v - 1) / 4);
        if (q.reverse) score = 1 - score;
        likertSum[q.dimension] = (likertSum[q.dimension] ?? 0) + score;
        likertCount[q.dimension] = (likertCount[q.dimension] ?? 0) + 1;
      }
    } else if (q.type == QuestionType.choice) {
      final pick = answers.choice[q.id];
      if (pick != null && pick >= 0 && pick < q.optionDims.length) {
        for (final d in q.optionDims) {
          choiceSeen[d] = (choiceSeen[d] ?? 0) + 1;
        }
        final won = q.optionDims[pick];
        choiceWins[won] = (choiceWins[won] ?? 0) + 1;
      }
    } else if (q.type == QuestionType.aptitude) {
      final correct = answers.aptitude[q.id];
      if (correct != null) {
        aptTotal[q.dimension] = (aptTotal[q.dimension] ?? 0) + 1;
        if (correct) aptCorrect[q.dimension] = (aptCorrect[q.dimension] ?? 0) + 1;
      }
    } else if (q.type == QuestionType.selfRating) {
      final v = answers.selfRating[q.id];
      if (v != null) selfRating[q.dimension] = clamp01((v - 1) / 4);
    }
  }

  final dims = <Dimension, double>{};
  for (final d in Dimension.values) {
    if (d.group == DimGroup.aptitude) {
      final total = aptTotal[d] ?? 0;
      final double? acc = total > 0 ? (aptCorrect[d] ?? 0) / total : null;
      final self = selfRating[d];
      if (acc != null && self != null) {
        dims[d] = 0.7 * acc + 0.3 * self;
      } else {
        dims[d] = acc ?? self ?? 0.5;
      }
    } else {
      final n = likertCount[d] ?? 0;
      final double? likert = n > 0 ? likertSum[d]! / n : null;
      final seen = choiceSeen[d] ?? 0;
      final double? chosen = seen > 0 ? (choiceWins[d] ?? 0) / seen : null;
      // Interests blend agree/disagree answers with forced choices, which cannot all be "agree".
      if (likert != null && chosen != null) {
        dims[d] = 0.5 * likert + 0.5 * chosen;
      } else {
        dims[d] = likert ?? chosen ?? 0.5;
      }
    }
  }

  return StudentVector(
    studentId: studentId,
    familyCode: familyCode,
    name: name,
    dims: Vector15(dims),
    context: context,
    completedAt: now ?? DateTime.now(),
  );
}
