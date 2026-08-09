/// Models for the Academics domain (Phase 6a: Semesters, Subjects, Grading).
/// Field names mirror the JavaFX DTOs exactly, including the quirks where the
/// list, find, add, and update endpoints use slightly different keys for the
/// same concept.

// ===========================================================================
// SEMESTERS
// ===========================================================================

/// List row — `GET /staff/v1/load-semesters` (mirrors `CachedSemesters`).
/// Note: `semesterId` (lowercase d) here.
class SemesterSummary {
  final String semesterId;
  final String semesterName;
  final String academicYear;

  const SemesterSummary({
    required this.semesterId,
    required this.semesterName,
    required this.academicYear,
  });

  factory SemesterSummary.fromJson(Map<String, dynamic> j) => SemesterSummary(
        semesterId: (j['semesterId'] ?? '').toString(),
        semesterName: (j['semesterName'] ?? '').toString(),
        academicYear: (j['academicYear'] ?? '').toString(),
      );
}

/// Full detail — `GET /admin/v1/search-semester/{id}` (mirrors `FindSemester`)
/// and the body for `PUT /admin/v1/update-semester-info`.
/// Note: `semesterID` (capital D) and `semesterStartDate` / `semesterEndDate`.
class SemesterDetail {
  final String semesterID;
  final String semesterName;
  final String semesterStartDate;
  final String semesterEndDate;
  final String academicYear;

  const SemesterDetail({
    required this.semesterID,
    required this.semesterName,
    required this.semesterStartDate,
    required this.semesterEndDate,
    required this.academicYear,
  });

  factory SemesterDetail.fromJson(Map<String, dynamic> j) => SemesterDetail(
        semesterID: (j['semesterID'] ?? j['semesterId'] ?? '').toString(),
        semesterName: (j['semesterName'] ?? '').toString(),
        semesterStartDate: (j['semesterStartDate'] ?? '').toString(),
        semesterEndDate: (j['semesterEndDate'] ?? '').toString(),
        academicYear: (j['academicYear'] ?? '').toString(),
      );

  Map<String, dynamic> toUpdateJson() => {
        'semesterID': semesterID,
        'semesterName': semesterName,
        'semesterStartDate': semesterStartDate,
        'semesterEndDate': semesterEndDate,
        'academicYear': academicYear,
      };

  SemesterDetail copyWith({
    String? semesterName,
    String? semesterStartDate,
    String? semesterEndDate,
    String? academicYear,
  }) =>
      SemesterDetail(
        semesterID: semesterID,
        semesterName: semesterName ?? this.semesterName,
        semesterStartDate: semesterStartDate ?? this.semesterStartDate,
        semesterEndDate: semesterEndDate ?? this.semesterEndDate,
        academicYear: academicYear ?? this.academicYear,
      );
}

/// Body for `POST /admin/v1/add-semester`.
/// Note: `startDate` / `endDate` (not the `semester*` prefixed variants).
class NewSemesterRequest {
  final String semesterName;
  final String startDate; // ISO yyyy-MM-dd
  final String endDate;
  final String academicYear;

  const NewSemesterRequest({
    required this.semesterName,
    required this.startDate,
    required this.endDate,
    required this.academicYear,
  });

  Map<String, dynamic> toJson() => {
        'semesterName': semesterName,
        'startDate': startDate,
        'endDate': endDate,
        'academicYear': academicYear,
      };
}

// ===========================================================================
// SUBJECTS
// ===========================================================================

/// List row — `GET /staff/v1/load-subjects/{levelId}` (mirrors `SubjectsHolder`).
class SubjectSummary {
  final String subjectId;
  final String subjectName;

  const SubjectSummary({required this.subjectId, required this.subjectName});

  factory SubjectSummary.fromJson(Map<String, dynamic> j) => SubjectSummary(
        subjectId: (j['subjectId'] ?? '').toString(),
        subjectName: (j['subjectName'] ?? '').toString(),
      );
}

/// Full detail — `GET /admin/v1/load-subject-data/{id}` (mirrors `SubjectDTO`)
/// and the body for `PUT /admin/v1/update-subject-details`.
class SubjectDetail {
  final String subjectId;
  final String subjectName;
  final String levelId;

  const SubjectDetail({
    required this.subjectId,
    required this.subjectName,
    required this.levelId,
  });

  factory SubjectDetail.fromJson(Map<String, dynamic> j) => SubjectDetail(
        subjectId: (j['subjectId'] ?? '').toString(),
        subjectName: (j['subjectName'] ?? '').toString(),
        levelId: (j['levelId'] ?? '').toString(),
      );

  Map<String, dynamic> toUpdateJson() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
        'levelId': levelId,
      };

  SubjectDetail copyWith({String? subjectName, String? levelId}) => SubjectDetail(
        subjectId: subjectId,
        subjectName: subjectName ?? this.subjectName,
        levelId: levelId ?? this.levelId,
      );
}

/// Body for `POST /admin/v1/add-subject`. Uses `gradeId` (the target class).
class NewSubjectRequest {
  final String subjectName;
  final String gradeId;

  const NewSubjectRequest({required this.subjectName, required this.gradeId});

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'gradeId': gradeId,
      };
}

// ===========================================================================
// GRADING CRITERIA
// ===========================================================================

/// A grading band — `GET /admin/v1/load-grading-criteria` (mirrors
/// `SaveGradingCriteria`) and the body for `POST /admin/v1/new-grading-criteria`.
class GradingCriteria {
  final int id;
  final double lowerRange;
  final double upperRange;
  final String grade;
  final String gradeDescription;

  const GradingCriteria({
    required this.id,
    required this.lowerRange,
    required this.upperRange,
    required this.grade,
    required this.gradeDescription,
  });

  factory GradingCriteria.fromJson(Map<String, dynamic> j) => GradingCriteria(
        id: (j['id'] is num) ? (j['id'] as num).toInt() : int.tryParse('${j['id']}') ?? 0,
        lowerRange: _toDouble(j['lowerRange']),
        upperRange: _toDouble(j['upperRange']),
        grade: (j['grade'] ?? '').toString(),
        gradeDescription: (j['gradeDescription'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lowerRange': lowerRange,
        'upperRange': upperRange,
        'grade': grade,
        'gradeDescription': gradeDescription,
      };

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
