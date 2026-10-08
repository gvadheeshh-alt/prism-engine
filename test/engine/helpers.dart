import 'dart:io';

import 'package:prism_engine/data/seed_data.dart';
import 'package:prism_engine/models/models.dart';

/// Loads the real seed JSON from disk (tests run from the project root).
SeedData loadSeed() {
  String f(String n) => File('assets/data/$n.json').readAsStringSync();
  return SeedData.fromJsonStrings(
    careers: f('careers'),
    exams: f('exams'),
    scholarships: f('scholarships'),
    regions: f('regions'),
    localIndustries: f('local_industries'),
    questions: f('questions'),
    personas: f('personas'),
  );
}

Persona persona(SeedData s, String id) => s.personas.firstWhere((p) => p.id == id);

Vector15 uniform(double v) => Vector15({for (final d in Dimension.values) d: v});
