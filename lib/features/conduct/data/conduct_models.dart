/// Models for the Conduct domain. Mirrors the JavaFX `StudentConductRecord`
/// DTO and `ConductRatings` enum.

/// The five conduct ratings (mirrors `ConductRatings`).
class ConductRatings {
  static const excellent = 'EXCELLENT';
  static const veryGood = 'VERY_GOOD';
  static const good = 'GOOD';
  static const fair = 'FAIR';
  static const notToExpectation = 'NOT_TO_EXPECTATION';

  static const all = [excellent, veryGood, good, fair, notToExpectation];

  static String label(String raw) {
    return switch (raw.toUpperCase()) {
      excellent => 'Excellent',
      veryGood => 'Very Good',
      good => 'Good',
      fair => 'Fair',
      notToExpectation => 'Not to Expectation',
      _ => raw,
    };
  }
}

/// A conduct category — the six rated dimensions. Kept as a small value type so
/// the rubric UI can iterate them without repeating field plumbing.
class ConductCategory {
  final String key; // matches the record field / payload key
  final String label;

  const ConductCategory(this.key, this.label);

  static const all = [
    ConductCategory('regular', 'Regular'),
    ConductCategory('punctual', 'Punctual'),
    ConductCategory('physicalAppearance', 'Physical Appearance'),
    ConductCategory('social', 'Social'),
    ConductCategory('emotional', 'Emotional'),
    ConductCategory('cognitiveSkills', 'Cognitive Skills'),
  ];
}

/// One student's conduct record — `GET /staff/v1/conduct-records` returns a
/// list of these, and `PUT /staff/v1/save-conduct-record` saves one.
class StudentConductRecord {
  final String studentId;
  final String studentName;
  final String semesterId;

  // The six ratings (each a ConductRatings value, possibly empty if unset).
  final String regular;
  final String punctual;
  final String physicalAppearance;
  final String social;
  final String emotional;
  final String cognitiveSkills;

  final String conductRemark;
  final String peculiarIssue;

  const StudentConductRecord({
    required this.studentId,
    required this.studentName,
    required this.semesterId,
    this.regular = '',
    this.punctual = '',
    this.physicalAppearance = '',
    this.social = '',
    this.emotional = '',
    this.cognitiveSkills = '',
    this.conductRemark = '',
    this.peculiarIssue = '',
  });

  /// Read a rating by category key (used by the rubric grid).
  String ratingFor(String key) => switch (key) {
        'regular' => regular,
        'punctual' => punctual,
        'physicalAppearance' => physicalAppearance,
        'social' => social,
        'emotional' => emotional,
        'cognitiveSkills' => cognitiveSkills,
        _ => '',
      };

  /// True once every category has a rating — used to show a "complete" badge.
  bool get isComplete => ConductCategory.all
      .every((c) => ratingFor(c.key).isNotEmpty);

  /// How many of the six categories have been rated.
  int get ratedCount =>
      ConductCategory.all.where((c) => ratingFor(c.key).isNotEmpty).length;

  factory StudentConductRecord.fromJson(Map<String, dynamic> j) =>
      StudentConductRecord(
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? '').toString(),
        semesterId: (j['semesterId'] ?? '').toString(),
        regular: (j['regular'] ?? '').toString(),
        punctual: (j['punctual'] ?? '').toString(),
        physicalAppearance: (j['physicalAppearance'] ?? '').toString(),
        social: (j['social'] ?? '').toString(),
        emotional: (j['emotional'] ?? '').toString(),
        cognitiveSkills: (j['cognitiveSkills'] ?? '').toString(),
        conductRemark: (j['conductRemark'] ?? '').toString(),
        peculiarIssue: (j['peculiarIssue'] ?? '').toString(),
      );

  /// Body for `PUT /staff/v1/save-conduct-record`.
  Map<String, dynamic> toSaveJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'semesterId': semesterId,
        'regular': regular,
        'punctual': punctual,
        'physicalAppearance': physicalAppearance,
        'social': social,
        'emotional': emotional,
        'cognitiveSkills': cognitiveSkills,
        'conductRemark': conductRemark,
        'peculiarIssue': peculiarIssue,
      };

  StudentConductRecord copyWith({
    String? regular,
    String? punctual,
    String? physicalAppearance,
    String? social,
    String? emotional,
    String? cognitiveSkills,
    String? conductRemark,
    String? peculiarIssue,
  }) =>
      StudentConductRecord(
        studentId: studentId,
        studentName: studentName,
        semesterId: semesterId,
        regular: regular ?? this.regular,
        punctual: punctual ?? this.punctual,
        physicalAppearance: physicalAppearance ?? this.physicalAppearance,
        social: social ?? this.social,
        emotional: emotional ?? this.emotional,
        cognitiveSkills: cognitiveSkills ?? this.cognitiveSkills,
        conductRemark: conductRemark ?? this.conductRemark,
        peculiarIssue: peculiarIssue ?? this.peculiarIssue,
      );

  /// Set a rating by category key, returning a new record.
  StudentConductRecord withRating(String key, String value) => switch (key) {
        'regular' => copyWith(regular: value),
        'punctual' => copyWith(punctual: value),
        'physicalAppearance' => copyWith(physicalAppearance: value),
        'social' => copyWith(social: value),
        'emotional' => copyWith(emotional: value),
        'cognitiveSkills' => copyWith(cognitiveSkills: value),
        _ => this,
      };
}
