import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../engine/labels.dart';
import '../engine/math_utils.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'motion.dart';

/// Centres content and caps its width so pages read well on web and tablets.
class PageBody extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  final ScrollController? controller;
  const PageBody({super.key, required this.children, this.maxWidth = 980, this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, Spacing.xxxl),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

/// Glass surface: slightly lighter than the page, 1px hairline border, soft highlight along the top edge.
/// [primary] surfaces get more padding and a larger radius than nested ones.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final bool primary;
  final Color? accent;
  final EdgeInsetsGeometry? padding;
  const GlassPanel({super.key, required this.child, this.primary = true, this.accent, this.padding});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = primary ? Radii.primary : Radii.nested;
    final List<Color> fill = primary
        ? (dark ? [PrismColors.surfaceDarkHigh, PrismColors.surfaceDark] : [Colors.white, const Color(0xFFFAFBFE)])
        : [cs.onSurface.fade(dark ? 0.04 : 0.03), cs.onSurface.fade(dark ? 0.02 : 0.02)];
    return Container(
      padding: padding ?? EdgeInsets.all(primary ? Spacing.xl : Spacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: fill),
        border: Border.all(color: accent?.fade(0.55) ?? (dark ? Colors.white.fade(0.08) : cs.onSurface.fade(0.08))),
        boxShadow: [
          if (accent != null && dark) BoxShadow(color: accent!.fade(0.10), blurRadius: 24, spreadRadius: -6),
        ],
      ),
      foregroundDecoration: primary && dark
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: const Alignment(0, -0.6),
                colors: [Colors.white.fade(0.05), Colors.white.fade(0)],
              ),
            )
          : null,
      child: child,
    );
  }
}

/// Older name kept so every existing screen still compiles.
class Panel extends StatelessWidget {
  final Widget child;
  final bool primary;
  final Color? accent;
  final EdgeInsetsGeometry? padding;
  const Panel({super.key, required this.child, this.primary = true, this.accent, this.padding});

  @override
  Widget build(BuildContext context) =>
      GlassPanel(primary: primary, accent: accent, padding: padding, child: child);
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xxl + Spacing.sm, bottom: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: tt.headlineSmall),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: tt.bodyMedium?.copyWith(color: tt.bodyMedium?.color?.fade(0.7))),
                ),
            ]),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// The signature element: a score split into its five coloured contributions.
class SpectrumBar extends StatelessWidget {
  final ScoreComponents c;
  final ScoreWeights w;
  final double height;
  const SpectrumBar({super.key, required this.c, required this.w, this.height = 12});

  @override
  Widget build(BuildContext context) {
    final sum = w.sum <= 0 ? 1.0 : w.sum;
    final parts = [
      w.alpha * c.fit / sum,
      w.beta * c.market / sum,
      w.gamma * c.feasibility / sum,
      w.delta * c.roiNorm / sum,
    ];
    final penalty = (c.conflictPenalty / 100).clamp(0.0, 1.0);
    final used = parts.fold<double>(0, (a, b) => a + b);
    final track = Theme.of(context).colorScheme.onSurface.fade(0.07);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(builder: (context, box) {
          final wpx = box.maxWidth;
          // Segments draw in left to right the first time the bar appears.
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, grow, _) => Stack(children: [
              Container(color: track),
              Row(children: [
                for (var i = 0; i < 4; i++) Container(width: wpx * parts[i] * grow, color: PrismColors.spectrum[i]),
              ]),
              if (penalty > 0 && grow > 0.99)
                Positioned(
                  left: wpx * (used - penalty).clamp(0.0, 1.0),
                  width: wpx * penalty,
                  top: 0,
                  bottom: 0,
                  child: Container(color: PrismColors.penalty.fade(0.9)),
                ),
            ]),
          );
        }),
      ),
    );
  }
}

class SpectrumLegend extends StatelessWidget {
  const SpectrumLegend({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final keys = ['fit', 'market', 'feasibility', 'roi', 'penalty'];
    return Wrap(spacing: 14, runSpacing: 6, children: [
      for (var i = 0; i < 5; i++)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: PrismColors.spectrum[i], shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(app.t(keys[i]), style: Theme.of(context).textTheme.bodySmall),
        ]),
    ]);
  }
}

/// Semi-circular 0..100 gauge. The arc and the number both animate to new values.
class ScoreGauge extends StatelessWidget {
  final double value; // 0..100
  final String label;
  final Color color;
  final double size;
  const ScoreGauge({super.key, required this.value, required this.label, this.color = PrismColors.fit, this.size = 150});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Semantics(
      label: '$label ${value.round()} out of 100',
      child: SizedBox(
        width: size,
        height: size * 0.68,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value / 100),
          duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => CustomPaint(
            painter: _GaugePainter(v, color, cs.onSurface.fade(0.08)),
            child: child,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedNumber(value: value, style: tt.displaySmall?.copyWith(height: 1, fontSize: size * 0.24)),
              Text(label, style: tt.bodySmall),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double v;
  final Color color, track;
  _GaugePainter(this.v, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.width / 2), radius: size.width / 2 - stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, p..color = track);
    final sweep = math.pi * v.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    p.shader = SweepGradient(
      startAngle: math.pi,
      endAngle: math.pi + math.max<double>(sweep, 0.01),
      colors: [color.fade(0.55), color],
    ).createShader(rect);
    canvas.drawArc(rect, math.pi, sweep, false, p);
    // Thin highlight along the outer edge gives the ring a glassy, slightly 3D look.
    final hi = Rect.fromCircle(center: rect.center, radius: rect.width / 2 + stroke * 0.30);
    canvas.drawArc(
      hi,
      math.pi,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.16
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.fade(0.28),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.v != v || old.color != color || old.track != track;
}

/// Labelled horizontal bar (0..1).
class MetricBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String? valueText;
  const MetricBar({super.key, required this.label, required this.value, required this.color, this.valueText});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 150, child: Text(label, style: tt.bodySmall, overflow: TextOverflow.ellipsis)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: clamp01(value)),
              duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                color: color,
                backgroundColor: Theme.of(context).colorScheme.onSurface.fade(0.07),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(valueText ?? '${(value * 100).round()}%', textAlign: TextAlign.right, style: tt.bodySmall),
        ),
      ]),
    );
  }
}

/// "How was this calculated?" bottom sheet listing formulas and inputs.
void showTraceSheet(BuildContext context, String title, List<Trace> traces) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final tt = Theme.of(context).textTheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(title, style: tt.headlineSmall),
            const SizedBox(height: 4),
            Text('Every number comes from a fixed formula. No AI is involved in scoring.', style: tt.bodySmall),
            for (final t in traces) ...[
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Text(t.metric, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                Text(t.value > 1.0001 ? t.value.toStringAsFixed(1) : '${(t.value * 100).round()}%',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              Panel(
                primary: false,
                child: SelectableText(t.formula, style: tt.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.5)),
              ),
              const SizedBox(height: 6),
              for (final e in t.inputs.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(e.key, style: tt.bodySmall)),
                    const SizedBox(width: 12),
                    Flexible(child: Text('${e.value}', textAlign: TextAlign.right, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700))),
                  ]),
                ),
            ],
          ],
        ),
      );
    },
  );
}

/// Bottom-sheet picker for up to [max] careers, grouped by cluster with search.
Future<List<String>?> pickCareers(BuildContext context, SeedData seed, List<String> initial, {int max = 3, String title = 'Pick up to 3 careers'}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CareerPicker(seed: seed, initial: initial, max: max, title: title),
  );
}

class _CareerPicker extends StatefulWidget {
  final SeedData seed;
  final List<String> initial;
  final int max;
  final String title;
  const _CareerPicker({required this.seed, required this.initial, required this.max, required this.title});
  @override
  State<_CareerPicker> createState() => _CareerPickerState();
}

class _CareerPickerState extends State<_CareerPicker> {
  late final List<String> selected = [...widget.initial];
  String query = '';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final careers = widget.seed.careers.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: Text('${widget.title} (${selected.length}/${widget.max})', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Done')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search careers', border: OutlineInputBorder()),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        Expanded(
          child: ListView(controller: controller, children: [
            for (final cl in CareerCluster.values)
              if (careers.any((c) => c.cluster == cl)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(clusterLabel(cl), style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                ),
                for (final c in careers.where((c) => c.cluster == cl))
                  CheckboxListTile(
                    dense: true,
                    value: selected.contains(c.id),
                    title: Text(c.name),
                    subtitle: Text(c.summary, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onChanged: (v) => setState(() {
                      if (v == true && selected.length < widget.max) selected.add(c.id);
                      if (v == false) selected.remove(c.id);
                    }),
                  ),
              ],
          ]),
        ),
      ]),
    );
  }
}

/// Wrap of single-select chips.
class ChoiceRow<T> extends StatelessWidget {
  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  const ChoiceRow({super.key, required this.values, required this.selected, required this.label, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final v in values)
        ChoiceChip(label: Text(label(v)), selected: v == selected, onSelected: (_) => onSelected(v)),
    ]);
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  final String? hint;
  const FieldLabel(this.text, {super.key, this.hint});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        if (hint != null) Text(hint!, style: tt.bodySmall?.copyWith(color: tt.bodySmall?.color?.fade(0.7))),
      ]),
    );
  }
}

/// Shared app-bar actions: language and theme.
List<Widget> appBarActions(BuildContext context) {
  final app = context.watch<AppState>();
  return [
    PopupMenuButton<AppLang>(
      tooltip: 'Language',
      icon: const Icon(Icons.translate),
      onSelected: app.setLang,
      itemBuilder: (_) => [for (final l in AppLang.values) PopupMenuItem(value: l, child: Text(l.label))],
    ),
    IconButton(
      tooltip: 'Light / dark',
      onPressed: app.toggleTheme,
      icon: Icon(app.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    ),
  ];
}

/// Friendly empty state that always tells the user what to do next.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSurface.fade(0.4)),
            const SizedBox(height: Spacing.md),
            Text(title, style: tt.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.sm),
            Text(message, style: tt.bodyMedium, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Spacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ]),
        ),
      ),
    );
  }
}
