import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../data/seed_repository.dart';
import '../engine/engine.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../services/job_feed.dart';

class AppState extends ChangeNotifier {
  SeedData? seed;

  /// Official list of states/UTs and their districts (assets/data/india_districts.json).
  Map<String, List<String>> districtsByState = const {};
  List<String> get states => districtsByState.keys.toList();
  bool loading = true;
  String? loadError;

  final Map<String, StudentVector> students = {};
  final Map<String, ParentProfile> parents = {};

  String? activeCode;
  String? selectedCareerId;
  ScoreWeights weights = const ScoreWeights();
  EngineResult? result;

  AppLang lang = AppLang.en;
  ThemeMode themeMode = ThemeMode.light; // light by default; the moon/sun button switches

  bool liveFeed = false;
  Map<String, double> velocityOverrides = {};
  final JobMarketSource _feed = SimulatedJobFeed();
  Timer? _feedTimer;

  static const _kStudents = 'prism.students';
  static const _kParents = 'prism.parents';

  String t(String key) => tr(lang, key);

  Future<void> init() async {
    try {
      seed = await loadSeedData();
      districtsByState = await _loadDistricts();
      await _restore();
    } catch (e) {
      loadError = 'Could not load data: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<Map<String, List<String>>> _loadDistricts() async {
    try {
      final raw = jsonDecode(await rootBundle.loadString('assets/data/india_districts.json')) as Map<String, dynamic>;
      return {
        for (final s in (raw['states'] as List).cast<Map<String, dynamic>>())
          s['name'] as String: List<String>.from(s['districts'] as List),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_kStudents);
      final p = prefs.getString(_kParents);
      if (s != null) {
        (jsonDecode(s) as Map<String, dynamic>).forEach((k, v) => students[k] = StudentVector.fromJson(v as Map<String, dynamic>));
      }
      if (p != null) {
        (jsonDecode(p) as Map<String, dynamic>).forEach((k, v) => parents[k] = ParentProfile.fromJson(v as Map<String, dynamic>));
      }
    } catch (_) {
      // Corrupt local data should never block the app.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStudents, jsonEncode(students.map((k, v) => MapEntry(k, v.toJson()))));
      await prefs.setString(_kParents, jsonEncode(parents.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (_) {}
  }

  /// 6-character family code without look-alike characters (no 0/O, 1/I).
  String newFamilyCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = math.Random();
    String code;
    do {
      code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    } while (students.containsKey(code));
    return code;
  }

  bool hasStudent(String code) => students.containsKey(code.trim().toUpperCase());

  Future<void> saveStudent(StudentVector s) async {
    students[s.familyCode] = s;
    await _persist();
    notifyListeners();
  }

  Future<void> saveParent(ParentProfile p) async {
    parents[p.familyCode] = p;
    await _persist();
    notifyListeners();
  }

  void openFamily(String code) {
    activeCode = code.trim().toUpperCase();
    selectedCareerId = null;
    _recompute();
  }

  void loadPersona(Persona p) {
    students[p.student.familyCode] = p.student;
    parents[p.parent.familyCode] = p.parent;
    weights = const ScoreWeights();
    openFamily(p.student.familyCode);
  }

  void _recompute() {
    final s = seed;
    final code = activeCode;
    if (s == null || code == null || students[code] == null) {
      result = null;
    } else {
      result = runEngine(
        student: students[code]!,
        parent: parents[code],
        seed: s,
        weights: weights,
        velocityOverrides: liveFeed ? velocityOverrides : const {},
      );
    }
    notifyListeners();
  }

  void setWeights(ScoreWeights w) {
    weights = w;
    _recompute();
  }

  void resetWeights() => setWeights(const ScoreWeights());

  void selectCareer(String id) {
    selectedCareerId = id;
    notifyListeners();
  }

  CareerScore? get selectedScore {
    final r = result;
    if (r == null || r.rankings.isEmpty) return null;
    return (selectedCareerId == null ? null : r.scoreFor(selectedCareerId!)) ?? r.rankings.first;
  }

  void setLang(AppLang l) {
    lang = l;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setLiveFeed(bool on) {
    liveFeed = on;
    _feedTimer?.cancel();
    if (on) {
      _tick();
      _feedTimer = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
    } else {
      velocityOverrides = {};
      _recompute();
    }
    notifyListeners();
  }

  Future<void> _tick() async {
    final s = seed;
    if (s == null) return;
    velocityOverrides = await _feed.fetchVelocity(s.careers);
    _recompute();
  }

  @override
  void dispose() {
    _feedTimer?.cancel();
    super.dispose();
  }
}
