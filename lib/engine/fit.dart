import 'dart:math' as math;

import '../models/models.dart';
import 'math_utils.dart';

class FitResult {
  final double value, pearson, shortfall;
  final Trace trace;
  const FitResult(this.value, this.pearson, this.shortfall, this.trace);
}

/// Stage 2, step 2: how well a career suits the student.
///
/// Two separate questions, because career research finds interests predict satisfaction better than ability:
///   Interest match = weighted Pearson correlation of the six RIASEC interest scores only (shape match).
///   Readiness      = 1 − weighted shortfall on aptitude and work style (how far below the bar the student is).
/// Fit = 0.65 × max(0, interest match) + 0.35 × readiness
FitResult fitScore(Vector15 s, Career c) {
  final interests = Dimension.values.where((d) => d.group == DimGroup.riasec).toList();
  final abilities = Dimension.values.where((d) => d.group != DimGroup.riasec).toList();

  // Weighted Pearson over the interest dimensions only.
  double sw = 0, ms = 0, mr = 0;
  for (final d in interests) {
    final w = c.importance[d];
    sw += w;
    ms += w * s[d];
    mr += w * c.requirement[d];
  }
  double r = 0;
  if (sw > 0) {
    ms /= sw;
    mr /= sw;
    double cov = 0, vs = 0, vr = 0;
    for (final d in interests) {
      final w = c.importance[d];
      final ds = s[d] - ms, dr = c.requirement[d] - mr;
      cov += w * ds * dr;
      vs += w * ds * ds;
      vr += w * dr * dr;
    }
    if (vs > 1e-12 && vr > 1e-12) r = cov / math.sqrt(vs * vr);
  }

  // Shortfall over aptitude and work style.
  double aw = 0, sf = 0;
  for (final d in abilities) {
    final w = c.importance[d];
    aw += w;
    final short = c.requirement[d] - s[d];
    sf += w * (short > 0 ? short : 0.0);
  }
  final shortfall = aw == 0 ? 0.0 : sf / aw;
  final value = clamp01(0.65 * (r > 0 ? r : 0.0) + 0.35 * (1 - shortfall));
  return FitResult(
    value,
    r,
    shortfall,
    Trace(
      metric: 'Fit',
      formula: 'Fit = 0.65 × max(0, interest match) + 0.35 × (1 − ability shortfall)\n'
          'Interest match = weighted Pearson of the six interest types; shortfall covers aptitude and work style',
      inputs: {
        'Interest match r (−1..1)': round2(r),
        'Ability shortfall (0..1)': round2(shortfall),
      },
      value: value,
    ),
  );
}

const Map<Dimension, List<GapAction>> _gapActions = {
  Dimension.numerical: [
    GapAction('Practise Class 9–12 maths daily', 'Khan Academy', 'https://www.khanacademy.org'),
    GapAction('Take a free maths foundation course', 'NPTEL', 'https://nptel.ac.in'),
  ],
  Dimension.logical: [
    GapAction('Solve one puzzle or chess problem a day', 'Self-practice'),
    GapAction('Learn basic programming logic', 'SWAYAM', 'https://swayam.gov.in'),
  ],
  Dimension.verbal: [
    GapAction('Read one long article a day and summarise it in 5 lines', 'Self-practice'),
    GapAction('Take a free communication skills course', 'SWAYAM', 'https://swayam.gov.in'),
  ],
  Dimension.spatial: [
    GapAction('Make simple 3D models', 'Tinkercad (free)', 'https://www.tinkercad.com'),
    GapAction('Sketch everyday objects from three views', 'Self-practice'),
  ],
  Dimension.creative: [
    GapAction('Finish one small creative project every month', 'Self-practice'),
    GapAction('Join your school innovation or tinkering lab', 'School ATL / club'),
  ],
  Dimension.realistic: [
    GapAction('Build an Arduino or electronics starter project', 'Maker club / ATL'),
    GapAction('Help repair something at home every month', 'Self-practice'),
  ],
  Dimension.investigative: [
    GapAction('Do one science-fair style mini research project', 'School / INSPIRE-MANAK'),
    GapAction('Take an introductory course in your subject', 'NPTEL', 'https://nptel.ac.in'),
  ],
  Dimension.artistic: [
    GapAction('Keep a sketchbook and build a portfolio', 'Self-practice'),
    GapAction('Study design basics through free video courses', 'SWAYAM', 'https://swayam.gov.in'),
  ],
  Dimension.social: [
    GapAction('Volunteer: teach juniors or join NSS', 'School / NSS'),
    GapAction('Lead a peer study group', 'Self-practice'),
  ],
  Dimension.enterprising: [
    GapAction('Organise a school event or start a club', 'School'),
    GapAction('Pitch an idea at a school or college E-cell event', 'E-cell'),
  ],
  Dimension.conventional: [
    GapAction('Learn spreadsheet basics', 'Google Sheets / Excel tutorials'),
    GapAction('Keep a weekly planner and track tasks', 'Self-practice'),
  ],
  Dimension.openness: [
    GapAction('Try one new subject course each term', 'SWAYAM', 'https://swayam.gov.in'),
  ],
  Dimension.conscientiousness: [
    GapAction('Use a weekly planner and track study hours', 'Self-practice'),
  ],
  Dimension.collaboration: [
    GapAction('Join a team competition (hackathon, robotics, quiz)', 'School / college'),
  ],
  Dimension.riskTolerance: [
    GapAction('Take small safe risks: enter a competition or pitch an idea', 'Self-practice'),
  ],
};

/// Largest importance-weighted gaps between the student and a career (top [top]).
List<GapItem> gapAnalysis(Vector15 s, Career c, {int top = 3}) {
  final items = <GapItem>[];
  for (final d in Dimension.values) {
    final gap = c.requirement[d] - s[d];
    if (gap > 0.05) {
      items.add(GapItem(dimension: d, required: c.requirement[d], current: s[d], actions: _gapActions[d] ?? const []));
    }
  }
  items.sort((a, b) => (c.importance[b.dimension] * b.gap).compareTo(c.importance[a.dimension] * a.gap));
  return items.take(top).toList();
}
