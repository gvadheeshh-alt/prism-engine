import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/interactions.dart';
import '../../widgets/motion.dart';
import '../../widgets/site_shell.dart';

class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  static const _stages = [
    (
      'Ingest',
      'Two people, one family code.',
      'The student answers 26 statements about interests and work style, 9 "which would you rather do?" choices, 11 timed puzzles and 5 self-ratings. '
          'A parent separately shares income, savings, how much loan feels safe, appetite for risk, and the careers they hope for.',
    ),
    (
      'Solve',
      'Four honest checks for every career.',
      'Fit asks two questions: does the career match what the student enjoys, and are they ready for it? The cost check finds the cheapest route '
          'the family can really afford, counting savings, likely scholarships and a safe loan. The agreement score measures '
          'how far apart parent and student are, and the market check looks at job growth, automation risk and demand nearby.',
    ),
    (
      'Synthesise',
      'One score, one plan.',
      'The four checks are blended into a PRISM score using weights the family can change. The result is a ranked list, '
          'bridge careers that suit both sides, a year-by-year roadmap with exams and scholarships, and project ideas from local industries.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final labels = [app.t('fit'), app.t('market'), app.t('feasibility'), app.t('roi'), app.t('conflict')];
    final wide = isWide(context);
    return SiteScaffold(sections: [
      SiteSection(
        tight: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MaskedTextReveal(text: 'How PRISM turns answers into a plan.', style: statementStyle(context)),
          const SizedBox(height: Spacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text('Every score comes from a fixed formula, not a black box. Here is the whole method in three steps.',
                style: leadStyle(context)),
          ),
        ]),
      ),
      for (var i = 0; i < _stages.length; i++)
        SiteSection(
          tight: true,
          child: Reveal(child: _StageBlock(index: i, stage: _stages[i])),
        ),
      SiteSection(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Try the weights yourself', style: statementStyle(context, max: 56, min: 30, factor: 0.045)),
          const SizedBox(height: Spacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text('This is a sample career, not real data. Move the sliders to see how a family\'s priorities change the score.',
                style: leadStyle(context)),
          ),
          const SizedBox(height: Spacing.xl),
          const _WeightsDemo(),
        ]),
      ),
      SiteSection(
        tight: true,
        child: Center(child: Prism3DHero(labels: labels, aspectRatio: wide ? 2.4 : 1.6)),
      ),
      SiteSection(
        tight: true,
        child: Wrap(spacing: Spacing.xl, runSpacing: Spacing.md, crossAxisAlignment: WrapCrossAlignment.center, children: [
          MagneticButton(
            child: CursorTarget(
              label: 'Start',
              child: FilledButton(onPressed: () => context.push('/student'), child: const Text('Start the assessment')),
            ),
          ),
          HoverLink(label: 'Read every formula', onTap: () => context.go('/about')),
        ]),
      ),
    ]);
  }
}

/// Five sliders updating a sample spectrum bar and score, using the same composite formula as the engine.
class _WeightsDemo extends StatefulWidget {
  const _WeightsDemo();
  @override
  State<_WeightsDemo> createState() => _WeightsDemoState();
}

class _WeightsDemoState extends State<_WeightsDemo> {
  // A sample career: good fit, average market, affordable, modest return, some family disagreement.
  static const _fit = 0.82, _market = 0.58, _feasibility = 0.74, _roi = 0.55, _psci = 50.0, _alignment = 0.4;
  ScoreWeights _w = const ScoreWeights();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final sum = _w.sum <= 0 ? 1.0 : _w.sum;
    final penalty = _w.lambda * (_psci / 100) * (1 - _alignment);
    final score = (100 * (_w.alpha * _fit + _w.beta * _market + _w.gamma * _feasibility + _w.delta * _roi) / sum - penalty)
        .clamp(0.0, 100.0);
    final comps = ScoreComponents(fit: _fit, market: _market, feasibility: _feasibility, roiNorm: _roi, conflictPenalty: penalty);

    Widget slider(String label, double value, Color color, ValueChanged<double> onChanged, {double max = 1}) => Row(children: [
          SizedBox(width: 130, child: Text(label, style: tt.bodyMedium)),
          Expanded(
            child: Slider(value: value, max: max, divisions: max == 1 ? 20 : 30, activeColor: color, label: value.toStringAsFixed(2), onChanged: onChanged),
          ),
        ]);

    final controls = Column(children: [
      slider(app.t('fit'), _w.alpha, PrismColors.fit, (v) => setState(() => _w = _w.copyWith(alpha: v))),
      slider(app.t('market'), _w.beta, PrismColors.market, (v) => setState(() => _w = _w.copyWith(beta: v))),
      slider(app.t('feasibility'), _w.gamma, PrismColors.feasibility, (v) => setState(() => _w = _w.copyWith(gamma: v))),
      slider(app.t('roi'), _w.delta, PrismColors.roi, (v) => setState(() => _w = _w.copyWith(delta: v))),
      slider(app.t('penalty'), _w.lambda, PrismColors.penalty, (v) => setState(() => _w = _w.copyWith(lambda: v)), max: 30),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(onPressed: () => setState(() => _w = const ScoreWeights()), child: const Text('Reset weights')),
      ),
    ]);
    final preview = GlassPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: ScoreGauge(value: score, label: 'Sample PRISM score', size: 170)),
        const SizedBox(height: Spacing.lg),
        SpectrumBar(c: comps, w: _w, height: 16),
        const SizedBox(height: Spacing.sm),
        const SpectrumLegend(),
      ]),
    );
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth > 820) {
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: controls),
          const SizedBox(width: Spacing.xxl),
          Expanded(child: preview),
        ]);
      }
      return Column(children: [preview, const SizedBox(height: Spacing.lg), controls]);
    });
  }
}

class _StageBlock extends StatelessWidget {
  final int index;
  final (String, String, String) stage;
  const _StageBlock({required this.index, required this.stage});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final number = Text('${index + 1}', style: statementStyle(context, max: 96, min: 56).copyWith(color: PrismColors.spectrum[index]));
    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(stage.$1, style: tt.titleLarge?.copyWith(color: PrismColors.spectrum[index])),
      const SizedBox(height: Spacing.sm),
      Text(stage.$2, style: statementStyle(context, max: 48, min: 28, factor: 0.035)),
      const SizedBox(height: Spacing.md),
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Text(stage.$3, style: leadStyle(context))),
    ]);
    if (isWide(context)) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 140, child: number),
        const SizedBox(width: Spacing.xl),
        Expanded(child: body),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [number, const SizedBox(height: Spacing.sm), body]);
  }
}
