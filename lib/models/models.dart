// PRISM Engine core models.
// Convention: money = whole INR (int). Scores/normalized values = 0..1 (double),
// unless the name ends in "100" (0..100 display scale).

// ───────────── Dimensions (15-dim vector space) ─────────────

enum DimGroup { riasec, aptitude, workStyle }

enum Dimension {
  realistic(DimGroup.riasec, 'Realistic (hands-on)'),
  investigative(DimGroup.riasec, 'Investigative (curious)'),
  artistic(DimGroup.riasec, 'Artistic'),
  social(DimGroup.riasec, 'Social (helping)'),
  enterprising(DimGroup.riasec, 'Enterprising (leading)'),
  conventional(DimGroup.riasec, 'Conventional (organised)'),
  numerical(DimGroup.aptitude, 'Numerical'),
  logical(DimGroup.aptitude, 'Logical'),
  verbal(DimGroup.aptitude, 'Verbal'),
  spatial(DimGroup.aptitude, 'Spatial'),
  creative(DimGroup.aptitude, 'Creative'),
  openness(DimGroup.workStyle, 'Openness'),
  conscientiousness(DimGroup.workStyle, 'Discipline'),
  collaboration(DimGroup.workStyle, 'Teamwork'),
  riskTolerance(DimGroup.workStyle, 'Risk tolerance');

  const Dimension(this.group, this.label);
  final DimGroup group;
  final String label;

  String get short => switch (this) {
        Dimension.realistic => 'R',
        Dimension.investigative => 'I',
        Dimension.artistic => 'A',
        Dimension.social => 'S',
        Dimension.enterprising => 'E',
        Dimension.conventional => 'C',
        Dimension.numerical => 'Num',
        Dimension.logical => 'Log',
        Dimension.verbal => 'Verb',
        Dimension.spatial => 'Spat',
        Dimension.creative => 'Crea',
        Dimension.openness => 'Open',
        Dimension.conscientiousness => 'Disc',
        Dimension.collaboration => 'Team',
        Dimension.riskTolerance => 'Risk',
      };
}

Dimension? dimensionByName(String? name) {
  for (final d in Dimension.values) {
    if (d.name == name) return d;
  }
  return null;
}

/// A full 15-dim vector, every value 0..1. Missing keys read as 0.
class Vector15 {
  final Map<Dimension, double> values;
  const Vector15(this.values);

  double operator [](Dimension d) => values[d] ?? 0;

  factory Vector15.fromJson(Map<String, dynamic> j) => Vector15({
        for (final d in Dimension.values) d: (j[d.name] as num?)?.toDouble() ?? 0,
      });
  Map<String, dynamic> toJson() => {for (final d in Dimension.values) d.name: this[d]};
}

// ───────────── Shared enums ─────────────

enum Mobility { local, state, india, abroad }

enum StudyLevel { class9, class10, class11, class12, ug, pg }

enum AcademicStream { sciencePcm, sciencePcb, sciencePcmb, commerce, humanities, vocational, undecided }

enum MarksBand { below50, b50to60, b60to75, b75to90, above90 }

enum LoanComfort { none, moderate, high }

enum SocialCategory { general, obc, sc, st, ews }

enum Gender { female, male, other, preferNot }

enum CareerCluster {
  engineeringTech,
  dataAi,
  healthMedicine,
  lifeSciences,
  designArts,
  mediaAnimation,
  businessFinance,
  lawGovernance,
  educationSocial,
  agriEnvironment,
  manufacturingSkilled
}

enum RouteTier { govt, private, distance, online, lateralEntry }

enum ConflictBand { aligned, mild, significant, high }

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

T? enumOrNull<T extends Enum>(List<T> values, Object? name) {
  for (final e in values) {
    if (e.name == name) return e;
  }
  return null;
}

// ───────────── Questions (assets/data/questions.json) ─────────────

/// likert: agree/disagree. choice: "which would you rather do?" between two interest types.
/// aptitude: timed puzzle. selfRating: 1..5 self-assessment.
enum QuestionType { likert, choice, aptitude, selfRating }

class Question {
  final String id, text;
  final QuestionType type;
  final Dimension dimension;
  final bool reverse;
  final List<String> options;
  final int answerIndex;
  final int seconds;

  /// For choice questions: the interest type each option stands for (same order as [options]).
  final List<Dimension> optionDims;

  const Question({
    required this.id,
    required this.text,
    required this.type,
    required this.dimension,
    this.reverse = false,
    this.options = const [],
    this.answerIndex = -1,
    this.seconds = 0,
    this.optionDims = const [],
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as String,
        text: j['text'] as String,
        type: enumByName(QuestionType.values, j['type'], QuestionType.likert),
        dimension: dimensionByName(j['dimension'] as String?) ?? Dimension.openness,
        reverse: j['reverse'] as bool? ?? false,
        options: List<String>.from(j['options'] as List? ?? const []),
        answerIndex: j['answerIndex'] as int? ?? -1,
        seconds: j['seconds'] as int? ?? 0,
        optionDims: [
          for (final d in (j['optionDims'] as List? ?? const []))
            if (dimensionByName(d as String) != null) dimensionByName(d)!
        ],
      );
}

/// Raw answers collected by the quiz. Values: likert 1..5, selfRating 1..5, aptitude correct/incorrect.
class StudentAnswers {
  final Map<String, int> likert;
  final Map<String, int> choice; // questionId -> index of the chosen option
  final Map<String, bool> aptitude;
  final Map<String, int> selfRating;

  StudentAnswers({Map<String, int>? likert, Map<String, int>? choice, Map<String, bool>? aptitude, Map<String, int>? selfRating})
      : likert = likert ?? {},
        choice = choice ?? {},
        aptitude = aptitude ?? {},
        selfRating = selfRating ?? {};
}

// ───────────── Stage 1: inputs ─────────────

class StudentContext {
  final StudyLevel level;
  final AcademicStream stream;
  final MarksBand marksBand;
  final String state, district;
  final Mobility mobility;
  final List<String> dreamCareerIds; // max 3
  final Gender? gender;
  final SocialCategory? category;

  const StudentContext({
    required this.level,
    required this.stream,
    required this.marksBand,
    required this.state,
    required this.district,
    required this.mobility,
    required this.dreamCareerIds,
    this.gender,
    this.category,
  });

  factory StudentContext.fromJson(Map<String, dynamic> j) => StudentContext(
        level: enumByName(StudyLevel.values, j['level'], StudyLevel.class12),
        stream: enumByName(AcademicStream.values, j['stream'], AcademicStream.undecided),
        marksBand: enumByName(MarksBand.values, j['marksBand'], MarksBand.b60to75),
        state: j['state'] as String? ?? '',
        district: j['district'] as String? ?? '',
        mobility: enumByName(Mobility.values, j['mobility'], Mobility.state),
        dreamCareerIds: List<String>.from(j['dreamCareerIds'] as List? ?? const []),
        gender: enumOrNull(Gender.values, j['gender']),
        category: enumOrNull(SocialCategory.values, j['category']),
      );

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'stream': stream.name,
        'marksBand': marksBand.name,
        'state': state,
        'district': district,
        'mobility': mobility.name,
        'dreamCareerIds': dreamCareerIds,
        'gender': gender?.name,
        'category': category?.name,
      };
}

/// Output of normalizeStudent()
class StudentVector {
  final String studentId, familyCode, name;
  final Vector15 dims;
  final StudentContext context;
  final DateTime completedAt;

  const StudentVector({
    required this.studentId,
    required this.familyCode,
    required this.name,
    required this.dims,
    required this.context,
    required this.completedAt,
  });

  factory StudentVector.fromJson(Map<String, dynamic> j) => StudentVector(
        studentId: j['studentId'] as String,
        familyCode: j['familyCode'] as String,
        name: j['name'] as String? ?? 'Student',
        dims: Vector15.fromJson(j['dims'] as Map<String, dynamic>),
        context: StudentContext.fromJson(j['context'] as Map<String, dynamic>),
        completedAt: DateTime.tryParse(j['completedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'familyCode': familyCode,
        'name': name,
        'dims': dims.toJson(),
        'context': context.toJson(),
        'completedAt': completedAt.toIso8601String(),
      };
}

class ParentProfile {
  final String familyCode;
  final int annualIncomeINR, savingsForEducationINR, maxMonthlyEmiINR, expectedSalaryAt25INR;
  final LoanComfort loanComfort;
  final double riskAppetite; // 0 = stable govt/PSU ... 1 = startup/creative
  final List<String> preferredCareerIds; // max 3
  final int preferredYearsToEarning;
  final Mobility relocationAcceptance;
  final SocialCategory? category;
  final Gender? childGender;
  final bool firstGenerationLearner;
  final bool disability;
  final DateTime completedAt;

  const ParentProfile({
    required this.familyCode,
    required this.annualIncomeINR,
    required this.savingsForEducationINR,
    required this.maxMonthlyEmiINR,
    required this.expectedSalaryAt25INR,
    required this.loanComfort,
    required this.riskAppetite,
    required this.preferredCareerIds,
    required this.preferredYearsToEarning,
    required this.relocationAcceptance,
    this.category,
    this.childGender,
    this.firstGenerationLearner = false,
    this.disability = false,
    required this.completedAt,
  });

  factory ParentProfile.fromJson(Map<String, dynamic> j) => ParentProfile(
        familyCode: j['familyCode'] as String,
        annualIncomeINR: (j['annualIncomeINR'] as num?)?.toInt() ?? 0,
        savingsForEducationINR: (j['savingsForEducationINR'] as num?)?.toInt() ?? 0,
        maxMonthlyEmiINR: (j['maxMonthlyEmiINR'] as num?)?.toInt() ?? 0,
        expectedSalaryAt25INR: (j['expectedSalaryAt25INR'] as num?)?.toInt() ?? 0,
        loanComfort: enumByName(LoanComfort.values, j['loanComfort'], LoanComfort.none),
        riskAppetite: (j['riskAppetite'] as num?)?.toDouble() ?? 0.5,
        preferredCareerIds: List<String>.from(j['preferredCareerIds'] as List? ?? const []),
        preferredYearsToEarning: (j['preferredYearsToEarning'] as num?)?.toInt() ?? 5,
        relocationAcceptance: enumByName(Mobility.values, j['relocationAcceptance'], Mobility.state),
        category: enumOrNull(SocialCategory.values, j['category']),
        childGender: enumOrNull(Gender.values, j['childGender']),
        firstGenerationLearner: j['firstGenerationLearner'] as bool? ?? false,
        disability: j['disability'] as bool? ?? false,
        completedAt: DateTime.tryParse(j['completedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'familyCode': familyCode,
        'annualIncomeINR': annualIncomeINR,
        'savingsForEducationINR': savingsForEducationINR,
        'maxMonthlyEmiINR': maxMonthlyEmiINR,
        'expectedSalaryAt25INR': expectedSalaryAt25INR,
        'loanComfort': loanComfort.name,
        'riskAppetite': riskAppetite,
        'preferredCareerIds': preferredCareerIds,
        'preferredYearsToEarning': preferredYearsToEarning,
        'relocationAcceptance': relocationAcceptance.name,
        'category': category?.name,
        'childGender': childGender?.name,
        'firstGenerationLearner': firstGenerationLearner,
        'disability': disability,
        'completedAt': completedAt.toIso8601String(),
      };
}

// ───────────── Seed data (assets/data/*.json) ─────────────

class EducationRoute {
  final String id, label;
  final RouteTier tier;
  final int years, tuitionPerYearINR, livingPerYearINR, coachingINR, examFeesINR;
  final List<String> entryExamIds;

  const EducationRoute({
    required this.id,
    required this.label,
    required this.tier,
    required this.years,
    required this.tuitionPerYearINR,
    required this.livingPerYearINR,
    required this.coachingINR,
    required this.examFeesINR,
    required this.entryExamIds,
  });

  /// TC = (tuition + living) × years + coaching + exam fees
  int get totalCostINR => (tuitionPerYearINR + livingPerYearINR) * years + coachingINR + examFeesINR;

  factory EducationRoute.fromJson(Map<String, dynamic> j) => EducationRoute(
        id: j['id'] as String,
        label: j['label'] as String,
        tier: enumByName(RouteTier.values, j['tier'], RouteTier.private),
        years: (j['years'] as num).toInt(),
        tuitionPerYearINR: (j['tuitionPerYearINR'] as num).toInt(),
        livingPerYearINR: (j['livingPerYearINR'] as num).toInt(),
        coachingINR: (j['coachingINR'] as num?)?.toInt() ?? 0,
        examFeesINR: (j['examFeesINR'] as num?)?.toInt() ?? 0,
        entryExamIds: List<String>.from(j['entryExamIds'] as List? ?? const []),
      );
}

class CareerMarket {
  final double jobVelocity; // YoY % growth in postings
  final double disruptionIndex; // 0..1 automation/AI exposure
  final double salaryGrowthPct; // CAGR %
  final Map<String, double> regionalDemand; // regionId -> 0..1

  const CareerMarket({
    required this.jobVelocity,
    required this.disruptionIndex,
    required this.salaryGrowthPct,
    required this.regionalDemand,
  });

  CareerMarket copyWith({double? jobVelocity}) => CareerMarket(
        jobVelocity: jobVelocity ?? this.jobVelocity,
        disruptionIndex: disruptionIndex,
        salaryGrowthPct: salaryGrowthPct,
        regionalDemand: regionalDemand,
      );

  factory CareerMarket.fromJson(Map<String, dynamic> j) => CareerMarket(
        jobVelocity: (j['jobVelocity'] as num).toDouble(),
        disruptionIndex: (j['disruptionIndex'] as num).toDouble(),
        salaryGrowthPct: (j['salaryGrowthPct'] as num).toDouble(),
        regionalDemand: (j['regionalDemand'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
}

class Career {
  final String id, name, summary;
  final CareerCluster cluster;
  final bool emerging;
  final List<AcademicStream> eligibleStreams; // empty = any stream
  final Vector15 requirement; // R
  final Vector15 importance; // W
  final List<EducationRoute> routes;
  final int startingSalaryINR, year5SalaryINR, year10SalaryINR; // annual
  final CareerMarket market;
  final List<String> relatedExamIds;
  final bool illustrative;

  const Career({
    required this.id,
    required this.name,
    required this.summary,
    required this.cluster,
    required this.emerging,
    required this.eligibleStreams,
    required this.requirement,
    required this.importance,
    required this.routes,
    required this.startingSalaryINR,
    required this.year5SalaryINR,
    required this.year10SalaryINR,
    required this.market,
    required this.relatedExamIds,
    this.illustrative = true,
  });

  Career withMarket(CareerMarket m) => Career(
        id: id,
        name: name,
        summary: summary,
        cluster: cluster,
        emerging: emerging,
        eligibleStreams: eligibleStreams,
        requirement: requirement,
        importance: importance,
        routes: routes,
        startingSalaryINR: startingSalaryINR,
        year5SalaryINR: year5SalaryINR,
        year10SalaryINR: year10SalaryINR,
        market: m,
        relatedExamIds: relatedExamIds,
        illustrative: illustrative,
      );

  factory Career.fromJson(Map<String, dynamic> j) {
    final salary = j['salary'] as Map<String, dynamic>;
    return Career(
      id: j['id'] as String,
      name: j['name'] as String,
      summary: j['summary'] as String? ?? '',
      cluster: enumByName(CareerCluster.values, j['cluster'], CareerCluster.engineeringTech),
      emerging: j['emerging'] as bool? ?? false,
      eligibleStreams: [
        for (final s in (j['eligibleStreams'] as List? ?? const [])) enumByName(AcademicStream.values, s, AcademicStream.undecided)
      ],
      requirement: Vector15.fromJson(j['requirement'] as Map<String, dynamic>),
      importance: Vector15.fromJson(j['importance'] as Map<String, dynamic>),
      routes: [for (final r in j['routes'] as List) EducationRoute.fromJson(r as Map<String, dynamic>)],
      startingSalaryINR: (salary['startingINR'] as num).toInt(),
      year5SalaryINR: (salary['year5INR'] as num).toInt(),
      year10SalaryINR: (salary['year10INR'] as num).toInt(),
      market: CareerMarket.fromJson(j['market'] as Map<String, dynamic>),
      relatedExamIds: List<String>.from(j['relatedExamIds'] as List? ?? const []),
    );
  }
}

class Exam {
  final String id, name, conductingBody, eligibility, officialUrl;
  final List<String> typicalMonths; // UI always adds "Verify on the official website"

  const Exam({
    required this.id,
    required this.name,
    required this.conductingBody,
    required this.eligibility,
    required this.officialUrl,
    required this.typicalMonths,
  });

  factory Exam.fromJson(Map<String, dynamic> j) => Exam(
        id: j['id'] as String,
        name: j['name'] as String,
        conductingBody: j['conductingBody'] as String,
        eligibility: j['eligibility'] as String,
        officialUrl: j['officialUrl'] as String,
        typicalMonths: List<String>.from(j['typicalMonths'] as List? ?? const []),
      );
}

class Scholarship {
  final String id, name, provider, officialUrl, note;
  final int amountINR; // per year, illustrative
  final int? maxIncomeINR;
  final List<String> states;
  final List<Gender> genders;
  final List<SocialCategory> categories;
  final List<StudyLevel> levels;
  final List<CareerCluster> clusters;
  final MarksBand? minMarksBand;
  final bool requiresFirstGen, requiresDisability;

  const Scholarship({
    required this.id,
    required this.name,
    required this.provider,
    required this.officialUrl,
    required this.note,
    required this.amountINR,
    this.maxIncomeINR,
    this.states = const [],
    this.genders = const [],
    this.categories = const [],
    this.levels = const [],
    this.clusters = const [],
    this.minMarksBand,
    this.requiresFirstGen = false,
    this.requiresDisability = false,
  });

  factory Scholarship.fromJson(Map<String, dynamic> j) {
    final r = j['rules'] as Map<String, dynamic>? ?? const {};
    List<T> list<T extends Enum>(String key, List<T> values) => [
          for (final v in (r[key] as List? ?? const []))
            if (enumOrNull(values, v) != null) enumOrNull(values, v)!
        ];
    return Scholarship(
      id: j['id'] as String,
      name: j['name'] as String,
      provider: j['provider'] as String,
      officialUrl: j['officialUrl'] as String,
      note: j['note'] as String? ?? '',
      amountINR: (j['amountINR'] as num).toInt(),
      maxIncomeINR: (r['maxIncomeINR'] as num?)?.toInt(),
      states: List<String>.from(r['states'] as List? ?? const []),
      genders: list('genders', Gender.values),
      categories: list('categories', SocialCategory.values),
      levels: list('levels', StudyLevel.values),
      clusters: list('clusters', CareerCluster.values),
      minMarksBand: enumOrNull(MarksBand.values, r['minMarksBand']),
      requiresFirstGen: r['requiresFirstGen'] as bool? ?? false,
      requiresDisability: r['requiresDisability'] as bool? ?? false,
    );
  }
}

class Region {
  final String id, name, state;
  final double lat, lng;
  final bool isMetro, isAbroad;

  const Region({
    required this.id,
    required this.name,
    required this.state,
    required this.lat,
    required this.lng,
    required this.isMetro,
    required this.isAbroad,
  });

  factory Region.fromJson(Map<String, dynamic> j) => Region(
        id: j['id'] as String,
        name: j['name'] as String,
        state: j['state'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        isMetro: j['isMetro'] as bool? ?? false,
        isAbroad: j['isAbroad'] as bool? ?? false,
      );
}

class IdeaTemplate {
  final String title, problem;
  final List<Dimension> strengths;
  const IdeaTemplate({required this.title, required this.problem, required this.strengths});

  factory IdeaTemplate.fromJson(Map<String, dynamic> j) => IdeaTemplate(
        title: j['title'] as String,
        problem: j['problem'] as String,
        strengths: [
          for (final s in (j['strengths'] as List? ?? const []))
            if (dimensionByName(s as String) != null) dimensionByName(s)!
        ],
      );
}

class IndustryCluster {
  final String name, description;
  final List<String> relatedCareerIds;
  final List<IdeaTemplate> ideas;
  const IndustryCluster(
      {required this.name, required this.description, required this.relatedCareerIds, required this.ideas});

  factory IndustryCluster.fromJson(Map<String, dynamic> j) => IndustryCluster(
        name: j['name'] as String,
        description: j['description'] as String,
        relatedCareerIds: List<String>.from(j['relatedCareerIds'] as List? ?? const []),
        ideas: [for (final i in (j['ideas'] as List? ?? const [])) IdeaTemplate.fromJson(i as Map<String, dynamic>)],
      );
}

class LocalIndustry {
  final String district, state; // district "*" = generic fallback
  final List<IndustryCluster> clusters;
  const LocalIndustry({required this.district, required this.state, required this.clusters});

  factory LocalIndustry.fromJson(Map<String, dynamic> j) => LocalIndustry(
        district: j['district'] as String,
        state: j['state'] as String,
        clusters: [for (final c in j['clusters'] as List) IndustryCluster.fromJson(c as Map<String, dynamic>)],
      );
}

class Persona {
  final String id, title, blurb;
  final StudentVector student;
  final ParentProfile parent;
  const Persona({required this.id, required this.title, required this.blurb, required this.student, required this.parent});

  factory Persona.fromJson(Map<String, dynamic> j) => Persona(
        id: j['id'] as String,
        title: j['title'] as String,
        blurb: j['blurb'] as String,
        student: StudentVector.fromJson(j['student'] as Map<String, dynamic>),
        parent: ParentProfile.fromJson(j['parent'] as Map<String, dynamic>),
      );
}

// ───────────── Stage 2 & 3: engine outputs ─────────────

class ScoreWeights {
  final double alpha, beta, gamma, delta, lambda;
  const ScoreWeights({this.alpha = 0.45, this.beta = 0.20, this.gamma = 0.15, this.delta = 0.20, this.lambda = 10});

  double get sum => alpha + beta + gamma + delta;

  ScoreWeights copyWith({double? alpha, double? beta, double? gamma, double? delta, double? lambda}) => ScoreWeights(
        alpha: alpha ?? this.alpha,
        beta: beta ?? this.beta,
        gamma: gamma ?? this.gamma,
        delta: delta ?? this.delta,
        lambda: lambda ?? this.lambda,
      );
}

/// Powers every "How was this calculated?" bottom sheet
class Trace {
  final String metric, formula;
  final Map<String, Object> inputs;
  final double value;
  const Trace({required this.metric, required this.formula, required this.inputs, required this.value});
}

class RouteFinance {
  final String routeId, label;
  final RouteTier tier;
  final int years;
  final int totalCostINR, savingsINR, scholarshipINR, loanCapacityINR;
  final double feasibility; // 0..1
  final double roi; // ratio, can be negative
  final double? paybackYears; // null = no payback within 10 years

  const RouteFinance({
    required this.routeId,
    required this.label,
    required this.tier,
    required this.years,
    required this.totalCostINR,
    required this.savingsINR,
    required this.scholarshipINR,
    required this.loanCapacityINR,
    required this.feasibility,
    required this.roi,
    this.paybackYears,
  });

  int get fundingTotalINR => savingsINR + scholarshipINR + loanCapacityINR;
  bool get viable => feasibility >= 0.6;
}

class FinanceResult {
  final String? cheapestViableRouteId;
  final RouteFinance best;
  final List<RouteFinance> allRoutes;
  final List<ScholarshipMatch> scholarships;
  const FinanceResult(
      {this.cheapestViableRouteId, required this.best, required this.allRoutes, required this.scholarships});
  bool get notViableWithoutAid => !best.viable;
}

class GapAction {
  final String label, resource;
  final String? url;
  const GapAction(this.label, this.resource, [this.url]);
}

class GapItem {
  final Dimension dimension;
  final double required, current;
  final List<GapAction> actions;
  const GapItem({required this.dimension, required this.required, required this.current, required this.actions});
  double get gap => (required - current).clamp(0.0, 1.0).toDouble();
}

class ScoreComponents {
  final double fit, market, feasibility, roiNorm, conflictPenalty;
  const ScoreComponents({
    required this.fit,
    required this.market,
    required this.feasibility,
    required this.roiNorm,
    required this.conflictPenalty,
  });
}

class RegionDemand {
  final Region region;
  final double demand;
  final bool inRange;
  const RegionDemand(this.region, this.demand, this.inRange);
}

class CareerScore {
  final Career career;
  final double prism100;
  final ScoreComponents components;
  final FinanceResult finance;
  final List<GapItem> gaps;
  final List<RegionDemand> demand; // sorted by demand desc
  final List<String> flags; // e.g. "Needs a stream switch"
  final List<Trace> traces;

  const CareerScore({
    required this.career,
    required this.prism100,
    required this.components,
    required this.finance,
    required this.gaps,
    required this.demand,
    required this.flags,
    required this.traces,
  });

  String get careerId => career.id;
}

class BridgeCareer {
  final Career career;
  final double studentFit, parentAlignment, combined;
  const BridgeCareer(this.career, this.studentFit, this.parentAlignment, this.combined);
}

class ConflictResult {
  final double psci100;
  final double preference, risk, salaryGap, relocationTimeline; // components, 0..1
  final List<String> drivers; // top 2, plain language
  final List<BridgeCareer> bridgeCareers;
  final Trace trace;

  const ConflictResult({
    required this.psci100,
    required this.preference,
    required this.risk,
    required this.salaryGap,
    required this.relocationTimeline,
    required this.drivers,
    required this.bridgeCareers,
    required this.trace,
  });

  ConflictBand get band => psci100 <= 25
      ? ConflictBand.aligned
      : psci100 <= 50
          ? ConflictBand.mild
          : psci100 <= 75
              ? ConflictBand.significant
              : ConflictBand.high;
}

class SwotItem {
  final String text, source;
  const SwotItem(this.text, this.source);
}

class Swot {
  final List<SwotItem> strengths, weaknesses, opportunities, threats;
  const Swot({required this.strengths, required this.weaknesses, required this.opportunities, required this.threats});
}

class RoadmapStep {
  final String periodLabel, title; // "2027–28"
  final List<String> actions;
  final List<String> examIds;
  const RoadmapStep({required this.periodLabel, required this.title, required this.actions, required this.examIds});
}

class ScholarshipMatch {
  final Scholarship scholarship;
  final List<String> matchedRules;
  const ScholarshipMatch(this.scholarship, this.matchedRules);
}

class Roadmap {
  final Career career;
  final RouteFinance route;
  final List<RoadmapStep> steps;
  final List<ScholarshipMatch> scholarships;
  const Roadmap({required this.career, required this.route, required this.steps, required this.scholarships});
}

class InnovationIdea {
  final String title, localIndustry, problem;
  final List<Dimension> strengthsUsed;
  final List<String> careerIds;
  final double matchScore;
  const InnovationIdea({
    required this.title,
    required this.localIndustry,
    required this.problem,
    required this.strengthsUsed,
    required this.careerIds,
    required this.matchScore,
  });
}

class EngineResult {
  final String version, familyCode, disclaimer;
  final DateTime generatedAt;
  final ScoreWeights weights;
  final StudentVector student;
  final ParentProfile? parent; // null = student-only mode
  final List<CareerScore> rankings; // sorted by prism100 desc (all careers)
  final ConflictResult? conflict; // null when no parent
  final Swot swot;
  final List<Roadmap> roadmaps; // top 3
  final List<InnovationIdea> hyperLocal; // up to 3
  final String hyperLocalArea;

  const EngineResult({
    required this.version,
    required this.familyCode,
    required this.disclaimer,
    required this.generatedAt,
    required this.weights,
    required this.student,
    this.parent,
    required this.rankings,
    this.conflict,
    required this.swot,
    required this.roadmaps,
    required this.hyperLocal,
    required this.hyperLocalArea,
  });

  CareerScore? scoreFor(String careerId) {
    for (final s in rankings) {
      if (s.careerId == careerId) return s;
    }
    return null;
  }
}
