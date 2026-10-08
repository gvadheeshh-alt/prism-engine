import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../engine/format.dart';
import '../engine/labels.dart';
import '../models/models.dart';

/// Builds a printable family report. Uses built-in PDF fonts, so text is English and money uses "Rs.".
class PdfService {
  static Future<void> shareReport(EngineResult r) async {
    await Printing.layoutPdf(
      name: 'PRISM-report-${r.familyCode}.pdf',
      onLayout: (PdfPageFormat format) async => (await build(r)).save(),
    );
  }

  static Future<pw.Document> build(EngineResult r) async {
    final doc = pw.Document(title: 'PRISM report for ${r.student.name}');
    final violet = PdfColor.fromHex('#6B4EE6');
    pw.Widget h(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(_clean(t), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: violet)),
        );
    pw.Widget p(String t) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 3), child: pw.Text(_clean(t), style: const pw.TextStyle(fontSize: 10)));

    final top = r.rankings.first;
    pw.Widget cleanText(String t, pw.TextStyle style) => pw.Text(_clean(t), style: style);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        pw.Text('PRISM Engine career report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        p('${r.student.name} | ${levelLabel(r.student.context.level)} | ${r.student.context.district}, ${r.student.context.state} | Family code ${r.familyCode}'),
        p('Generated ${r.generatedAt.toLocal().toString().substring(0, 16)}'),
        h('Top match: ${top.career.name} (PRISM ${top.prism100.toStringAsFixed(0)}/100)'),
        p(top.career.summary),
        for (final f in top.flags) p('Note: $f'),
        h('Top 5 careers'),
        pw.TableHelper.fromTextArray(
          headers: ['#', 'Career', 'PRISM', 'Fit', 'Market', 'Afford.', 'Route cost'],
          data: [
            for (var i = 0; i < 5 && i < r.rankings.length; i++)
              [
                '${i + 1}',
                _clean(r.rankings[i].career.name),
                r.rankings[i].prism100.toStringAsFixed(0),
                pct(r.rankings[i].components.fit),
                pct(r.rankings[i].components.market),
                pct(r.rankings[i].components.feasibility),
                inrPdf(r.rankings[i].finance.best.totalCostINR),
              ]
          ],
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
        h('Affordability for ${top.career.name}'),
        p('Route: ${top.finance.best.label}'),
        p('Total cost ${inrPdf(top.finance.best.totalCostINR)}; savings ${inrPdf(top.finance.best.savingsINR)}; '
            'expected scholarships ${inrPdf(top.finance.best.scholarshipINR)}; manageable loan ${inrPdf(top.finance.best.loanCapacityINR)}.'),
        p('Covered: ${pct(top.finance.best.feasibility)}. Return: ${roiText(top.finance.best.roi)} the cost.'),
        if (r.conflict != null) ...[
          h('Family alignment: ${bandLabel(r.conflict!.band)} (PSCI ${r.conflict!.psci100.toStringAsFixed(0)}/100)'),
          for (final d in r.conflict!.drivers) p('- ${d.replaceAll('₹', 'Rs. ')}'),
          p('Bridge careers: ${r.conflict!.bridgeCareers.map((b) => b.career.name).join(', ')}'),
        ],
        h('SWOT'),
        p('Strengths: ${r.swot.strengths.map((s) => s.text).join('; ')}'),
        p('Weaknesses: ${r.swot.weaknesses.map((s) => s.text).join('; ')}'),
        p('Opportunities: ${r.swot.opportunities.map((s) => s.text).join('; ')}'),
        p('Threats: ${r.swot.threats.map((s) => s.text).join('; ')}'),
        h('Roadmap: ${r.roadmaps.first.career.name}'),
        for (final s in r.roadmaps.first.steps) ...[
          cleanText('${s.periodLabel}: ${s.title}', pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          for (final a in s.actions) p('  - ${a.replaceAll('₹', 'Rs. ')}'),
        ],
        h('Innovation ideas in ${r.hyperLocalArea}'),
        for (final i in r.hyperLocal) p('- ${i.title}: ${i.problem}'),
        pw.SizedBox(height: 16),
        pw.Text(r.disclaimer, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    ));
    return doc;
  }

  /// Built-in PDF fonts only cover basic Latin, so swap symbols they cannot draw.
  static String _clean(String t) => t
      .replaceAll('₹', 'Rs. ')
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('’', "'")
      .replaceAll('×', 'x')
      .replaceAll('·', '-')
      .replaceAll('≥', '>=')
      .replaceAll('≤', '<=');
}
