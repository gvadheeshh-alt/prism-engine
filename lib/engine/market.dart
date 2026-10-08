import '../models/models.dart';
import 'math_utils.dart';

/// Ranges across all careers, used to normalise market signals to 0..1.
class MarketStats {
  final double minVelocity, maxVelocity, minGrowth, maxGrowth;
  final List<double> sortedVelocities;
  const MarketStats(this.minVelocity, this.maxVelocity, this.minGrowth, this.maxGrowth, this.sortedVelocities);

  factory MarketStats.from(List<Career> careers) {
    final v = careers.map<double>((c) => c.market.jobVelocity).toList()..sort();
    final g = careers.map<double>((c) => c.market.salaryGrowthPct).toList();
    double lo(double a, double b) => a < b ? a : b;
    double hi(double a, double b) => a > b ? a : b;
    return MarketStats(v.first, v.last, g.reduce(lo), g.reduce(hi), v);
  }

  /// Share of careers with slower job growth (0..1). Using rank instead of min-max stops one
  /// outlier (a very fast-growing field) from giving the same few careers a big bonus for everyone.
  double velocityRank(double v) {
    if (sortedVelocities.length < 2) return 0.5;
    final below = sortedVelocities.where((x) => x < v).length;
    return clamp01(below / (sortedVelocities.length - 1));
  }
}

class MarketResult {
  final double value, geoDemand;
  final List<RegionDemand> demand;
  final Trace trace;
  const MarketResult(this.value, this.geoDemand, this.demand, this.trace);
}

bool regionInRange(Region r, StudentContext ctx) => switch (ctx.mobility) {
      Mobility.abroad => true,
      Mobility.india => !r.isAbroad,
      Mobility.state => !r.isAbroad && r.state.toLowerCase() == ctx.state.toLowerCase(),
      Mobility.local => !r.isAbroad && r.name.toLowerCase() == ctx.district.toLowerCase(),
    };

/// Stage 3, step 5: market score for a career, personalised to how far the student will move.
/// M = 0.35 × job velocity + 0.25 × (1 − disruption) + 0.20 × salary growth + 0.20 × geo demand
MarketResult marketScore(Career c, StudentContext ctx, List<Region> regions, MarketStats stats) {
  final m = c.market;
  final velocity = stats.velocityRank(m.jobVelocity);
  final growth = minMax(m.salaryGrowthPct, stats.minGrowth, stats.maxGrowth);

  final demand = <RegionDemand>[
    for (final r in regions) RegionDemand(r, m.regionalDemand[r.id] ?? 0, regionInRange(r, ctx)),
  ]..sort((a, b) => b.demand.compareTo(a.demand));

  final inRange = demand.where((d) => d.inRange).toList();
  double geo;
  String geoNote;
  if (inRange.isNotEmpty) {
    geo = inRange.first.demand;
    geoNote = 'Best in your range: ${inRange.first.region.name}';
  } else {
    // Nothing inside the student's radius: fall back to the home state at a 20% discount.
    final sameState = demand.where((d) => d.region.state.toLowerCase() == ctx.state.toLowerCase()).toList();
    geo = sameState.isNotEmpty ? 0.8 * sameState.first.demand : 0.5;
    geoNote = 'No listed hub in your range; using nearest state hub × 0.8';
  }

  final value = clamp01(0.35 * velocity + 0.25 * (1 - m.disruptionIndex) + 0.20 * growth + 0.20 * geo);
  return MarketResult(
    value,
    geo,
    demand,
    Trace(
      metric: 'Market',
      formula: 'M = 0.35 × job-growth rank + 0.25 × (1 − disruption) + 0.20 × salary growth + 0.20 × geo demand',
      inputs: {
        'Job-posting growth': '${m.jobVelocity.toStringAsFixed(0)}% a year, faster than ${(velocity * 100).round()}% of careers',
        'Automation / AI exposure': round2(m.disruptionIndex),
        'Salary growth': '${m.salaryGrowthPct.toStringAsFixed(0)}% a year → ${round2(growth)}',
        'Geo demand': '${round2(geo)} ($geoNote)',
      },
      value: value,
    ),
  );
}
