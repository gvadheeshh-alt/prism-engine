import 'package:flutter/services.dart' show rootBundle;

import 'seed_data.dart';

/// Loads all seed JSON from assets/data.
Future<SeedData> loadSeedData() async {
  Future<String> load(String name) => rootBundle.loadString('assets/data/$name.json');
  final files = await Future.wait([
    load('careers'),
    load('exams'),
    load('scholarships'),
    load('regions'),
    load('local_industries'),
    load('questions'),
    load('personas'),
  ]);
  return SeedData.fromJsonStrings(
    careers: files[0],
    exams: files[1],
    scholarships: files[2],
    regions: files[3],
    localIndustries: files[4],
    questions: files[5],
    personas: files[6],
  );
}
