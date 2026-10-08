import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../engine/format.dart';
import '../engine/labels.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_shell.dart';

/// Plain-language one-page summary for parents, with a family discussion guide.
class ParentViewScreen extends StatelessWidget {
  const ParentViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final r = app.result;
    final tt = Theme.of(context).textTheme;
    if (r == null) {
      return Scaffold(
        appBar: prismAppBar(context, title: app.t('parentView')),
        body: EmptyState(
          icon: Icons.family_restroom_outlined,
          title: 'No summary yet',
          message: 'The parent summary appears once your child has finished the assessment.',
          actionLabel: 'Go to the start page',
          onAction: () => context.go('/'),
        ),
      );
    }
    final top = r.rankings.first;
    final f = top.finance.best;
    final c = r.conflict;
    final name = r.student.name;

    final questions = <String>[
      'What does $name enjoy most about ${top.career.name.toLowerCase()}?',
      if (c != null && c.bridgeCareers.isNotEmpty)
        'Would ${c.bridgeCareers.first.career.name.toLowerCase()} satisfy what both of us want?',
      if (!f.viable) 'Which scholarships can we apply for together this month?',
      if (c != null && c.risk > 0.3) 'What would make a less traditional path feel safer to us?',
      'Who could we talk to (a teacher, a relative, a professional) who works in this field?',
    ];

    return Scaffold(
      appBar: prismAppBar(context, title: app.t('parentView')),
      body: PageBody(maxWidth: 720, children: [
        Text('Summary for $name\'s family', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _Block(
          title: 'Our best suggestion',
          color: PrismColors.fit,
          text: '${top.career.name}. It matches $name\'s interests and abilities (${pct(top.components.fit)} fit) '
              'and has ${top.components.market >= 0.6 ? 'good' : 'moderate'} job demand. ${top.career.summary}',
        ),
        _Block(
          title: app.t('afford'),
          color: f.viable ? PrismColors.market : PrismColors.penalty,
          text: 'The most affordable route is "${f.label}", costing about ${inr(f.totalCostINR)} in total. '
              'Your savings (${inr(f.savingsINR)}), likely scholarships (${inr(f.scholarshipINR)}) and a manageable loan '
              '(up to ${inr(f.loanCapacityINR)}) cover about ${pct(f.feasibility)} of it. '
              '${f.viable ? 'This looks workable.' : 'You would need more scholarships or support to make this work.'}',
        ),
        if (c != null)
          _Block(
            title: 'Where you agree and differ',
            color: c.psci100 > 50 ? PrismColors.penalty : PrismColors.market,
            text: '${bandLabel(c.band)} (score ${c.psci100.round()} out of 100). ${c.drivers.join(' ')} '
                '${c.bridgeCareers.isEmpty ? '' : 'Options that may suit both of you: ${c.bridgeCareers.map((b) => b.career.name).join(', ')}.'}',
          ),
        _Block(
          title: 'Next 3 steps',
          color: PrismColors.roi,
          text: r.roadmaps.first.steps.first.actions.take(3).join('\n'),
        ),
        const SizedBox(height: 8),
        Text('Questions to discuss together', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final q in questions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(primary: false, child: Text(q, style: tt.bodyLarge)),
          ),
        const SizedBox(height: 16),
        Text(r.disclaimer, style: tt.bodySmall),
      ]),
    );
  }
}

class _Block extends StatelessWidget {
  final String title, text;
  final Color color;
  const _Block({required this.title, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        accent: color,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 6),
          Text(text, style: tt.bodyLarge?.copyWith(height: 1.5)),
        ]),
      ),
    );
  }
}
