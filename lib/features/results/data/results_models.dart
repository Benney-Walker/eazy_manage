/// Models for the Results (Enter Scores) domain. Mirrors the JavaFX
/// `StudentsScoresTable` / `SubjectScores` DTOs and the score formula from
/// `EnterScoresController`.

/// The five editable score components with their maximum values, in display
/// order. Kept as data so the grid can render columns without repeating
/// per-field plumbing.
class ScoreColumn {
  final String key;
  final String label;
  final String shortLabel;
  final double max;

  const ScoreColumn(this.key, this.label, this.shortLabel, this.max);

  static const classTest1 =
      ScoreColumn('classTest1Score', 'Class Test 1', 'CT1', 30);
  static const groupWork =
      ScoreColumn('groupWorkScore', 'Group Work', 'GW', 20);
  static const classTest2 =
      ScoreColumn('classTest2Score', 'Class Test 2', 'CT2', 30);
  static const project = ScoreColumn('projectScore', 'Project', 'Proj', 20);
  static const exam = ScoreColumn('examScore', 'Exam', 'Exam', 100);

  /// All editable columns, in order.
  static const all = [classTest1, groupWork, classTest2, project, exam];
}

/// One student's score row. The five component scores are editable; the class
/// score, calculated exam score, and total are DERIVED live from them, so they
/// are always consistent (no stale computed fields).
///
/// Formula (from EnterScoresController):
///   classScore          = ((ct1 + groupWork + ct2 + project) / 100) * 50
///   calculatedExamScore = (exam / 100) * 50
///   total               = classScore + calculatedExamScore   (out of 100)
class ScoreRow {
  final String studentId;
  final String studentName;

  // Editable components (stored as strings to preserve blank vs 0).
  final String classTest1Score;
  final String groupWorkScore;
  final String classTest2Score;
  final String projectScore;
  final String examScore;

  const ScoreRow({
    required this.studentId,
    required this.studentName,
    this.classTest1Score = '',
    this.groupWorkScore = '',
    this.classTest2Score = '',
    this.projectScore = '',
    this.examScore = '',
  });

  factory ScoreRow.fromJson(Map<String, dynamic> j) => ScoreRow(
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? '').toString(),
        classTest1Score: _clean(j['classTest1Score']),
        groupWorkScore: _clean(j['groupWorkScore']),
        classTest2Score: _clean(j['classTest2Score']),
        projectScore: _clean(j['projectScore']),
        examScore: _clean(j['examScore']),
      );

  /// Read a component by column key.
  String valueFor(String key) => switch (key) {
        'classTest1Score' => classTest1Score,
        'groupWorkScore' => groupWorkScore,
        'classTest2Score' => classTest2Score,
        'projectScore' => projectScore,
        'examScore' => examScore,
        _ => '',
      };

  /// Return a new row with one component set.
  ScoreRow withValue(String key, String value) => switch (key) {
        'classTest1Score' => copyWith(classTest1Score: value),
        'groupWorkScore' => copyWith(groupWorkScore: value),
        'classTest2Score' => copyWith(classTest2Score: value),
        'projectScore' => copyWith(projectScore: value),
        'examScore' => copyWith(examScore: value),
        _ => this,
      };

  double get _ct1 => _parse(classTest1Score);
  double get _gw => _parse(groupWorkScore);
  double get _ct2 => _parse(classTest2Score);
  double get _project => _parse(projectScore);
  double get _exam => _parse(examScore);

  /// Continuous-assessment component, scaled to 50.
  double get classScore => ((_ct1 + _gw + _ct2 + _project) / 100.0) * 50.0;

  /// Exam component, scaled to 50.
  double get calculatedExamScore => (_exam / 100.0) * 50.0;

  /// Overall total, out of 100.
  double get total => classScore + calculatedExamScore;

  /// True if any component has been entered.
  bool get hasAnyScore => [
        classTest1Score,
        groupWorkScore,
        classTest2Score,
        projectScore,
        examScore,
      ].any((s) => s.trim().isNotEmpty);

  /// Body entry for the save-scores array. Sends the components plus the
  /// derived values (the backend stores them; we compute the same way).
  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'classTest1Score': classTest1Score,
        'groupWorkScore': groupWorkScore,
        'classTest2Score': classTest2Score,
        'projectScore': projectScore,
        'classScore': classScore.toStringAsFixed(1),
        'examScore': examScore,
        'calculatedExamScore': calculatedExamScore.toStringAsFixed(1),
      };

  ScoreRow copyWith({
    String? classTest1Score,
    String? groupWorkScore,
    String? classTest2Score,
    String? projectScore,
    String? examScore,
  }) =>
      ScoreRow(
        studentId: studentId,
        studentName: studentName,
        classTest1Score: classTest1Score ?? this.classTest1Score,
        groupWorkScore: groupWorkScore ?? this.groupWorkScore,
        classTest2Score: classTest2Score ?? this.classTest2Score,
        projectScore: projectScore ?? this.projectScore,
        examScore: examScore ?? this.examScore,
      );

  static double _parse(String s) => double.tryParse(s.trim()) ?? 0;

  /// Normalize incoming values: treat null / "null" / "0" placeholders sanely.
  static String _clean(dynamic v) {
    final s = (v ?? '').toString().trim();
    if (s.toLowerCase() == 'null') return '';
    return s;
  }
}

/// The load response — `GET /student/v1/load-subject-students/{subjectId}/{semesterId}`
/// (mirrors `SubjectScores`).
class SubjectScores {
  final String subjectId;
  final String subjectName;
  final List<ScoreRow> rows;

  const SubjectScores({
    required this.subjectId,
    required this.subjectName,
    required this.rows,
  });

  factory SubjectScores.fromJson(Map<String, dynamic> j) => SubjectScores(
        subjectId: (j['subjectId'] ?? '').toString(),
        subjectName: (j['subjectName'] ?? '').toString(),
        rows: (j['scoresTable'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ScoreRow.fromJson)
                .toList() ??
            const [],
      );
}
