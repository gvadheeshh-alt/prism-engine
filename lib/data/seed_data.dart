import 'dart:convert';

import '../models/models.dart';

/// All seed data in one immutable bundle. Pure Dart (no Flutter) so tests can build it from files.
class SeedData {
  final List<Career> careers;
  final List<Exam> exams;
  final List<Scholarship> scholarships;
  final List<Region> regions;
  final List<LocalIndustry> localIndustries;
  final List<Question> questions;
  final List<Persona> personas;

  late final Map<String, Career> careerById = {for (final c in careers) c.id: c};
  late final Map<String, Exam> examById = {for (final e in exams) e.id: e};

  SeedData({
    required this.careers,
    required this.exams,
    required this.scholarships,
    required this.regions,
    required this.localIndustries,
    required this.questions,
    required this.personas,
  });

  factory SeedData.fromJsonStrings({
    required String careers,
    required String exams,
    required String scholarships,
    required String regions,
    required String localIndustries,
    required String questions,
    required String personas,
  }) {
    List<Map<String, dynamic>> list(String s) => (jsonDecode(s) as List).cast<Map<String, dynamic>>();
    return SeedData(
      careers: list(careers).map(Career.fromJson).toList(),
      exams: list(exams).map(Exam.fromJson).toList(),
      scholarships: list(scholarships).map(Scholarship.fromJson).toList(),
      regions: list(regions).map(Region.fromJson).toList(),
      localIndustries: list(localIndustries).map(LocalIndustry.fromJson).toList(),
      questions: list(questions).map(Question.fromJson).toList(),
      personas: list(personas).map(Persona.fromJson).toList(),
    );
  }

  /// Same data with some careers replaced (used by the live job-feed simulator).
  SeedData withCareers(List<Career> newCareers) => SeedData(
        careers: newCareers,
        exams: exams,
        scholarships: scholarships,
        regions: regions,
        localIndustries: localIndustries,
        questions: questions,
        personas: personas,
      );
}
