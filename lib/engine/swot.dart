import '../models/models.dart';
import 'format.dart';

/// Stage 3, step 7: rule-based SWOT (the AI layer may re-phrase it, never change it).
Swot buildSwot({
  required StudentVector student,
  required List<CareerScore> rankings,
  required ConflictResult? conflict,
  required List<InnovationIdea> ideas,
  required String area,
}) {
  final dims = [...Dimension.values]..sort((a, b) => student.dims[b].compareTo(student.dims[a]));
  final strengths = [
    for (final d in dims.take(3)) SwotItem('Strong ${d.label.toLowerCase()} (${pct(student.dims[d])})', d.name),
  ];

  final top = rankings.isEmpty ? null : rankings.first;
  final weaknesses = <SwotItem>[
    if (top != null)
      for (final g in top.gaps)
        SwotItem(
            '${g.dimension.label} is ${(g.gap * 100).round()} points below what ${top.career.name} needs',
            g.dimension.name),
  ];
  if (weaknesses.isEmpty) {
    final low = dims.last;
    weaknesses.add(SwotItem('${low.label} is your lowest area (${pct(student.dims[low])})', low.name));
  }

  final topTen = rankings.take(10).toList();
  final growing = topTen.where((s) => s.career.market.jobVelocity >= 15).toList()
    ..sort((a, b) => b.career.market.jobVelocity.compareTo(a.career.market.jobVelocity));
  final opportunities = <SwotItem>[
    for (final s in growing.take(2))
      SwotItem('${s.career.name} job postings growing about ${s.career.market.jobVelocity.round()}% a year',
          s.career.id),
    if (ideas.isNotEmpty) SwotItem('Local industry in $area: ${ideas.first.localIndustry}', 'hyperlocal'),
  ];
  if (opportunities.isEmpty) {
    opportunities.add(const SwotItem('Several careers that fit you are still growing steadily', 'market'));
  }

  final threats = <SwotItem>[
    if (top != null && top.career.market.disruptionIndex >= 0.35)
      SwotItem('${top.career.name} has high automation / AI exposure; keep skills current', top.career.id),
    if (top != null && top.finance.notViableWithoutAid)
      SwotItem('Your top match is not affordable without extra scholarships or loans', 'finance'),
    if (conflict != null && conflict.psci100 > 50)
      SwotItem('Significant family disagreement (conflict index ${conflict.psci100.round()}/100)', 'conflict'),
    if (top != null && top.flags.any((f) => f.contains('stream')))
      SwotItem('${top.career.name} needs a different subject stream', 'stream'),
  ];
  if (threats.isEmpty) {
    threats.add(const SwotItem('Entrance exams are competitive; start preparing early', 'exams'));
  }

  return Swot(strengths: strengths, weaknesses: weaknesses, opportunities: opportunities, threats: threats);
}
