import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../engine/labels.dart';
import '../engine/normalize.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_shell.dart';
import '../widgets/motion.dart';

enum _Stage { profile, quiz, done }

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});
  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  _Stage stage = _Stage.profile;

  // Profile
  final nameCtrl = TextEditingController();
  final stateCtrl = TextEditingController(text: 'Tamil Nadu'); // default; the student can change it
  final districtCtrl = TextEditingController();
  StudyLevel level = StudyLevel.class12;
  AcademicStream stream = AcademicStream.sciencePcm;
  MarksBand marks = MarksBand.b60to75;
  Mobility mobility = Mobility.state;
  Gender? gender;
  List<String> dreams = [];

  // Quiz
  int index = 0;
  final answers = StudentAnswers();
  Timer? timer;
  int secondsLeft = 0;
  String? familyCode;

  @override
  void dispose() {
    timer?.cancel();
    nameCtrl.dispose();
    stateCtrl.dispose();
    districtCtrl.dispose();
    super.dispose();
  }

  List<Question> get questions => context.read<AppState>().seed!.questions;

  void _startQuiz() {
    if (nameCtrl.text.trim().isEmpty || districtCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name, state and district.')));
      return;
    }
    setState(() {
      stage = _Stage.quiz;
      index = 0;
    });
    _onQuestionShown();
  }

  void _onQuestionShown() {
    timer?.cancel();
    final q = questions[index];
    if (q.type == QuestionType.aptitude) {
      secondsLeft = q.seconds;
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => secondsLeft--);
        if (secondsLeft <= 0) {
          answers.aptitude[q.id] = false; // time ran out
          _next();
        }
      });
    }
  }

  void _answer(int value) {
    final q = questions[index];
    switch (q.type) {
      case QuestionType.likert:
        answers.likert[q.id] = value;
      case QuestionType.choice:
        answers.choice[q.id] = value;
      case QuestionType.selfRating:
        answers.selfRating[q.id] = value;
      case QuestionType.aptitude:
        answers.aptitude[q.id] = value == q.answerIndex;
    }
    _next();
  }

  void _next() {
    timer?.cancel();
    if (index < questions.length - 1) {
      setState(() => index++);
      _onQuestionShown();
    } else {
      _finish();
    }
  }

  void _back() {
    if (index == 0) return;
    final prev = questions[index - 1];
    if (prev.type == QuestionType.aptitude) return; // timed items can't be retaken
    timer?.cancel();
    setState(() => index--);
    _onQuestionShown();
  }

  Future<void> _finish() async {
    final app = context.read<AppState>();
    final code = app.newFamilyCode();
    final vector = normalizeStudent(
      studentId: 'stu-$code',
      familyCode: code,
      name: nameCtrl.text.trim(),
      questions: app.seed!.questions,
      answers: answers,
      context: StudentContext(
        level: level,
        stream: level.index < StudyLevel.class11.index ? AcademicStream.undecided : stream,
        marksBand: marks,
        state: stateCtrl.text.trim(),
        district: districtCtrl.text.trim(),
        mobility: mobility,
        dreamCareerIds: dreams,
        gender: gender,
      ),
    );
    await app.saveStudent(vector);
    if (!mounted) return;
    setState(() {
      familyCode = code;
      stage = _Stage.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.seed == null) return const Scaffold(body: PageSkeleton());
    return Scaffold(
      appBar: prismAppBar(context, title: 'Student assessment'),
      body: switch (stage) {
        _Stage.profile => _profile(context),
        _Stage.quiz => _quiz(context),
        _Stage.done => _done(context),
      },
    );
  }

  Widget _profile(BuildContext context) {
    final app = context.read<AppState>();
    final seed = app.seed!;
    final curatedDistricts = {for (final l in seed.localIndustries) if (l.district != '*') l.district.toLowerCase()};
    final tt = Theme.of(context).textTheme;
    return PageBody(maxWidth: 720, children: [
      Text('About you', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('This takes about 15 minutes: 51 questions, including 11 timed puzzles. There are no right or wrong answers except in the puzzles.'),
      const FieldLabel('Your name'),
      TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
      const FieldLabel('Where are you now?'),
      ChoiceRow<StudyLevel>(values: StudyLevel.values, selected: level, label: levelLabel, onSelected: (v) => setState(() => level = v)),
      if (level.index >= StudyLevel.class11.index) ...[
        const FieldLabel('Your stream'),
        ChoiceRow<AcademicStream>(
          values: AcademicStream.values.where((s) => s != AcademicStream.undecided).toList(),
          selected: stream,
          label: streamLabel,
          onSelected: (v) => setState(() => stream = v),
        ),
      ],
      const FieldLabel('Your recent marks'),
      ChoiceRow<MarksBand>(values: MarksBand.values, selected: marks, label: marksLabel, onSelected: (v) => setState(() => marks = v)),
      const FieldLabel('State or union territory'),
      DropdownMenu<String>(
        initialSelection: app.districtsByState.containsKey(stateCtrl.text) ? stateCtrl.text : null,
        expandedInsets: EdgeInsets.zero,
        enableFilter: true,
        requestFocusOnTap: true,
        menuHeight: 360,
        hintText: 'Type or choose your state',
        dropdownMenuEntries: [for (final st in app.states) DropdownMenuEntry<String>(value: st, label: st)],
        onSelected: (v) {
          if (v == null || v == stateCtrl.text) return;
          setState(() {
            stateCtrl.text = v;
            districtCtrl.clear(); // districts belong to the old state
          });
        },
      ),
      const FieldLabel('District', hint: 'Used to find local industries and innovation ideas near you.'),
      DropdownMenu<String>(
        key: ValueKey('district-${stateCtrl.text}'),
        initialSelection: (app.districtsByState[stateCtrl.text] ?? const []).contains(districtCtrl.text) ? districtCtrl.text : null,
        expandedInsets: EdgeInsets.zero,
        enableFilter: true,
        requestFocusOnTap: true,
        menuHeight: 360,
        enabled: (app.districtsByState[stateCtrl.text] ?? const []).isNotEmpty,
        hintText: stateCtrl.text.isEmpty ? 'Choose your state first' : 'Type or choose your district',
        dropdownMenuEntries: [
          for (final d in app.districtsByState[stateCtrl.text] ?? const <String>[]) DropdownMenuEntry<String>(value: d, label: d),
        ],
        onSelected: (v) => setState(() => districtCtrl.text = v ?? ''),
      ),
      if (districtCtrl.text.isNotEmpty && !curatedDistricts.contains(districtCtrl.text.toLowerCase()))
        Padding(
          padding: const EdgeInsets.only(top: Spacing.sm),
          child: Text(
            'Detailed local-industry ideas are available for ${curatedDistricts.length} Tamil Nadu districts so far. '
            'For ${districtCtrl.text} you will see general ideas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      const FieldLabel('How far would you move for work?'),
      ChoiceRow<Mobility>(values: Mobility.values, selected: mobility, label: mobilityLabel, onSelected: (v) => setState(() => mobility = v)),
      const FieldLabel('Gender (optional)', hint: 'Only used to match scholarships.'),
      ChoiceRow<Gender>(
        values: Gender.values,
        selected: gender,
        label: (g) => switch (g) {
          Gender.female => 'Female',
          Gender.male => 'Male',
          Gender.other => 'Other',
          Gender.preferNot => 'Prefer not to say',
        },
        onSelected: (v) => setState(() => gender = v),
      ),
      const FieldLabel('Your dream careers (up to 3)'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final id in dreams) Chip(label: Text(seed.careerById[id]?.name ?? id), onDeleted: () => setState(() => dreams.remove(id))),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('Choose careers'),
          onPressed: () async {
            final picked = await pickCareers(context, seed, dreams);
            if (picked != null) setState(() => dreams = picked);
          },
        ),
      ]),
      const SizedBox(height: 28),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(onPressed: _startQuiz, child: Text('${app.t('next')}: start the questions')),
      ),
    ]);
  }

  Widget _quiz(BuildContext context) {
    final app = context.read<AppState>();
    final tt = Theme.of(context).textTheme;
    final q = questions[index];
    final progress = (index + 1) / questions.length;
    final section = switch (q.type) {
      QuestionType.likert => 'How much do you agree?',
      QuestionType.choice => 'Which would you rather do?',
      QuestionType.aptitude => 'Quick puzzle',
      QuestionType.selfRating => 'Rate yourself honestly',
    };
    final options = switch (q.type) {
      QuestionType.likert => ['Strongly disagree', 'Disagree', 'Not sure', 'Agree', 'Strongly agree'],
      QuestionType.selfRating => ['Needs work', 'Below average', 'Average', 'Good', 'Excellent'],
      QuestionType.aptitude => q.options,
      QuestionType.choice => q.options,
    };
    final still = reduceMotion(context);
    final card = Column(
      key: ValueKey<int>(index),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(section, style: tt.labelLarge?.copyWith(color: PrismColors.fit)),
        const SizedBox(height: Spacing.sm),
        Text(q.text, style: tt.headlineSmall),
        const SizedBox(height: Spacing.xl),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.nested + 2)),
              ),
              onPressed: () => _answer(q.type == QuestionType.aptitude || q.type == QuestionType.choice ? i : i + 1),
              child: Text(options[i], style: tt.bodyLarge),
            ),
          ),
      ],
    );

    return PageBody(maxWidth: 640, children: [
      Row(children: [
        Text('Question ${index + 1} of ${questions.length}', style: tt.labelLarge),
        const Spacer(),
        if (q.type == QuestionType.aptitude) _TimerRing(secondsLeft: secondsLeft, total: q.seconds),
      ]),
      const SizedBox(height: Spacing.sm),
      _SpectrumProgress(value: progress),
      const SizedBox(height: Spacing.xxl),
      AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
        child: card,
      ),
      const SizedBox(height: Spacing.sm),
      Row(children: [
        if (index > 0 && questions[index - 1].type != QuestionType.aptitude && q.type != QuestionType.aptitude)
          TextButton.icon(onPressed: _back, icon: const Icon(Icons.arrow_back), label: Text(app.t('back'))),
        const Spacer(),
        if (q.type == QuestionType.aptitude) TextButton(onPressed: () => _answer(-1), child: const Text('Skip this puzzle')),
      ]),
    ]);
  }

  Widget _done(BuildContext context) {
    final app = context.read<AppState>();
    final tt = Theme.of(context).textTheme;
    final code = familyCode!;
    return PageBody(maxWidth: 640, children: [
      const SizedBox(height: 24),
      Text('Done, ${nameCtrl.text.trim()}!', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Your profile is ready. Ask a parent to add the family details so the results include your budget and their views.'),
      const SizedBox(height: 24),
      Panel(
        accent: PrismColors.fit,
        child: Column(children: [
          Text(app.t('familyCode'), style: tt.labelLarge),
          const SizedBox(height: 6),
          SelectableText(code, style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 6)),
          const SizedBox(height: 6),
          Text('Share this code with your parent', style: tt.bodySmall),
        ]),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => context.go('/parent?code=$code'),
        icon: const Icon(Icons.family_restroom_outlined),
        label: const Text('Parent fills in now on this device'),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () {
          app.openFamily(code);
          context.go('/results');
        },
        child: const Text('See my results without parent details'),
      ),
    ]);
  }
}


/// Thin progress bar filled with the five-colour spectrum.
class _SpectrumProgress extends StatelessWidget {
  final double value;
  const _SpectrumProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${(value * 100).round()} percent complete',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.pill),
        child: Container(
          height: 6,
          color: Theme.of(context).colorScheme.onSurface.fade(0.08),
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: value.clamp(0.0, 1.0)),
            duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 300),
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: LinearGradient(colors: PrismColors.spectrum)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Countdown shown as a ring that shrinks as time runs out.
class _TimerRing extends StatelessWidget {
  final int secondsLeft;
  final int total;
  const _TimerRing({required this.secondsLeft, required this.total});

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft <= 10;
    final color = urgent ? PrismColors.penalty : PrismColors.fit;
    return Semantics(
      label: '$secondsLeft seconds left',
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: total <= 0 ? 0 : (secondsLeft / total).clamp(0.0, 1.0),
              strokeWidth: 3.5,
              color: color,
              backgroundColor: Theme.of(context).colorScheme.onSurface.fade(0.08),
            ),
          ),
          Text('$secondsLeft', style: displayFont(Theme.of(context).textTheme.labelLarge!).copyWith(color: color, fontFeatures: tabularFigures)),
        ]),
      ),
    );
  }
}
