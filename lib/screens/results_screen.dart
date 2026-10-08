import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../engine/format.dart';
import '../engine/labels.dart';
import '../models/models.dart';
import '../services/pdf_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/career_constellation.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/site_shell.dart';
import '../widgets/motion.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _Section {
  final String label;
  final IconData icon;
  const _Section(this.label, this.icon);
}

const _sections = [
  _Section('Overview', Icons.dashboard_outlined),
  _Section('Careers', Icons.format_list_numbered),
  _Section('Money', Icons.account_balance_wallet_outlined),
  _Section('Family', Icons.family_restroom_outlined),
  _Section('Roadmap', Icons.route_outlined),
  _Section('Local ideas', Icons.lightbulb_outline),
];

class _ResultsScreenState extends State<ResultsScreen> {
  final _scroll = ScrollController();
  final _keys = List.generate(_sections.length, (_) => GlobalKey());
  int _current = 0;
  bool _jumping = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_spy);
  }

  @override
  void dispose() {
    _scroll.removeListener(_spy);
    _scroll.dispose();
    super.dispose();
  }

  /// Highlights the rail item for whichever section is near the top of the screen.
  void _spy() {
    if (_jumping) return;
    var active = 0;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= 180) active = i;
    }
    if (active != _current) setState(() => _current = active);
  }

  Future<void> _goTo(int i) async {
    final ctx = _keys[i].currentContext;
    if (ctx == null) return;
    setState(() {
      _current = i;
      _jumping = true;
    });
    await Scrollable.ensureVisible(
      ctx,
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
    _jumping = false;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final r = app.result;
    final wide = MediaQuery.sizeOf(context).width >= Layout.railBreakpoint;

    Widget mark(int i, Widget child) => KeyedSubtree(key: _keys[i], child: child);

    final body = r == null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.insights_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.fade(0.4)),
                const SizedBox(height: Spacing.md),
                Text('No results yet', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Spacing.sm),
                const Text('Take the assessment, or open a demo family from the start page.', textAlign: TextAlign.center),
                const SizedBox(height: Spacing.lg),
                FilledButton(onPressed: () => context.go('/'), child: const Text('Go to the start page')),
              ]),
            ),
          )
        : PageBody(
            controller: _scroll,
            maxWidth: wide ? 1100 : 980,
            children: [
              mark(0, _Header(r: r)),
              _Hero(r: r),
              const SizedBox(height: Spacing.md),
              const _WhatIf(),
              SectionTitle('Career constellation',
                  subtitle: 'All ${r.rankings.length} careers placed by fit, job demand and affordability. Tap one to explore it.'),
              GlassPanel(
                padding: const EdgeInsets.all(Spacing.md),
                child: CareerConstellation(
                  rankings: r.rankings,
                  selectedId: app.selectedScore?.careerId,
                  onSelect: (id) {
                    app.selectCareer(id);
                    _goTo(2);
                  },
                ),
              ),
              mark(1, SectionTitle(app.t('rankings'), subtitle: 'Tap a career to explore it below.')),
              _Rankings(r: r),
              mark(2, _CareerDetail(r: r)),
              mark(3, SectionTitle(app.t('conflict'), subtitle: 'Parent–Student Conflict Index (PSCI)')),
              _ConflictPanel(r: r),
              SectionTitle(app.t('swot')),
              _SwotGrid(swot: r.swot),
              mark(4, SectionTitle(app.t('roadmap'), subtitle: 'For your top 3 careers')),
              _Roadmaps(r: r),
              mark(5, SectionTitle(app.t('hyperLocal'), subtitle: 'STEAM project ideas from industries in ${r.hyperLocalArea}')),
              _HyperLocal(r: r),
              const SizedBox(height: Spacing.xl),
              Text(r.disclaimer, style: Theme.of(context).textTheme.bodySmall),
            ],
          );

    return Scaffold(
      appBar: prismAppBar(
        context,
        title: 'Results',
        actions: [
          if (r != null) ...[
            IconButton(tooltip: app.t('parentView'), icon: const Icon(Icons.family_restroom_outlined), onPressed: () => context.push('/parent-view')),
            IconButton(tooltip: app.t('counselor'), icon: const Icon(Icons.chat_bubble_outline), onPressed: () => context.push('/counselor')),
            IconButton(tooltip: app.t('pdf'), icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: () => PdfService.shareReport(r)),
          ],
        ],
      ),
      body: (r != null && wide)
          ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              NavigationRail(
                selectedIndex: _current,
                onDestinationSelected: _goTo,
                labelType: NavigationRailLabelType.all,
                minWidth: 88,
                destinations: [
                  for (final sct in _sections)
                    NavigationRailDestination(icon: Icon(sct.icon), label: Text(sct.label)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ])
          : body,
    );
  }
}

class _Header extends StatelessWidget {
  final EngineResult r;
  const _Header({required this.r});
  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 6, children: [
          Text(r.student.name, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          Chip(label: Text('${app.t('familyCode')}: ${r.familyCode}'), visualDensity: VisualDensity.compact),
          Text('${levelLabel(r.student.context.level)}, ${r.student.context.district}', style: tt.bodyMedium),
        ]),
        if (r.parent == null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Panel(
              primary: false,
              accent: PrismColors.feasibility,
              child: Row(children: [
                const Expanded(child: Text('Parent details are missing, so affordability uses default assumptions and family alignment is skipped.')),
                TextButton(onPressed: () => context.push('/parent?code=${r.familyCode}'), child: Text(app.t('joinParent'))),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  final EngineResult r;
  const _Hero({required this.r});
  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final tt = Theme.of(context).textTheme;
    final top = r.rankings.first;
    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(app.t('topMatch'), style: tt.labelLarge?.copyWith(color: PrismColors.fit)),
      const SizedBox(height: 4),
      Text(top.career.name, style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
      const SizedBox(height: 4),
      Text(clusterLabel(top.career.cluster), style: tt.bodyMedium),
      const SizedBox(height: 10),
      Text(top.career.summary, style: tt.bodyLarge),
      if (top.flags.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final f in top.flags)
            Chip(
              label: Text(f),
              avatar: const Icon(Icons.warning_amber_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
        ]),
      ],
    ]);
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, box) {
          final gauge = ScoreGauge(value: top.prism100, label: app.t('prismScore'), size: 180);
          return box.maxWidth > 560
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: info), const SizedBox(width: 16), gauge])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, const SizedBox(height: 16), Center(child: gauge)]);
        }),
        const SizedBox(height: 16),
        SpectrumBar(c: top.components, w: r.weights, height: 14),
        const SizedBox(height: 8),
        Row(children: [
          const Expanded(child: SpectrumLegend()),
          TextButton(onPressed: () => showTraceSheet(context, top.career.name, top.traces), child: Text(app.t('how'))),
        ]),
      ]),
    );
  }
}

class _WhatIf extends StatelessWidget {
  const _WhatIf();
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final w = app.weights;
    Widget slider(String label, double value, Color color, ValueChanged<double> onChanged, {double max = 1}) => Row(children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: Slider(
              value: value,
              max: max,
              divisions: max == 1 ? 20 : 30,
              activeColor: color,
              label: value.toStringAsFixed(2),
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: 40, child: Text(value.toStringAsFixed(2), textAlign: TextAlign.right)),
        ]);
    return Panel(
      primary: false,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: const Icon(Icons.tune),
        title: Text(app.t('whatIf')),
        subtitle: const Text('Drag to see how the ranking changes when your family values things differently.'),
        children: [
          slider('${app.t('fit')} (α)', w.alpha, PrismColors.fit, (v) => app.setWeights(w.copyWith(alpha: v))),
          slider('${app.t('market')} (β)', w.beta, PrismColors.market, (v) => app.setWeights(w.copyWith(beta: v))),
          slider('${app.t('feasibility')} (γ)', w.gamma, PrismColors.feasibility, (v) => app.setWeights(w.copyWith(gamma: v))),
          slider('${app.t('roi')} (δ)', w.delta, PrismColors.roi, (v) => app.setWeights(w.copyWith(delta: v))),
          slider('${app.t('penalty')} (λ)', w.lambda, PrismColors.penalty, (v) => app.setWeights(w.copyWith(lambda: v)), max: 30),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(app.t('liveFeed')),
            subtitle: const Text('Job-posting growth updates every few seconds and the ranking re-scores live.'),
            value: app.liveFeed,
            onChanged: app.setLiveFeed,
          ),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: app.resetWeights, child: const Text('Reset to defaults'))),
        ],
      ),
    );
  }
}

class _Rankings extends StatelessWidget {
  final EngineResult r;
  const _Rankings({required this.r});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final selected = app.selectedScore?.careerId;
    Widget content(CareerScore s, int rank, {required bool compact}) => Padding(
          padding: EdgeInsets.fromLTRB(Spacing.lg, compact ? Spacing.xs : Spacing.md, Spacing.xs, compact ? Spacing.xs : Spacing.md),
          child: Row(children: [
            SizedBox(
              width: compact ? 32 : 40,
              child: Text('$rank', style: displayFont(compact ? tt.titleSmall! : tt.headlineSmall!).copyWith(fontFeatures: tabularFigures)),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(s.career.name,
                        style: (compact ? tt.bodyMedium : tt.titleMedium)?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  ),
                  if (s.career.emerging)
                    Padding(padding: const EdgeInsets.only(right: Spacing.sm), child: Text('emerging', style: tt.labelSmall?.copyWith(color: PrismColors.market))),
                  if (s.flags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: Spacing.sm),
                      child: Tooltip(message: s.flags.join('\n'), child: const Icon(Icons.warning_amber_rounded, size: 16)),
                    ),
                  AnimatedNumber(value: s.prism100, style: compact ? tt.titleSmall : tt.titleLarge),
                ]),
                if (!compact) ...[const SizedBox(height: Spacing.sm), SpectrumBar(c: s.components, w: r.weights)],
              ]),
            ),
            IconButton(
              tooltip: app.t('how'),
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () => showTraceSheet(context, s.career.name, s.traces),
            ),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < 5 && i < r.rankings.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: TiltCard(
            radius: Radii.nested + 2,
            maxTiltDegrees: 3,
            selected: r.rankings[i].careerId == selected,
            semanticLabel: 'Rank ${i + 1}: ${r.rankings[i].career.name}',
            onTap: () => app.selectCareer(r.rankings[i].careerId),
            child: content(r.rankings[i], i + 1, compact: false),
          ),
        ),
      Panel(
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text('Show all ${r.rankings.length} careers', style: tt.labelLarge),
          children: [
            for (var i = 5; i < r.rankings.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(Radii.nested),
                onTap: () => app.selectCareer(r.rankings[i].careerId),
                child: Container(
                  decoration: BoxDecoration(
                    color: r.rankings[i].careerId == selected ? PrismColors.fit.fade(0.10) : null,
                    borderRadius: BorderRadius.circular(Radii.nested),
                  ),
                  child: content(r.rankings[i], i + 1, compact: true),
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}

class _CareerDetail extends StatelessWidget {
  final EngineResult r;
  const _CareerDetail({required this.r});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.selectedScore!;
    final tt = Theme.of(context).textTheme;
    final left = Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(app.t('skills'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ProfileRadar(student: r.student.dims, requirement: s.career.requirement, careerName: s.career.name),
        const SizedBox(height: 12),
        Text('Biggest gaps', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        if (s.gaps.isEmpty) const Padding(padding: EdgeInsets.only(top: 6), child: Text('None. You already meet this profile.')),
        for (final g in s.gaps)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MetricBar(label: g.dimension.label, value: g.current, color: PrismColors.fit, valueText: '${pct(g.current)} / ${pct(g.required)}'),
              for (final a in g.actions.take(1)) Text('${a.label} (${a.resource})', style: tt.bodySmall),
            ]),
          ),
      ]),
    );
    final right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _FinancePanel(s: s),
      const SizedBox(height: 12),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(app.t('demand'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DemandMap(demand: s.demand),
        ]),
      ),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(s.career.name, subtitle: 'PRISM ${s.prism100.toStringAsFixed(0)} · ${clusterLabel(s.career.cluster)}'),
      LayoutBuilder(builder: (context, box) {
        if (box.maxWidth > 760) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 12), right]);
      }),
    ]);
  }
}

class _FinancePanel extends StatelessWidget {
  final CareerScore s;
  const _FinancePanel({required this.s});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final tt = Theme.of(context).textTheme;
    final best = s.finance.best;
    final cost = best.totalCostINR <= 0 ? 1 : best.totalCostINR;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(app.t('afford'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () => showTraceSheet(context, 'Financial Constraint Solver', [s.traces.last]),
          ),
        ]),
        Text('Best workable route: ${best.label}', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Total cost ${inr(best.totalCostINR)} over ${best.years} yr${best.years == 1 ? '' : 's'}. '
            'Return ${roiText(best.roi)} the cost; pays back in ${best.paybackYears == null ? 'over 10' : best.paybackYears!.toStringAsFixed(0)} working years.'),
        const SizedBox(height: 10),
        MetricBar(label: 'Savings', value: best.savingsINR / cost, color: PrismColors.market, valueText: inr(best.savingsINR)),
        MetricBar(label: 'Scholarships (expected)', value: best.scholarshipINR / cost, color: PrismColors.fit, valueText: inr(best.scholarshipINR)),
        MetricBar(label: 'Manageable loan', value: best.loanCapacityINR / cost, color: PrismColors.roi, valueText: inr(best.loanCapacityINR)),
        MetricBar(label: 'Covered', value: best.feasibility, color: best.viable ? PrismColors.market : PrismColors.penalty),
        const SizedBox(height: 10),
        Text('All routes', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        for (final rf in s.finance.allRoutes)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Icon(rf.viable ? Icons.check_circle_outline : Icons.cancel_outlined, size: 18, color: rf.viable ? PrismColors.market : PrismColors.penalty),
              const SizedBox(width: 8),
              Expanded(child: Text('${tierLabel(rf.tier)}: ${rf.label}', style: tt.bodySmall)),
              Text(inr(rf.totalCostINR), style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
        if (s.finance.scholarships.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Matched scholarships', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          for (final m in s.finance.scholarships.take(4))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${m.scholarship.name}: up to ${inr(m.scholarship.amountINR)}/yr. ${m.scholarship.note}', style: tt.bodySmall),
            ),
        ],
      ]),
    );
  }
}

class _ConflictPanel extends StatelessWidget {
  final EngineResult r;
  const _ConflictPanel({required this.r});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final tt = Theme.of(context).textTheme;
    final c = r.conflict;
    if (c == null) {
      return Panel(
        child: Row(children: [
          const Expanded(child: Text('Add parent details to see how closely your family\'s hopes match yours.')),
          TextButton(onPressed: () => context.push('/parent?code=${r.familyCode}'), child: Text(app.t('joinParent'))),
        ]),
      );
    }
    final color = switch (c.band) {
      ConflictBand.aligned => PrismColors.market,
      ConflictBand.mild => PrismColors.feasibility,
      ConflictBand.significant => PrismColors.penalty,
      ConflictBand.high => PrismColors.penalty,
    };
    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(bandLabel(c.band), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 8),
      MetricBar(label: 'Different career choices', value: c.preference, color: color),
      MetricBar(label: 'Risk appetite gap', value: c.risk, color: color),
      MetricBar(label: 'Salary expectation gap', value: c.salaryGap, color: color),
      MetricBar(label: 'Relocation / timeline', value: c.relocationTimeline, color: color),
      const SizedBox(height: 8),
      for (final d in c.drivers)
        Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $d', style: tt.bodyMedium)),
    ]);
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, box) {
          final gauge = ScoreGauge(value: c.psci100, label: 'PSCI', color: color, size: 130);
          return box.maxWidth > 560
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [gauge, const SizedBox(width: 20), Expanded(child: body)])
              : Column(children: [gauge, const SizedBox(height: 12), body]);
        }),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Text(app.t('bridge'), style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          IconButton(icon: const Icon(Icons.info_outline, size: 20), onPressed: () => showTraceSheet(context, 'Conflict index', [c.trace])),
        ]),
        Text('Careers that fit you well and are close to what your parents hope for.', style: tt.bodySmall),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, box) {
          final cols = box.maxWidth > 640 ? 3 : 1;
          final w = (box.maxWidth - (cols - 1) * Spacing.md) / cols;
          return Wrap(spacing: Spacing.md, runSpacing: Spacing.md, children: [
            for (final b in c.bridgeCareers)
              SizedBox(
                width: w,
                child: TiltCard(
                  radius: Radii.nested + 2,
                  maxTiltDegrees: 4,
                  selected: app.selectedScore?.careerId == b.career.id,
                  semanticLabel: 'Bridge career ${b.career.name}',
                  onTap: () => app.selectCareer(b.career.id),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.career.name, style: tt.titleMedium),
                      const SizedBox(height: Spacing.sm),
                      MetricBar(label: 'Fits the student', value: b.studentFit, color: PrismColors.fit),
                      MetricBar(label: 'Close to parents\' wishes', value: b.parentAlignment, color: PrismColors.market),
                    ]),
                  ),
                ),
              ),
          ]);
        }),
      ]),
    );
  }
}

class _SwotGrid extends StatelessWidget {
  final Swot swot;
  const _SwotGrid({required this.swot});
  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final tt = Theme.of(context).textTheme;
    Widget cell(String title, List<SwotItem> items, Color color) => TiltCard(
          maxTiltDegrees: 3,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: Spacing.sm),
                Text(title, style: tt.titleLarge),
              ]),
              const SizedBox(height: Spacing.sm),
              for (final i in items) Padding(padding: const EdgeInsets.only(top: Spacing.xs), child: Text(i.text, style: tt.bodyMedium)),
            ]),
          ),
        );
    final cells = [
      cell(app.t('strengths'), swot.strengths, PrismColors.market),
      cell(app.t('weaknesses'), swot.weaknesses, PrismColors.feasibility),
      cell(app.t('opportunities'), swot.opportunities, PrismColors.roi),
      cell(app.t('threats'), swot.threats, PrismColors.penalty),
    ];
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth < 600) {
        return Column(children: [for (final c in cells) Padding(padding: const EdgeInsets.only(bottom: 10), child: c)]);
      }
      return Column(children: [
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: cells[0]), const SizedBox(width: 10), Expanded(child: cells[1])])),
        const SizedBox(height: 10),
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: cells[2]), const SizedBox(width: 10), Expanded(child: cells[3])])),
      ]);
    });
  }
}

class _Roadmaps extends StatefulWidget {
  final EngineResult r;
  const _Roadmaps({required this.r});
  @override
  State<_Roadmaps> createState() => _RoadmapsState();
}

class _RoadmapsState extends State<_Roadmaps> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final maps = widget.r.roadmaps;
    if (maps.isEmpty) return const SizedBox.shrink();
    final i = tab.clamp(0, maps.length - 1);
    final m = maps[i];
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var k = 0; k < maps.length; k++)
            ChoiceChip(label: Text(maps[k].career.name), selected: k == i, onSelected: (_) => setState(() => tab = k)),
        ]),
        const SizedBox(height: 16),
        for (var k = 0; k < m.steps.length; k++)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: 28,
                child: Column(children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(color: PrismColors.spectrum[k % 4], shape: BoxShape.circle),
                  ),
                  if (k < m.steps.length - 1)
                    Expanded(child: Container(width: 2, color: Theme.of(context).colorScheme.onSurface.fade(0.12))),
                ]),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.steps[k].periodLabel, style: tt.labelMedium),
                    Text(m.steps[k].title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    for (final a in m.steps[k].actions) Padding(padding: const EdgeInsets.only(top: 3), child: Text('• $a', style: tt.bodyMedium)),
                  ]),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _HyperLocal extends StatelessWidget {
  final EngineResult r;
  const _HyperLocal({required this.r});
  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final tt = Theme.of(context).textTheme;
    final seed = app.seed!;
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth > 760 ? 3 : 1;
      final w = (box.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (final idea in r.hyperLocal)
          SizedBox(
            width: w,
            child: Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(idea.localIndustry, style: tt.labelMedium?.copyWith(color: PrismColors.market)),
                const SizedBox(height: 4),
                Text(idea.title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Problem: ${idea.problem}', style: tt.bodyMedium),
                const SizedBox(height: 6),
                Text('Uses your ${idea.strengthsUsed.map((d) => d.label.toLowerCase()).join(', ')} skills', style: tt.bodySmall),
                const SizedBox(height: 6),
                Text('Leads toward: ${idea.careerIds.map((id) => seed.careerById[id]?.name ?? id).join(', ')}', style: tt.bodySmall),
                const SizedBox(height: 8),
                MetricBar(label: 'Match', value: idea.matchScore, color: PrismColors.market),
              ]),
            ),
          ),
      ]);
    });
  }
}
