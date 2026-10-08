/// Indian-style money formatting: ₹45k, ₹3.5 L, ₹1.20 Cr.
String inr(num v, {String symbol = '₹'}) {
  final a = v.abs();
  final sign = v < 0 ? '-' : '';
  if (a >= 10000000) return '$sign$symbol${(a / 10000000).toStringAsFixed(2)} Cr';
  if (a >= 100000) return '$sign$symbol${(a / 100000).toStringAsFixed(1)} L';
  if (a >= 1000) return '$sign$symbol${(a / 1000).toStringAsFixed(0)}k';
  return '$sign$symbol${a.toStringAsFixed(0)}';
}

/// PDF-safe version (built-in PDF fonts have no rupee glyph).
String inrPdf(num v) => inr(v, symbol: 'Rs. ');

String pct(double v) => '${(v * 100).round()}%';

String roiText(double roi) => roi > 50 ? 'more than 50x' : '${roi.toStringAsFixed(1)}x';

String titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
