import 'dart:convert';

import 'package:http/http.dart' as http;

import '../engine/format.dart';
import '../models/models.dart';

class ChatTurn {
  final bool fromUser;
  final String text;
  const ChatTurn(this.fromUser, this.text);
}

/// Optional LLM layer. Configure at build/run time, never hard-code keys:
///   flutter run --dart-define=LLM_PROVIDER=anthropic --dart-define=LLM_KEY=sk-...
///   flutter run --dart-define=LLM_PROVIDER=gemini --dart-define=LLM_KEY=...
/// Optional: --dart-define=LLM_MODEL=<model id>. Without a key, the offline counselor is used.
/// For production, route requests through your own backend so the key never ships in the app.
class LlmService {
  static const provider = String.fromEnvironment('LLM_PROVIDER', defaultValue: 'none');
  static const apiKey = String.fromEnvironment('LLM_KEY');
  static const model = String.fromEnvironment('LLM_MODEL');

  bool get enabled => provider != 'none' && apiKey.isNotEmpty;

  Future<String> chat(String system, List<ChatTurn> history) async {
    if (!enabled) throw StateError('LLM not configured');
    return provider == 'gemini' ? _gemini(system, history) : _anthropic(system, history);
  }

  Future<String> _anthropic(String system, List<ChatTurn> history) async {
    final res = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: jsonEncode({
        'model': model.isEmpty ? 'claude-haiku-4-5-20251001' : model,
        'max_tokens': 600,
        'system': system,
        'messages': [
          for (final t in history) {'role': t.fromUser ? 'user' : 'assistant', 'content': t.text}
        ],
      }),
    );
    if (res.statusCode != 200) throw Exception('LLM error ${res.statusCode}: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['content'] as List).where((b) => b['type'] == 'text').map((b) => b['text']).join('\n');
  }

  Future<String> _gemini(String system, List<ChatTurn> history) async {
    final m = model.isEmpty ? 'gemini-2.5-flash' : model;
    final res = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$apiKey'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': system}
          ]
        },
        'contents': [
          for (final t in history)
            {
              'role': t.fromUser ? 'user' : 'model',
              'parts': [
                {'text': t.text}
              ]
            }
        ],
      }),
    );
    if (res.statusCode != 200) throw Exception('LLM error ${res.statusCode}: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final parts = (data['candidates'] as List).first['content']['parts'] as List;
    return parts.map((p) => p['text']).join('\n');
  }
}

/// Compact, number-complete summary of the engine result. This is the ONLY knowledge the AI gets.
String groundingContext(EngineResult r) {
  final b = StringBuffer();
  b.writeln('Student: ${r.student.name}, ${r.student.context.level.name}, ${r.student.context.district}, ${r.student.context.state}.');
  b.writeln('Weights: fit ${r.weights.alpha}, market ${r.weights.beta}, affordability ${r.weights.gamma}, ROI ${r.weights.delta}, family penalty ${r.weights.lambda}.');
  b.writeln('Top careers:');
  for (final s in r.rankings.take(5)) {
    final f = s.finance.best;
    b.writeln('- ${s.career.name}: PRISM ${s.prism100.toStringAsFixed(0)}/100; fit ${pct(s.components.fit)}, market ${pct(s.components.market)}, '
        'affordability ${pct(s.components.feasibility)}, route "${f.label}" costing ${inr(f.totalCostINR)}, ROI ${roiText(f.roi)}, '
        'starting salary ${inr(s.career.startingSalaryINR)}. Gaps: ${s.gaps.map((g) => g.dimension.label).join(', ')}. ${s.flags.join('. ')}');
  }
  final c = r.conflict;
  if (c != null) {
    b.writeln('Family conflict index ${c.psci100.toStringAsFixed(0)}/100. Drivers: ${c.drivers.join(' ')}');
    b.writeln('Bridge careers: ${c.bridgeCareers.map((x) => x.career.name).join(', ')}.');
  }
  b.writeln('Strengths: ${r.swot.strengths.map((s) => s.text).join('; ')}.');
  b.writeln('Local ideas in ${r.hyperLocalArea}: ${r.hyperLocal.map((i) => i.title).join('; ')}.');
  b.writeln('Scholarships matched for the top career: ${r.rankings.first.finance.scholarships.map((m) => m.scholarship.name).join(', ')}.');
  return b.toString();
}

String counselorSystemPrompt(EngineResult r) => '''
You are PRISM, a warm, practical career counselor for Indian students and their parents.
Answer ONLY using the computed results below. Never invent salaries, fees, ranks, percentages or dates.
If a number is not in the results, say you don't have it and suggest checking the official source.
All figures are illustrative demo estimates; mention this when quoting money.
Keep answers under 150 words, in simple language. If the user writes in Tamil or Hindi, reply in that language.

RESULTS:
${groundingContext(r)}''';

/// Rule-based fallback so the counselor works offline and on stage without an API key.
String offlineCounselorReply(EngineResult r, String question) {
  final q = question.toLowerCase();
  final top = r.rankings.first;
  final f = top.finance.best;
  if (q.contains('why') || q.contains('top') || q.contains('best')) {
    return '${top.career.name} ranks first with a PRISM score of ${top.prism100.round()}/100. '
        'Your profile fit is ${pct(top.components.fit)}, market strength ${pct(top.components.market)}, '
        'affordability ${pct(top.components.feasibility)}. Tap any score to see the exact formula.';
  }
  if (q.contains('cost') || q.contains('afford') || q.contains('fee') || q.contains('loan') || q.contains('money')) {
    return 'The most affordable workable route for ${top.career.name} is "${f.label}". Estimated total cost ${inr(f.totalCostINR)}; '
        'savings ${inr(f.savingsINR)}, expected scholarships ${inr(f.scholarshipINR)}, and a manageable loan of up to ${inr(f.loanCapacityINR)}. '
        'These are illustrative estimates.';
  }
  if (q.contains('scholar')) {
    final s = top.finance.scholarships;
    if (s.isEmpty) return 'No scholarships matched the details entered. Check scholarships.gov.in for the full list.';
    return 'Matched schemes: ${s.take(4).map((m) => m.scholarship.name).join(', ')}. Verify eligibility on each official website.';
  }
  if (q.contains('parent') || q.contains('family') || q.contains('conflict') || q.contains('agree')) {
    final c = r.conflict;
    if (c == null) return 'Your parents have not added their inputs yet. Share your family code so they can join.';
    return 'Family conflict index: ${c.psci100.round()}/100. ${c.drivers.join(' ')} '
        'Careers that could work for both of you: ${c.bridgeCareers.map((b) => b.career.name).join(', ')}.';
  }
  if (q.contains('exam') || q.contains('entrance')) {
    final steps = r.roadmaps.first.steps.expand((s) => s.actions).where((a) => a.contains('exam') || a.contains('Register') || a.contains('Prepare'));
    return steps.isEmpty ? 'Check the roadmap section for exam steps.' : steps.join(' ');
  }
  if (q.contains('improve') || q.contains('weak') || q.contains('gap')) {
    if (top.gaps.isEmpty) return 'You already meet the profile for ${top.career.name}. Keep building projects.';
    return top.gaps.map((g) => '${g.dimension.label}: ${g.actions.isEmpty ? 'practise regularly' : g.actions.first.label}').join('. ');
  }
  return 'I can explain your top careers, costs and loans, scholarships, exams, how to improve, or how your family\'s views affect the results. '
      'Try asking "Why is ${top.career.name} my top match?"';
}
