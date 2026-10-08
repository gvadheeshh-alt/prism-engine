import 'dart:math' as math;

import '../models/models.dart';

/// Adapter interface: plug a real job-postings API in here later (e.g. a scraper or partner feed).
abstract class JobMarketSource {
  /// Returns careerId -> current YoY job-posting growth (%).
  Future<Map<String, double>> fetchVelocity(List<Career> careers);
}

/// Demo source: a gentle random walk around the seed values, clearly labelled "simulated" in the UI.
class SimulatedJobFeed implements JobMarketSource {
  final math.Random _rng;
  final Map<String, double> _current = {};
  SimulatedJobFeed({int seed = 42}) : _rng = math.Random(seed);

  @override
  Future<Map<String, double>> fetchVelocity(List<Career> careers) async {
    for (final c in careers) {
      final base = c.market.jobVelocity;
      final prev = _current[c.id] ?? base;
      final step = (_rng.nextDouble() - 0.5) * 3; // ±1.5 points per tick
      final pulledBack = prev + step + (base - prev) * 0.1; // drift back toward the seed value
      _current[c.id] = pulledBack.clamp(base - 8, base + 8).toDouble();
    }
    return Map.of(_current);
  }
}
