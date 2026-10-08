import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../engine/engine.dart';
import '../../engine/format.dart';
import '../../engine/labels.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/interactions.dart';
import '../../widgets/motion.dart';
import '../../widgets/site_shell.dart';
import '../info_screens.dart';

/// Text on the left, a live preview built from real widgets on the right (stacked on phones).
class _Feature extends StatelessWidget {
  final String title, body;
  final Widget preview;
  final bool flip;
  const _Feature({required this.title, required this.body, required this.preview, this.flip = false});

  @override
  Widget build(BuildContext context) {
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: statementStyle(context, max: 48, min: 28, factor: 0.035)),
      const SizedBox(height: Spacing.md),
      Text(body, style: leadStyle(context)),
    ]);
    final content = isWide(context)
        ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (!flip) Expanded(child: text) else Expanded(child: preview),
            const SizedBox(width: Spacing.xxl),
            if (!flip) Expanded(child: preview) else Expanded(child: text),
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [text, const SizedBox(height: Spacing.xl), preview]);
    return SiteSection(tight: true, child: Reveal(child: content));
  }
}

Widget _callToAction(BuildContext context, String label, String path, {String? secondaryLabel, String? secondaryPath}) => SiteSection(
      tight: true,
      child: Wrap(spacing: Spacing.xl, runSpacing: Spacing.md, crossAxisAlignment: WrapCrossAlignment.center, children: [
        MagneticButton(
          child: CursorTarget(
            label: 'Start',
            child: FilledButton(onPressed: () => context.push(path), child: Text(label)),
          ),
        ),
        if (secondaryLabel != null && secondaryPath != null)
          HoverLink(label: secondaryLabel, onTap: () => context.go(secondaryPath)),
      ]),
    );

// ---------------------------------------------------------------------------
// /parents
// ---------------------------------------------------------------------------

class ParentsPage extends StatefulWidget {
  const ParentsPage({super.key});
  @override
  State<ParentsPage> createState() => _ParentsPageState();
}

class _ParentsPageState extends State<ParentsPage> {
  EngineResult? _example; // Priya's family, computed by the real engine
  String _exampleName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final seed = context.read<AppState>().seed;
    if (_example == null && seed != null && seed.personas.isNotEmpty) {
      final p = seed.personas.first;
      _exampleName = p.student.name;
      _example = runEngine(student: p.student, parent: p.parent, seed: seed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seed = context.watch<AppState>().seed;
    final tt = Theme.of(context).textTheme;
    final r = _example;
    if (seed == null || r == null) return const Scaffold(body: PageSkeleton());
    final top = r.rankings.first;
    final f = top.finance.best;
    final cost = f.totalCostINR <= 0 ? 1 : f.totalCostINR;
    final c = r.conflict;

    return SiteScaffold(sections: [
      SiteSection(
        tight: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MaskedTextReveal(text: 'Parents decide too. PRISM makes that part of the plan.', style: statementStyle(context)),
          const SizedBox(height: Spacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'You answer a few questions on your own phone or your child\'s, linked by a six-letter family code. '
              'The examples below are the real results for $_exampleName, one of our demo families.',
              style: leadStyle(context),
            ),
          ),
        ]),
      ),
      _Feature(
        title: 'See what a path really costs',
        body: 'For every career, PRISM checks each route: government college, private college, online, or diploma first. '
            'It adds up your savings, likely scholarships (counted at half, because they are not guaranteed) and a loan '
            'whose monthly payment stays manageable, then picks the cheapest route that works.',
        preview: GlassPanel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${top.career.name}: ${f.label}', style: tt.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text('Total cost about ${inr(f.totalCostINR)}', style: tt.bodySmall),
            const SizedBox(height: Spacing.md),
            MetricBar(label: 'Savings', value: f.savingsINR / cost, color: PrismColors.market, valueText: inr(f.savingsINR)),
            MetricBar(label: 'Scholarships', value: f.scholarshipINR / cost, color: PrismColors.fit, valueText: inr(f.scholarshipINR)),
            MetricBar(label: 'Manageable loan', value: f.loanCapacityINR / cost, color: PrismColors.roi, valueText: inr(f.loanCapacityINR)),
            MetricBar(label: 'Covered', value: f.feasibility, color: f.viable ? PrismColors.market : PrismColors.penalty),
          ]),
        ),
      ),
      if (c != null)
        _Feature(
          flip: true,
          title: 'Know where you agree',
          body: 'The family alignment score compares your hopes with your child\'s: the careers you each picked, '
              'comfort with risk, salary expectations, and how far and how soon. ${bandLabel(c.band)} here, '
              'so PRISM looks for bridge careers that suit both of you.',
          preview: GlassPanel(
            child: Column(children: [
              ScoreGauge(value: c.psci100, label: 'Family gap', color: c.psci100 > 50 ? PrismColors.penalty : PrismColors.market, size: 170),
              const SizedBox(height: Spacing.lg),
              for (final b in c.bridgeCareers)
                MetricBar(label: b.career.name, value: b.combined, color: PrismColors.fit),
              const SizedBox(height: Spacing.xs),
              Text('Bridge careers: good for the student and close to the parents\' wishes', style: tt.bodySmall),
            ]),
          ),
        ),
      _Feature(
        title: 'Your family\'s details stay private',
        body: 'Income, savings and eligibility answers stay on the device you use. Category and disability questions are optional '
            'and are only used to match scholarships. Nothing is sent to a server for scoring.',
        preview: GlassPanel(
          child: Row(children: [
            const Icon(Icons.lock_outline, size: 40, color: PrismColors.market),
            const SizedBox(width: Spacing.lg),
            Expanded(child: Text('Scoring runs on the device. The optional AI chat only sees the computed results.', style: tt.bodyLarge)),
          ]),
        ),
      ),
      _callToAction(context, 'I have a family code', '/parent', secondaryLabel: 'How the scores work', secondaryPath: '/how-it-works'),
    ]);
  }
}

// ---------------------------------------------------------------------------
// /schools
// ---------------------------------------------------------------------------

class SchoolsPage extends StatelessWidget {
  const SchoolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final seed = context.watch<AppState>().seed;
    final preview = GlassPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('What the dashboard shows', style: tt.titleMedium),
        const SizedBox(height: Spacing.md),
        for (final line in const [
          'Average interest and aptitude profile of the class',
          'The most common top career matches',
          'How many families disagree, and how strongly',
          'The skill gaps shared by the most students',
          'How many top choices need financial aid',
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.check, size: 18, color: PrismColors.market)),
              const SizedBox(width: Spacing.sm),
              Expanded(child: Text(line, style: tt.bodyLarge)),
            ]),
          ),
      ]),
    );
    return SiteScaffold(sections: [
      SiteSection(
        tight: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MaskedTextReveal(text: 'See a whole class at once.', style: statementStyle(context)),
          const SizedBox(height: Spacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'When students and parents use PRISM, counsellors get a cohort view that shows where to spend their time: '
              'which workshops would help most, and which families may need a conversation.',
              style: leadStyle(context),
            ),
          ),
        ]),
      ),
      _Feature(
        title: 'Plan workshops around real gaps',
        body: 'The dashboard runs the same engine for every student and adds the results up. '
            'Until real submissions arrive, it uses a simulated class of 60 students, and says so on the page.',
        preview: preview,
      ),
      _Feature(
        flip: true,
        title: 'Built for Indian schools',
        body: 'Covers ${seed?.careers.length ?? 40} careers, ${seed?.exams.length ?? 15} entrance exams and '
            '${seed?.scholarships.length ?? 11} scholarship schemes, with local industry ideas for districts across Tamil Nadu.',
        preview: GlassPanel(
          child: Wrap(spacing: Spacing.xxl, runSpacing: Spacing.lg, children: [
            for (final (value, label) in [
              (seed?.careers.length ?? 0, 'Careers'),
              (seed?.exams.length ?? 0, 'Entrance exams'),
              (seed?.scholarships.length ?? 0, 'Scholarships'),
            ])
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedNumber(value: value.toDouble(), style: tt.displaySmall),
                Text(label, style: tt.bodySmall),
              ]),
          ]),
        ),
      ),
      _callToAction(context, 'Open the school dashboard', '/admin'),
    ]);
  }
}

// ---------------------------------------------------------------------------
// /about (methodology + data sources)
// ---------------------------------------------------------------------------

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SiteScaffold(sections: [
      SiteSection(
        tight: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MaskedTextReveal(text: 'Every score is a formula you can read.', style: statementStyle(context)),
          const SizedBox(height: Spacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text('This page shows how PRISM calculates every number, and where the data comes from.', style: leadStyle(context)),
          ),
        ]),
      ),
      const SiteSection(tight: true, maxWidth: 860, child: MethodologyContent()),
      SiteSection(
        tight: true,
        maxWidth: 860,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('About the data', style: tt.headlineSmall),
          const SizedBox(height: Spacing.md),
          const DataSourcesContent(),
        ]),
      ),
    ]);
  }
}
