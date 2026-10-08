import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/engine.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _Formula extends StatelessWidget {
  final String title, formula, explain;
  final Color color;
  const _Formula({required this.title, required this.formula, required this.explain, required this.color});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        accent: color,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 8),
          Panel(primary: false, child: SelectableText(formula, style: tt.bodyMedium?.copyWith(fontFamily: 'monospace', height: 1.5))),
          const SizedBox(height: 8),
          Text(explain, style: tt.bodyMedium?.copyWith(height: 1.5)),
        ]),
      ),
    );
  }
}

/// The formulas behind every score, used on the About page.
class MethodologyContent extends StatelessWidget {
  const MethodologyContent({super.key});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Every score is a formula', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Scores are computed by deterministic code. The AI counselor only explains results in plain language; it never changes a number.'),
        const SectionTitle('Stage 1: Ingest'),
        const Text('Student: 26 interest and work-style statements (RIASEC + 4 work-style traits), 9 forced choices between interest types, 11 timed puzzles, 5 self-ratings, plus context. '
            'Parent: income band, savings, loan comfort, max EMI, risk appetite, preferred careers, salary expectation, timeline and relocation. '
            'The two are linked by a 6-character family code.'),
        const SectionTitle('Stage 2: Vectorise, normalise, solve'),
        const _Formula(
          title: 'Student vector S (15 dimensions)',
          formula: 'Likert: (answer − 1) / 4, reversed items flipped, averaged per dimension\n'
              'Choices: share of the times an interest type is picked; blended 50/50 with Likert\n'
              'Aptitude: 0.7 × puzzle accuracy + 0.3 × self-rating\n'
              'Missing dimension → 0.5 (neutral)',
          explain: 'Every value lands between 0 and 1, so dimensions are comparable.',
          color: PrismColors.fit,
        ),
        const _Formula(
          title: 'Fit',
          formula: 'Fit = 0.65 × max(0, interest match) + 0.35 × (1 − ability shortfall)\n'
              'Interest match = weighted Pearson of the six interest types (S vs R)\n'
              'Ability shortfall = Σ W·max(0, R − S) / Σ W over aptitude and work style',
          explain: 'Interests decide which careers suit the student; abilities decide how ready they are. '
              'Keeping them apart stops strong maths or logic scores from pushing the same few careers to the top for everyone.',
          color: PrismColors.fit,
        ),
        const _Formula(
          title: 'Financial Constraint Solver',
          formula: 'TC = (tuition + living) × years + coaching + exam fees\n'
              'Loan capacity = min(limit for comfort level, PV of EMI) where\n'
              '  EMI = min(parent max EMI, 35% of starting monthly salary), 84 months @ 9%\n'
              'Scholarship = 50% × min(top-2 matched schemes × years, tuition)\n'
              'F = min(1, (savings + scholarship + loan) / TC); viable if F ≥ 0.6\n'
              'ROI = (NPV 10-yr salary − NPV baseline earnings − TC) / TC, discount 8%',
          explain: 'Each education route (government, private, online, lateral entry) is solved separately and the cheapest viable one is used. '
              'Scholarships are counted at 50% because they are not guaranteed. A wrong stream multiplies F by 0.3.',
          color: PrismColors.feasibility,
        ),
        const _Formula(
          title: 'Parent–Student Conflict Index (PSCI)',
          formula: 'PSCI = 100 × [0.35 × (1 − preference overlap)\n'
              '            + 0.25 × |risk_student − risk_parent|\n'
              '            + 0.20 × salary expectation gap\n'
              '            + 0.20 × relocation / timeline mismatch]\n'
              'Career similarity = 0.3 × same cluster + 0.7 × max(0, Pearson(R_a, R_b))',
          explain: 'Bands: 0–25 aligned, 26–50 mild, 51–75 significant, 76–100 high. Bridge careers maximise the harmonic mean of '
              'student fit and parent alignment, so both must be good.',
          color: PrismColors.penalty,
        ),
        const SectionTitle('Stage 3: Synthesise'),
        const _Formula(
          title: 'Market score',
          formula: 'M = 0.35 × job-growth rank + 0.25 × (1 − disruption) + 0.20 × salary growth + 0.20 × geo demand',
          explain: 'Velocity and growth are min-max normalised across all careers. Geo demand is the best hub within the distance the student will move.',
          color: PrismColors.market,
        ),
        const _Formula(
          title: 'PRISM score',
          formula: 'PRISM = 100 × (α·Fit + β·M + γ·F + δ·ROI_norm) / (α+β+γ+δ)\n'
              '        − λ × PSCI/100 × (1 − parent alignment)\n'
              'ROI_norm = (min(ROI, 6) + 1) / (min(ROI, 6) + 4)\n'
              'Defaults: α 0.45, β 0.20, γ 0.15, δ 0.20, λ 10',
          explain: 'Weights are adjustable live on the results page. The penalty only applies when the family disagrees AND the career is far from the parents\' wishes.',
          color: PrismColors.roi,
        ),
        const SizedBox(height: 8),
        Text('Engine version $engineVersion', style: tt.bodySmall),
    ]);
  }
}

/// Honesty note and data sources, used on the About page.
class DataSourcesContent extends StatelessWidget {
  const DataSourcesContent({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    const sources = [
      ('PLFS (Periodic Labour Force Survey), MoSPI', 'Employment and wage levels by occupation and state'),
      ('NASSCOM reports', 'Technology workforce demand and emerging skills'),
      ('Naukri JobSpeak / job-portal indices', 'Monthly job-posting growth by sector (job velocity)'),
      ('WEF Future of Jobs report', 'Automation and AI exposure by role (disruption index)'),
      ('AISHE and NIRF', 'Institutions, seats, fees and rankings'),
      ('National Scholarship Portal and state portals', 'Scholarship rules and amounts'),
      ('Official exam websites (NTA, CoA, NID, NIFT, ICAI, UPSC)', 'Exam dates and eligibility'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('About the data', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Panel(
          accent: PrismColors.feasibility,
          child: Text(dataDisclaimer, style: tt.bodyLarge?.copyWith(height: 1.5)),
        ),
        const SectionTitle('Where production data would come from'),
        for (final s in sources)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              primary: false,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$1, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(s.$2, style: tt.bodyMedium),
              ]),
            ),
          ),
        const SectionTitle('Live data hook'),
        const Text('The JobMarketSource interface in lib/services/job_feed.dart is where a real job-postings feed plugs in. '
            'The demo uses a clearly labelled simulated feed.'),
        const SectionTitle('What is in this prototype'),
        Text('${app.seed?.careers.length ?? 0} careers, ${app.seed?.exams.length ?? 0} entrance exams, '
            '${app.seed?.scholarships.length ?? 0} scholarship schemes, ${app.seed?.regions.length ?? 0} job hubs, '
            '${(app.seed?.localIndustries.length ?? 1) - 1} districts with local industry profiles.'),
    ]);
  }
}
