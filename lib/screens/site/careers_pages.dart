import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../engine/format.dart';
import '../../engine/labels.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/interactions.dart';
import '../../widgets/motion.dart';
import '../../widgets/site_shell.dart';

// ---------------------------------------------------------------------------
// /careers
// ---------------------------------------------------------------------------

class CareersPage extends StatefulWidget {
  const CareersPage({super.key});
  @override
  State<CareersPage> createState() => _CareersPageState();
}

class _CareersPageState extends State<CareersPage> {
  CareerCluster? _cluster;
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
        _cluster = null;
        _query = '';
        _search.clear();
      });

  @override
  Widget build(BuildContext context) {
    final seed = context.watch<AppState>().seed;
    if (seed == null) return const Scaffold(body: PageSkeleton());
    final q = _query.trim().toLowerCase();
    final list = seed.careers
        .where((c) => _cluster == null || c.cluster == _cluster)
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.summary.toLowerCase().contains(q))
        .toList();
    final clusters = CareerCluster.values.where((cl) => seed.careers.any((c) => c.cluster == cl)).toList();

    return SiteScaffold(sections: [
      SiteSection(
        tight: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MaskedTextReveal(text: 'Explore ${seed.careers.length} careers.', style: statementStyle(context)),
          const SizedBox(height: Spacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text('Salaries, routes and demand for every career PRISM scores. Take the quiz to see how each one fits you.',
                style: leadStyle(context)),
          ),
          const SizedBox(height: Spacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search careers'),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Wrap(spacing: Spacing.sm, runSpacing: Spacing.sm, children: [
            ChoiceChip(label: const Text('All'), selected: _cluster == null, onSelected: (_) => setState(() => _cluster = null)),
            for (final cl in clusters)
              ChoiceChip(label: Text(clusterLabel(cl)), selected: _cluster == cl, onSelected: (_) => setState(() => _cluster = cl)),
          ]),
        ]),
      ),
      SiteSection(
        tight: true,
        child: list.isEmpty
            ? EmptyState(
                icon: Icons.search_off,
                title: 'No careers match',
                message: 'Try a different word or show every field.',
                actionLabel: 'Show all careers',
                onAction: _reset,
              )
            : LayoutBuilder(builder: (context, box) {
                final cols = box.maxWidth > 1100 ? 4 : box.maxWidth > 800 ? 3 : box.maxWidth > 520 ? 2 : 1;
                final w = (box.maxWidth - (cols - 1) * Spacing.lg) / cols;
                return Wrap(
                  key: ValueKey('${_cluster?.name}|$q'),
                  spacing: Spacing.lg,
                  runSpacing: Spacing.lg,
                  children: [
                    for (var i = 0; i < list.length; i++)
                      SizedBox(
                        width: w,
                        child: Reveal(
                          delay: Duration(milliseconds: math.min<int>(i, 12) * 40),
                          child: _CareerCard(career: list[i], showDetails: cols == 1),
                        ),
                      ),
                  ],
                );
              }),
      ),
    ]);
  }
}

class _CareerCard extends StatefulWidget {
  final Career career;
  final bool showDetails; // phones have no hover, so details are always shown there
  const _CareerCard({required this.career, required this.showDetails});

  @override
  State<_CareerCard> createState() => _CareerCardState();
}

class _CareerCardState extends State<_CareerCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final c = widget.career;
    final still = reduceMotion(context);
    final show = _hover || widget.showDetails;
    return CursorTarget(
      label: 'Open',
      child: MouseRegion(
        opaque: false,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedSlide(
          duration: still ? Duration.zero : const Duration(milliseconds: 220),
          offset: _hover && !still ? const Offset(0, -0.02) : Offset.zero,
          child: TiltCard(
            maxTiltDegrees: 4,
            semanticLabel: c.name,
            onTap: () => context.go('/careers/${c.id}'),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(clusterLabel(c.cluster), style: tt.labelMedium)),
                  if (c.emerging) Text('Emerging', style: tt.labelMedium?.copyWith(color: PrismColors.market)),
                ]),
                const SizedBox(height: Spacing.sm),
                Text(c.name, style: tt.titleLarge),
                const SizedBox(height: Spacing.sm),
                Text(c.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.bodyMedium),
                AnimatedSize(
                  duration: still ? Duration.zero : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: show
                      ? Padding(
                          padding: const EdgeInsets.only(top: Spacing.md),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Starts around ${inr(c.startingSalaryINR)} a year', style: tt.labelLarge),
                            const SizedBox(height: 2),
                            Text('Job postings growing about ${c.market.jobVelocity.round()}% a year', style: tt.bodySmall),
                          ]),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// /careers/:id
// ---------------------------------------------------------------------------

class CareerDetailPage extends StatelessWidget {
  final String id;
  const CareerDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final seed = context.watch<AppState>().seed;
    if (seed == null) return const Scaffold(body: PageSkeleton());
    final c = seed.careerById[id];
    final tt = Theme.of(context).textTheme;
    if (c == null) {
      return SiteScaffold(sections: [
        SiteSection(
          child: EmptyState(
            icon: Icons.work_off_outlined,
            title: 'Career not found',
            message: 'This link does not match any career in PRISM.',
            actionLabel: 'Browse all careers',
            onAction: () => context.go('/careers'),
          ),
        ),
      ]);
    }
    final demand = [
      for (final r in seed.regions) RegionDemand(r, c.market.regionalDemand[r.id] ?? 0, true),
    ]..sort((a, b) => b.demand.compareTo(a.demand));
    final examIds = <String>{...c.relatedExamIds, for (final r in c.routes) ...r.entryExamIds}.toList();
    final wide = isWide(context);

    final salary = GlassPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Salary path', style: tt.titleLarge),
        const SizedBox(height: Spacing.xs),
        Text('Typical yearly salary (illustrative)', style: tt.bodySmall),
        const SizedBox(height: Spacing.lg),
        SizedBox(height: 200, child: _SalaryChart(career: c)),
      ]),
    );
    final demandPanel = GlassPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Where the jobs are', style: tt.titleLarge),
        const SizedBox(height: Spacing.md),
        DemandMap(demand: demand, showRange: false),
      ]),
    );

    return SiteScaffold(sections: [
      SiteSection(
        tight: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HoverLink(label: 'All careers', arrow: false, style: tt.labelLarge, onTap: () => context.go('/careers')),
          const SizedBox(height: Spacing.lg),
          Wrap(spacing: Spacing.sm, runSpacing: Spacing.sm, children: [
            Chip(label: Text(clusterLabel(c.cluster))),
            if (c.emerging) const Chip(label: Text('Emerging field')),
          ]),
          const SizedBox(height: Spacing.md),
          MaskedTextReveal(text: c.name, style: statementStyle(context)),
          const SizedBox(height: Spacing.lg),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: Text(c.summary, style: leadStyle(context))),
          const SizedBox(height: Spacing.xl),
          Wrap(spacing: Spacing.xxl, runSpacing: Spacing.lg, children: [
            _Fact(label: 'Starting salary', value: inr(c.startingSalaryINR)),
            _Fact(label: 'Job postings growth', value: '${c.market.jobVelocity.round()}% a year'),
            _Fact(label: 'Automation exposure', value: pct(c.market.disruptionIndex)),
          ]),
        ]),
      ),
      SiteSection(
        tight: true,
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: salary),
                const SizedBox(width: Spacing.lg),
                Expanded(child: demandPanel),
              ])
            : Column(children: [salary, const SizedBox(height: Spacing.lg), demandPanel]),
      ),
      SiteSection(
        tight: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ways to get there', style: statementStyle(context, max: 44, min: 28, factor: 0.032)),
          const SizedBox(height: Spacing.lg),
          for (final r in c.routes)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Reveal(
                child: GlassPanel(
                  primary: false,
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.label, style: tt.titleMedium),
                        const SizedBox(height: 2),
                        Text('${tierLabel(r.tier)}, ${r.years} year${r.years == 1 ? '' : 's'}', style: tt.bodySmall),
                      ]),
                    ),
                    const SizedBox(width: Spacing.md),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(inr(r.totalCostINR), style: displayFont(tt.titleLarge!).copyWith(fontFeatures: tabularFigures)),
                      Text('total, illustrative', style: tt.bodySmall),
                    ]),
                  ]),
                ),
              ),
            ),
        ]),
      ),
      if (examIds.isNotEmpty)
        SiteSection(
          tight: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Entrance exams', style: statementStyle(context, max: 44, min: 28, factor: 0.032)),
            const SizedBox(height: Spacing.sm),
            Text('Usual months only. Verify dates on the official website.', style: tt.bodySmall),
            const SizedBox(height: Spacing.lg),
            Wrap(spacing: Spacing.md, runSpacing: Spacing.md, children: [
              for (final id in examIds)
                if (seed.examById[id] != null)
                  SizedBox(
                    width: 280,
                    child: GlassPanel(
                      primary: false,
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(seed.examById[id]!.name, style: tt.titleMedium),
                        const SizedBox(height: 2),
                        Text(seed.examById[id]!.conductingBody, style: tt.bodySmall),
                        const SizedBox(height: Spacing.sm),
                        Text('Usually ${seed.examById[id]!.typicalMonths.join(', ')}', style: tt.bodyMedium),
                      ]),
                    ),
                  ),
            ]),
          ]),
        ),
      SiteSection(
        tight: true,
        child: Wrap(spacing: Spacing.xl, runSpacing: Spacing.md, crossAxisAlignment: WrapCrossAlignment.center, children: [
          MagneticButton(
            child: CursorTarget(
              label: 'Start',
              child: FilledButton(onPressed: () => context.push('/student'), child: const Text('See how this fits you')),
            ),
          ),
          Text('All figures on this page are illustrative demo data.', style: tt.bodySmall),
        ]),
      ),
    ]);
  }
}

class _Fact extends StatelessWidget {
  final String label, value;
  const _Fact({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: displayFont(tt.headlineSmall!).copyWith(fontFeatures: tabularFigures)),
      Text(label, style: tt.bodySmall),
    ]);
  }
}

/// Start, year 5 and year 10 salaries as a line that draws itself in.
class _SalaryChart extends StatelessWidget {
  final Career career;
  const _SalaryChart({required this.career});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium ?? const TextStyle();
    return Semantics(
      label: 'Salary rises from ${inr(career.startingSalaryINR)} at the start to ${inr(career.year5SalaryINR)} '
          'after 5 years and ${inr(career.year10SalaryINR)} after 10 years.',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          size: Size.infinite,
          painter: _SalaryPainter(
            values: [career.startingSalaryINR.toDouble(), career.year5SalaryINR.toDouble(), career.year10SalaryINR.toDouble()],
            labels: const ['Start', 'Year 5', 'Year 10'],
            progress: t,
            grid: Theme.of(context).colorScheme.onSurface,
            textStyle: style,
          ),
        ),
      ),
    );
  }
}

class _SalaryPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double progress;
  final Color grid;
  final TextStyle textStyle;
  _SalaryPainter({required this.values, required this.labels, required this.progress, required this.grid, required this.textStyle});

  void _text(Canvas canvas, String s, Offset at, {bool centre = true}) {
    final tp = TextPainter(text: TextSpan(text: s, style: textStyle), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, centre ? at - Offset(tp.width / 2, 0) : at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 36.0, padTop = 28.0, padBottom = 28.0;
    final maxV = values.reduce((a, b) => a > b ? a : b) * 1.1;
    final w = size.width - padX * 2, h = size.height - padTop - padBottom;
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(padX + w * i / (values.length - 1), padTop + h * (1 - values[i] / maxV)),
    ];
    final base = padTop + h;
    canvas.drawLine(Offset(padX, base), Offset(padX + w, base), Paint()..color = grid.fade(0.15));

    if (progress <= 0.001) return;

    // Line draws in from left to right.
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);
    final area = Path.from(drawn)
      ..lineTo(metric.getTangentForOffset(metric.length * progress)?.position.dx ?? pts.first.dx, base)
      ..lineTo(pts.first.dx, base)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [PrismColors.roi.fade(0.25), PrismColors.roi.fade(0)])
            .createShader(Rect.fromLTWH(0, padTop, size.width, h)),
    );
    canvas.drawPath(drawn, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = PrismColors.roi);

    for (var i = 0; i < pts.length; i++) {
      final visible = progress >= i / (pts.length - 1) - 0.001;
      if (!visible) continue;
      canvas.drawCircle(pts[i], 5, Paint()..color = PrismColors.roi);
      _text(canvas, inr(values[i]), pts[i] - const Offset(0, 24));
      _text(canvas, labels[i], Offset(pts[i].dx, base + 8));
    }
  }

  @override
  bool shouldRepaint(_SalaryPainter old) => old.progress != progress || old.values != values;
}
