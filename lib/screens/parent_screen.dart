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
import '../widgets/motion.dart';

class _IncomeBand {
  final String label;
  final int midpoint;
  const _IncomeBand(this.label, this.midpoint);
}

const _bands = [
  _IncomeBand('Under ₹2.5 L', 150000),
  _IncomeBand('₹2.5–5 L', 375000),
  _IncomeBand('₹5–8 L', 650000),
  _IncomeBand('₹8–15 L', 1150000),
  _IncomeBand('₹15–30 L', 2250000),
  _IncomeBand('Above ₹30 L', 4000000),
];

class ParentScreen extends StatefulWidget {
  final String? initialCode;
  const ParentScreen({super.key, this.initialCode});
  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  late final codeCtrl = TextEditingController(text: widget.initialCode ?? '');
  String? code;
  int step = 0; // 0 money, 1 hopes, 2 location & eligibility

  _IncomeBand income = _bands[1];
  double savings = 100000;
  LoanComfort loan = LoanComfort.moderate;
  double emi = 5000;
  double risk = 0.3;
  List<String> prefs = [];
  double expectedSalary = 600000;
  double yearsToEarn = 5;
  Mobility relocation = Mobility.state;
  SocialCategory? category;
  Gender? childGender;
  bool firstGen = false;
  bool disability = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCode != null) _checkCode();
    });
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  void _checkCode() {
    final app = context.read<AppState>();
    final c = codeCtrl.text.trim().toUpperCase();
    if (app.hasStudent(c)) {
      final existing = app.parents[c];
      final student = app.students[c]!;
      setState(() {
        code = c;
        childGender = student.context.gender;
        if (existing != null) {
          savings = existing.savingsForEducationINR.toDouble().clamp(0, 2000000).toDouble();
          loan = existing.loanComfort;
          emi = existing.maxMonthlyEmiINR.toDouble().clamp(0, 50000).toDouble();
          risk = existing.riskAppetite;
          prefs = [...existing.preferredCareerIds];
          expectedSalary = existing.expectedSalaryAt25INR.toDouble().clamp(100000, 3000000).toDouble();
          yearsToEarn = existing.preferredYearsToEarning.toDouble().clamp(1, 10).toDouble();
          relocation = existing.relocationAcceptance;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No student found with that code on this device. Ask your child to finish the assessment first.')),
      );
    }
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    final c = code!;
    await app.saveParent(ParentProfile(
      familyCode: c,
      annualIncomeINR: income.midpoint,
      savingsForEducationINR: savings.round(),
      maxMonthlyEmiINR: emi.round(),
      expectedSalaryAt25INR: expectedSalary.round(),
      loanComfort: loan,
      riskAppetite: risk,
      preferredCareerIds: prefs,
      preferredYearsToEarning: yearsToEarn.round(),
      relocationAcceptance: relocation,
      category: category,
      childGender: childGender,
      firstGenerationLearner: firstGen,
      disability: disability,
      completedAt: DateTime.now(),
    ));
    app.openFamily(c);
    if (mounted) context.go('/results');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    if (app.seed == null) return const Scaffold(body: PageSkeleton());

    if (code == null) {
      return Scaffold(
        appBar: prismAppBar(context, title: app.t('joinParent')),
        body: PageBody(maxWidth: 520, children: [
          const SizedBox(height: 24),
          Text('Enter your child\'s family code', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Your child gets this 6-character code after finishing the assessment.'),
          const SizedBox(height: 20),
          TextField(
            controller: codeCtrl,
            textCapitalization: TextCapitalization.characters,
            style: tt.headlineSmall?.copyWith(letterSpacing: 4),
            decoration: InputDecoration(labelText: app.t('familyCode'), border: const OutlineInputBorder()),
            onSubmitted: (_) => _checkCode(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _checkCode, child: Text(app.t('next'))),
        ]),
      );
    }

    final student = app.students[code]!;
    const stepTitles = ['Money', 'Hopes', 'Moving & eligibility'];

    final List<Widget> money = [
      const FieldLabel('Yearly household income'),
      ChoiceRow<_IncomeBand>(values: _bands, selected: income, label: (b) => b.label, onSelected: (v) => setState(() => income = v)),
      FieldLabel('Savings set aside for education: ${inr(savings)}'),
      Slider(value: savings, min: 0, max: 2000000, divisions: 80, label: inr(savings), onChanged: (v) => setState(() => savings = v)),
      const FieldLabel('Education loan'),
      ChoiceRow<LoanComfort>(values: LoanComfort.values, selected: loan, label: loanLabel, onSelected: (v) => setState(() => loan = v)),
      FieldLabel('Highest monthly EMI you could manage: ${inr(emi)}', hint: 'Usually repaid after the course, once your child is earning.'),
      Slider(value: emi, min: 0, max: 50000, divisions: 50, label: inr(emi), onChanged: (v) => setState(() => emi = v)),
    ];

    final List<Widget> hopes = [
      const FieldLabel('What kind of career path feels right?'),
      Slider(value: risk, min: 0, max: 1, divisions: 10, onChanged: (v) => setState(() => risk = v)),
      Row(children: [
        Expanded(child: Text('Stable job (government, PSU, bank)', style: tt.bodySmall)),
        Expanded(child: Text('Startup, creative or new-age field', textAlign: TextAlign.right, style: tt.bodySmall)),
      ]),
      const FieldLabel('Careers you would like for your child (up to 3)'),
      Wrap(spacing: Spacing.sm, runSpacing: Spacing.sm, children: [
        for (final id in prefs) Chip(label: Text(app.seed!.careerById[id]?.name ?? id), onDeleted: () => setState(() => prefs.remove(id))),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('Choose careers'),
          onPressed: () async {
            final picked = await pickCareers(context, app.seed!, prefs);
            if (picked != null) setState(() => prefs = picked);
          },
        ),
      ]),
      FieldLabel('Salary you expect by age 25: ${inr(expectedSalary)} a year'),
      Slider(value: expectedSalary, min: 100000, max: 3000000, divisions: 58, label: inr(expectedSalary), onChanged: (v) => setState(() => expectedSalary = v)),
      FieldLabel('Years until your child should start earning: ${yearsToEarn.round()}'),
      Slider(value: yearsToEarn, min: 1, max: 10, divisions: 9, label: '${yearsToEarn.round()}', onChanged: (v) => setState(() => yearsToEarn = v)),
    ];

    final List<Widget> place = [
      const FieldLabel('How far are you comfortable with them moving for work?'),
      ChoiceRow<Mobility>(values: Mobility.values, selected: relocation, label: mobilityLabel, onSelected: (v) => setState(() => relocation = v)),
      const SizedBox(height: Spacing.lg),
      Panel(
        primary: false,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          title: const Text('Scholarship eligibility (optional)'),
          subtitle: const Text('Private and optional. Used only to match scholarships.'),
          children: [
            const FieldLabel('Category'),
            ChoiceRow<SocialCategory>(
              values: SocialCategory.values,
              selected: category,
              label: (c) => c.name.toUpperCase(),
              onSelected: (v) => setState(() => category = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('My child will be the first graduate in our family'),
              value: firstGen,
              onChanged: (v) => setState(() => firstGen = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('My child has a disability (40% or more)'),
              value: disability,
              onChanged: (v) => setState(() => disability = v),
            ),
          ],
        ),
      ),
    ];

    final pages = [money, hopes, place];
    final last = step == pages.length - 1;

    return Scaffold(
      appBar: prismAppBar(context, title: 'Family details for ${student.name}'),
      body: PageBody(maxWidth: 720, children: [
        _StepHeader(titles: stepTitles, current: step, onTap: (i) => setState(() => step = i)),
        const SizedBox(height: Spacing.lg),
        if (step == 0)
          Text('Your answers stay on this device. They are used only to check affordability and how closely your hopes match your child\'s.',
              style: tt.bodyMedium),
        AnimatedSwitcher(
          duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 240),
          child: Column(key: ValueKey<int>(step), crossAxisAlignment: CrossAxisAlignment.stretch, children: pages[step]),
        ),
        const SizedBox(height: Spacing.xxl),
        Row(children: [
          if (step > 0)
            OutlinedButton.icon(
              onPressed: () => setState(() => step--),
              icon: const Icon(Icons.arrow_back),
              label: Text(app.t('back')),
            ),
          const Spacer(),
          FilledButton(
            onPressed: last ? _submit : () => setState(() => step++),
            child: Text(last ? app.t('seeResults') : '${app.t('next')}: ${stepTitles[step + 1 < stepTitles.length ? step + 1 : step]}'),
          ),
        ]),
      ]),
    );
  }
}

/// Three numbered steps joined by a line; tap a step to jump to it.
class _StepHeader extends StatelessWidget {
  final List<String> titles;
  final int current;
  final ValueChanged<int> onTap;
  const _StepHeader({required this.titles, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final ink = Theme.of(context).colorScheme.onSurface;
    final wide = MediaQuery.sizeOf(context).width > 560; // on phones only the current step shows its name
    final items = <Widget>[];
    for (var i = 0; i < titles.length; i++) {
      final done = i < current, active = i == current;
      items.add(InkWell(
        borderRadius: BorderRadius.circular(Radii.nested),
        onTap: () => onTap(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xs, vertical: Spacing.sm),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active || done ? PrismColors.fit : Colors.transparent,
                border: Border.all(color: active || done ? PrismColors.fit : ink.fade(0.3)),
              ),
              child: done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text('${i + 1}', style: tt.labelLarge?.copyWith(color: active ? Colors.white : ink.fade(0.7))),
            ),
            if (active || wide) ...[
              const SizedBox(width: Spacing.sm),
              Text(titles[i], style: tt.labelLarge?.copyWith(color: active ? ink : ink.fade(0.6))),
            ],
          ]),
        ),
      ));
      if (i < titles.length - 1) {
        items.add(Expanded(child: Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: Spacing.sm), color: ink.fade(0.15))));
      }
    }
    return Row(children: items);
  }
}
