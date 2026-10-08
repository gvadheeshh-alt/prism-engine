import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../engine/engine.dart';
import '../../engine/labels.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/interactions.dart';
import '../../widgets/motion.dart';
import '../../widgets/site_shell.dart';

/// Home: a scroll story that teases each topic and links out to its own page.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.seed == null) return const Scaffold(body: PageSkeleton());
    final labels = [app.t('fit'), app.t('market'), app.t('feasibility'), app.t('roi'), app.t('conflict')];
    return SiteScaffold(sections: [
      _Hero(labels: labels),
      const _Problem(),
      _HowItWorksTeaser(labels: labels),
      const _InAction(),
      const _CareerTicker(),
      const _Audiences(),
    ]);
  }
}

// 1. Hero ---------------------------------------------------------------------

class _Hero extends StatelessWidget {
  final List<String> labels;
  const _Hero({required this.labels});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final statement = MaskedTextReveal(
      text: 'Career guidance that brings the whole family to the table.',
      style: statementStyle(context, max: 80, factor: 0.05),
      delay: const Duration(milliseconds: 200),
    );
    final lead = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Reveal(
        delay: const Duration(milliseconds: 700),
        child: Text(
          'A short quiz for the student, a few questions for a parent, and one honest plan with the maths behind every score.',
          style: leadStyle(context),
        ),
      ),
    );
    final cards = LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth > 620 ? 2 : 1;
      final w = (box.maxWidth - (cols - 1) * Spacing.lg) / cols;
      return Wrap(spacing: Spacing.lg, runSpacing: Spacing.lg, children: [
        SizedBox(
          width: w,
          child: _EntryCard(
            title: "I'm a student",
            body: 'Answer questions about what you enjoy and what you are good at.',
            onTap: () => context.push('/student'),
          ),
        ),
        SizedBox(
          width: w,
          child: _EntryCard(
            title: "I'm a parent",
            body: 'Add your budget and hopes using your child\'s family code.',
            onTap: () => context.push('/parent'),
          ),
        ),
      ]);
    });

    return SiteSection(
      tight: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [statement, const SizedBox(height: Spacing.xl), lead])),
            const SizedBox(width: Spacing.xl),
            Expanded(flex: 5, child: Prism3DHero(labels: labels, aspectRatio: 1.25)),
          ])
        else ...[
          statement,
          const SizedBox(height: Spacing.lg),
          lead,
          const SizedBox(height: Spacing.lg),
          Prism3DHero(labels: labels, aspectRatio: 1.6),
        ],
        const SizedBox(height: Spacing.xxl),
        Reveal(delay: const Duration(milliseconds: 900), child: cards),
      ]),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final String title, body;
  final VoidCallback onTap;
  const _EntryCard({required this.title, required this.body, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return CursorTarget(
      label: 'Start',
      child: TiltCard(
        maxTiltDegrees: 4,
        semanticLabel: title,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: tt.headlineSmall),
                const SizedBox(height: Spacing.sm),
                Text(body, style: tt.bodyMedium),
              ]),
            ),
            const SizedBox(width: Spacing.md),
            const Icon(Icons.arrow_forward, color: PrismColors.fit, size: 28),
          ]),
        ),
      ),
    );
  }
}

// 2. The problem ------------------------------------------------------------------

class _Problem extends StatelessWidget {
  const _Problem();

  @override
  Widget build(BuildContext context) {
    return SiteSection(
      maxWidth: 1000,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ScrollFillText(
          text: 'Most students in India choose a career without structured guidance. Parents pay for the choice, '
              'yet they are rarely part of the thinking. PRISM puts both at the same table.',
          style: statementStyle(context, max: 56, min: 30, factor: 0.045),
        ),
        const SizedBox(height: Spacing.xl),
        HoverLink(label: 'Why it matters for parents', onTap: () => context.go('/parents')),
      ]),
    );
  }
}

// 3. How it works (pinned, scroll-driven) ------------------------------------------------

class _HowItWorksTeaser extends StatelessWidget {
  final List<String> labels;
  const _HowItWorksTeaser({required this.labels});

  static const _steps = [
    ('Ingest', 'The student answers 51 questions, including puzzles. A parent adds budget, savings and hopes.'),
    ('Solve', 'PRISM checks fit, cost, family agreement and job demand for all 40 careers.'),
    ('Synthesise', 'You get a ranked list, a step-by-step plan, and the maths behind every score.'),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final wide = isWide(context);
    return PinnedScrollSection(
      scrollLength: 2.6,
      builder: (context, progress) {
        final active = (progress * 3).floor().clamp(0, 2);
        final steps = Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('How it works', style: tt.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.fade(0.6))),
          const SizedBox(height: Spacing.lg),
          for (var i = 0; i < _steps.length; i++)
            AnimatedOpacity(
              duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 300),
              opacity: i == active ? 1 : 0.3,
              child: Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xl),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 48,
                    child: Text('${i + 1}', style: displayFont(tt.headlineSmall!).copyWith(color: PrismColors.spectrum[i])),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_steps[i].$1, style: statementStyle(context, max: 40, min: 26, factor: 0.03)),
                      const SizedBox(height: Spacing.xs),
                      Text(_steps[i].$2, style: leadStyle(context)),
                    ]),
                  ),
                ]),
              ),
            ),
          HoverLink(label: 'See the full method', onTap: () => context.go('/how-it-works')),
        ]);
        final prism = Prism3DHero(labels: labels, storyProgress: progress, aspectRatio: wide ? 1.2 : 1.9);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 20, vertical: wide ? 88 : 72),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Layout.maxContent),
              child: wide
                  ? Row(children: [Expanded(child: prism), const SizedBox(width: Spacing.xxl), Expanded(child: steps)])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [prism, const SizedBox(height: Spacing.lg), Flexible(child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: steps))]),
            ),
          ),
        );
      },
    );
  }
}

// 4. See it in action (demo families) ----------------------------------------------------

class _InAction extends StatelessWidget {
  const _InAction();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final seed = app.seed!;
    final tt = Theme.of(context).textTheme;
    return SiteSection(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Reveal(child: Text('See it in action', style: statementStyle(context, max: 72))),
        const SizedBox(height: Spacing.md),
        Text('Three example families. Open one to explore their full results.', style: leadStyle(context)),
        const SizedBox(height: Spacing.xxl),
        LayoutBuilder(builder: (context, box) {
          final cols = box.maxWidth > 1000 ? 3 : (box.maxWidth > 640 ? 2 : 1);
          final w = (box.maxWidth - (cols - 1) * Spacing.lg) / cols;
          return Wrap(spacing: Spacing.lg, runSpacing: Spacing.lg, children: [
            for (var i = 0; i < seed.personas.length; i++)
              SizedBox(
                width: w,
                child: Reveal(
                  delay: Duration(milliseconds: 120 * i),
                  child: _FamilyCard(persona: seed.personas[i], textTheme: tt),
                ),
              ),
          ]);
        }),
      ]),
    );
  }
}

class _FamilyCard extends StatefulWidget {
  final Persona persona;
  final TextTheme textTheme;
  const _FamilyCard({required this.persona, required this.textTheme});

  @override
  State<_FamilyCard> createState() => _FamilyCardState();
}

class _FamilyCardState extends State<_FamilyCard> {
  EngineResult? _result;
  bool _hover = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final seed = context.read<AppState>().seed;
    if (_result == null && seed != null) {
      _result = runEngine(student: widget.persona.student, parent: widget.persona.parent, seed: seed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = widget.textTheme;
    final r = _result;
    final p = widget.persona;
    final still = reduceMotion(context);
    if (r == null) return const Skeleton(height: 320, radius: Radii.primary);
    final top = r.rankings.first;
    final tags = [
      levelLabel(p.student.context.level),
      p.student.context.district,
      if (r.conflict != null) bandLabel(r.conflict!.band),
    ];
    final outcome = r.conflict != null && r.conflict!.bridgeCareers.isNotEmpty && r.conflict!.psci100 > 50
        ? 'Bridge career found: ${r.conflict!.bridgeCareers.first.career.name}.'
        : 'Top match: ${top.career.name}.';

    return CursorTarget(
      label: 'Open',
      child: MouseRegion(
        opaque: false,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: TiltCard(
          maxTiltDegrees: 3,
          semanticLabel: 'Open demo results for ${p.title}',
          onTap: () {
            context.read<AppState>().loadPersona(p);
            context.push('/results');
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Preview built from real widgets with this family's real result.
            ClipRect(
              child: AnimatedScale(
                scale: _hover && !still ? 1.04 : 1,
                duration: still ? Duration.zero : const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                child: Container(
                  height: 190,
                  padding: const EdgeInsets.all(Spacing.lg),
                  color: Theme.of(context).colorScheme.onSurface.fade(0.03),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Center(child: ScoreGauge(value: top.prism100, label: 'PRISM score', size: 130)),
                    const SizedBox(height: Spacing.md),
                    SpectrumBar(c: top.components, w: r.weights),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: Spacing.sm, runSpacing: Spacing.sm, children: [
                  for (final t in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.pill),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.fade(0.16)),
                      ),
                      child: Text(t, style: tt.labelMedium),
                    ),
                ]),
                const SizedBox(height: Spacing.md),
                Text(p.title, style: tt.titleLarge),
                const SizedBox(height: Spacing.xs),
                Text(p.blurb, style: tt.bodyMedium),
                const SizedBox(height: Spacing.md),
                AnimatedOpacity(
                  duration: still ? Duration.zero : const Duration(milliseconds: 250),
                  opacity: _hover ? 1 : 0.7,
                  child: Text(outcome, style: tt.labelLarge?.copyWith(color: PrismColors.fit)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// 5. Career ticker --------------------------------------------------------------------

class _CareerTicker extends StatelessWidget {
  const _CareerTicker();

  @override
  Widget build(BuildContext context) {
    final seed = context.watch<AppState>().seed!;
    final style = statementStyle(context, max: 56, min: 28, factor: 0.04);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SiteSection(
        tight: true,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text('${seed.careers.length} careers, from AI to agritech', style: statementStyle(context, max: 56, min: 30, factor: 0.045))),
          const SizedBox(width: Spacing.lg),
          HoverLink(label: 'Explore all careers', onTap: () => context.go('/careers')),
        ]),
      ),
      SizedBox(
        height: (style.fontSize ?? 40) * 1.6,
        child: Marquee(children: [
          for (final c in seed.careers)
            CursorTarget(
              label: 'Open',
              child: InkWell(
                onTap: () => context.go('/careers/${c.id}'),
                borderRadius: BorderRadius.circular(Radii.nested),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  child: Text(c.name, style: style.copyWith(color: style.color?.fade(0.55))),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: Spacing.xl),
    ]);
  }
}

// 6. Parents and schools ---------------------------------------------------------------

class _Audiences extends StatelessWidget {
  const _Audiences();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    Widget block(String title, String body, String link, String path) => TiltCard(
          maxTiltDegrees: 3,
          semanticLabel: title,
          onTap: () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xxl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: statementStyle(context, max: 44, min: 28, factor: 0.032)),
              const SizedBox(height: Spacing.md),
              Text(body, style: leadStyle(context)),
              const SizedBox(height: Spacing.lg),
              HoverLink(label: link, style: tt.titleMedium, onTap: () => context.go(path)),
            ]),
          ),
        );
    return SiteSection(
      child: LayoutBuilder(builder: (context, box) {
        final cols = box.maxWidth > 760 ? 2 : 1;
        final w = (box.maxWidth - (cols - 1) * Spacing.lg) / cols;
        return Wrap(spacing: Spacing.lg, runSpacing: Spacing.lg, children: [
          SizedBox(
            width: w,
            child: Reveal(
              child: block('For parents', 'See what a path really costs, which loans are manageable, and where you and your child agree.',
                  'How PRISM helps parents', '/parents'),
            ),
          ),
          SizedBox(
            width: w,
            child: Reveal(
              delay: const Duration(milliseconds: 120),
              child: block('For schools', 'See a whole class at once: common interests, skill gaps and family disagreement.',
                  'How PRISM helps schools', '/schools'),
            ),
          ),
        ]);
      }),
    );
  }
}
