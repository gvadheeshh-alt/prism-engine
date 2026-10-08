import 'dart:math' as math;

import '../models/models.dart';

double clamp01(double v) {
  if (v.isNaN) return 0;
  if (v < 0) return 0;
  if (v > 1) return 1;
  return v;
}

/// Min-max normalisation to 0..1. Returns 0.5 when the range is empty.
double minMax(double v, double lo, double hi) => hi == lo ? 0.5 : clamp01((v - lo) / (hi - lo));

final Vector15 onesVector = Vector15({for (final d in Dimension.values) d: 1.0});

/// Weighted Pearson correlation between two 15-dim profiles (-1..1).
/// Compares the SHAPE of the profiles (what stands out), not just their level.
double weightedPearson(Vector15 a, Vector15 b, Vector15 w) {
  double sw = 0, ma = 0, mb = 0;
  for (final d in Dimension.values) {
    sw += w[d];
    ma += w[d] * a[d];
    mb += w[d] * b[d];
  }
  if (sw == 0) return 0;
  ma /= sw;
  mb /= sw;
  double cov = 0, va = 0, vb = 0;
  for (final d in Dimension.values) {
    final da = a[d] - ma, db = b[d] - mb;
    cov += w[d] * da * db;
    va += w[d] * da * da;
    vb += w[d] * db * db;
  }
  if (va == 0 || vb == 0) return 0;
  return cov / math.sqrt(va * vb);
}

/// Present value of [n] equal monthly payments at [monthlyRate].
double presentValueOfAnnuity(double payment, double monthlyRate, int n) {
  if (payment <= 0 || n <= 0) return 0;
  if (monthlyRate == 0) return payment * n;
  return payment * (1 - math.pow(1 + monthlyRate, -n)) / monthlyRate;
}

double round2(double v) => (v * 100).roundToDouble() / 100;
