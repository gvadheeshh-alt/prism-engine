import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/cohort.dart';
import '../engine/labels.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_shell.dart';
import '../widgets/motion.dart';

/// School / counselor view: aggregate analytics across a cohort.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  CohortStats? stats;

  @override
  void initState() {
    super.initState();
    // Let the first frame paint a spinner, then run 60 engine passes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seed = context.read<AppState>().seed;
      if (seed != null && mounted) setState(() => stats = simulateCohort(seed));
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final s = stats;
    return Scaffold(
      appBar: prismAppBar(context, title: app.t('school')),
      body: s == null
          ? const PageSkeleton()
          : PageBody(children: [
              Text('Class cohort overview', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Simulated cohort of ${s.size} students, each scored by the real engine. '
                  'In a school deployment this page aggregates actual submissions.'),
              const SizedBox(height: 16),
              Wrap(spacing: 12, runSpacing: 12, children: [
                _Stat(label: 'Students', value: s.size, color: PrismColors.fit),
                _Stat(
                  label: 'Significant family disagreement',
                  value: (s.conflictBands[ConflictBand.significant] ?? 0) + (s.conflictBands[ConflictBand.high] ?? 0),
                  color: PrismColors.penalty,
                ),
                _Stat(label: 'Top choice needs financial aid', value: s.notViableTopChoice, color: PrismColors.feasibility),
              ]),
              const SectionTitle('Average interest and aptitude profile'),
              Panel(
                child: Column(children: [
                  for (final d in Dimension.values)
                    MetricBar(label: d.label, value: s.avgDims[d] ?? 0, color: PrismColors.spectrum[d.group.index]),
                ]),
              ),
              const SectionTitle('Most common #1 career match'),
              Panel(child: _CountBars(
                entries: (s.topCareerCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                    .take(8)
                    .map((e) => MapEntry<String, int>(app.seed!.careerById[e.key]?.name ?? e.key, e.value))
                    .toList(),
                total: s.size,
                color: PrismColors.roi,
              )),
              const SectionTitle('Family alignment across the class'),
              Panel(child: _CountBars(
                entries: [for (final b in ConflictBand.values) MapEntry<String, int>(bandLabel(b), s.conflictBands[b] ?? 0)],
                total: s.size,
                color: PrismColors.penalty,
              )),
              const SectionTitle('Most common skill gaps', subtitle: 'Where a workshop would help the most students'),
              Panel(child: _CountBars(
                entries: (s.commonGaps.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                    .take(6)
                    .map((e) => MapEntry<String, int>(e.key.label, e.value))
                    .toList(),
                total: s.size,
                color: PrismColors.feasibility,
              )),
            ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      width: 220,
      child: Panel(
        accent: color,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedNumber(value: value.toDouble(), style: tt.displaySmall?.copyWith(color: color)),
          Text(label, style: tt.bodySmall),
        ]),
      ),
    );
  }
}

class _CountBars extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final int total;
  final Color color;
  const _CountBars({required this.entries, required this.total, required this.color});
  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const Text('No data yet.');
    return Column(children: [
      for (final e in entries) MetricBar(label: e.key, value: total == 0 ? 0 : e.value / total, color: color, valueText: '${e.value}'),
    ]);
  }
}
