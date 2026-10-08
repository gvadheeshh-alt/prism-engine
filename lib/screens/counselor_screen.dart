import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/llm_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_shell.dart';
import '../widgets/motion.dart';

/// Chat grounded strictly in the engine result. Uses an LLM when configured, otherwise offline rules.
class CounselorScreen extends StatefulWidget {
  const CounselorScreen({super.key});
  @override
  State<CounselorScreen> createState() => _CounselorScreenState();
}

class _CounselorScreenState extends State<CounselorScreen> {
  final llm = LlmService();
  final ctrl = TextEditingController();
  final scroll = ScrollController();
  final turns = <ChatTurn>[];
  bool busy = false;

  @override
  void dispose() {
    ctrl.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final r = context.read<AppState>().result;
    if (r == null || text.trim().isEmpty || busy) return;
    setState(() {
      turns.add(ChatTurn(true, text.trim()));
      busy = true;
      ctrl.clear();
    });
    String reply;
    if (llm.enabled) {
      try {
        reply = await llm.chat(counselorSystemPrompt(r), turns);
      } catch (e) {
        reply = '${offlineCounselorReply(r, text)}\n\n(AI service unavailable, so this answer used offline rules.)';
      }
    } else {
      reply = offlineCounselorReply(r, text);
    }
    if (!mounted) return;
    setState(() {
      turns.add(ChatTurn(false, reply));
      busy = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final r = app.result;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (r == null) {
      return Scaffold(
        appBar: prismAppBar(context, title: app.t('counselor')),
        body: EmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Nothing to discuss yet',
          message: 'The counselor answers questions about your results. Take the assessment or open a demo family first.',
          actionLabel: 'Go to the start page',
          onAction: () => context.go('/'),
        ),
      );
    }
    final suggestions = [
      'Why is ${r.rankings.first.career.name} my top match?',
      'Can we afford it?',
      'Which scholarships fit me?',
      'How do my parents\' views affect this?',
      'What should I improve?',
    ];
    return Scaffold(
      appBar: prismAppBar(context, title: app.t('counselor')),
      body: Column(children: [
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                llm.enabled
                    ? 'Answers use only your computed results. The AI never changes the scores.'
                    : 'Offline mode: answers come from your computed results using fixed rules. Add an API key to enable the AI counselor.',
                style: tt.bodySmall,
              ),
              const SizedBox(height: 12),
              if (turns.isEmpty)
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in suggestions) ActionChip(label: Text(s), onPressed: () => _send(s)),
                ]),
              for (final t in turns)
                Align(
                  alignment: t.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 560),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.fromUser ? PrismColors.fit.fade(0.12) : cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.onSurface.fade(0.08)),
                    ),
                    child: SelectableText(t.text, style: tt.bodyMedium?.copyWith(height: 1.45)),
                  ),
                ),
              if (busy)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(padding: EdgeInsets.symmetric(vertical: Spacing.sm), child: _TypingDots()),
                ),
            ],
          ),
        ),
        if (turns.isNotEmpty && !busy)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              children: [
                for (final s in suggestions)
                  Padding(
                    padding: const EdgeInsets.only(right: Spacing.sm),
                    child: ActionChip(label: Text(s), onPressed: () => _send(s)),
                  ),
              ],
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: const InputDecoration(hintText: 'Ask about your results', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: busy ? null : () => _send(ctrl.text), icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}


/// Three dots that pulse in turn while the counselor is writing.
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final still = reduceMotion(context);
    return Semantics(
      label: 'Counselor is typing',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(Radii.primary),
          border: Border.all(color: cs.onSurface.fade(0.08)),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.onSurface.fade(still ? 0.5 : 0.25 + 0.6 * _wave(_c.value, i)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  static double _wave(double t, int i) {
    final x = (t - i * 0.2) % 1.0;
    return x < 0.5 ? x * 2 : (1 - x) * 2;
  }
}
