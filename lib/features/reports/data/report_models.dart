/// DTOs for the Reporting Center previews. Field names mirror the JavaFX
/// report DTOs exactly.

// ---- Class Results (view-class-results) ------------------------------------

/// One subject's result within a class-results row (mirrors
/// `ViewStudentsSubjectsResults`).
class ClassResultSubject {
  final String subjectName;
  final String total;
  final String grade;
  final String description;

  const ClassResultSubject({
    required this.subjectName,
    required this.total,
    required this.grade,
    required this.description,
  });

  factory ClassResultSubject.fromJson(Map<String, dynamic> j) =>
      ClassResultSubject(
        subjectName: (j['subjectName'] ?? '').toString(),
        total: (j['total'] ?? '').toString(),
        grade: (j['grade'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
      );
}

/// One student's row in the class results (mirrors `ViewClassSemesterReport`).
class ClassResultRow {
  final String studentId;
  final String studentName;
  final String totalScore;
  final String averageScore;
  final String classPosition;
  final String totalStudents;
  final String semesterRemark;
  final List<ClassResultSubject> scores;

  const ClassResultRow({
    required this.studentId,
    required this.studentName,
    required this.totalScore,
    required this.averageScore,
    required this.classPosition,
    required this.totalStudents,
    required this.semesterRemark,
    required this.scores,
  });

  factory ClassResultRow.fromJson(Map<String, dynamic> j) => ClassResultRow(
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? '').toString(),
        totalScore: (j['totalScore'] ?? '').toString(),
        averageScore: (j['averageScore'] ?? '').toString(),
        classPosition: (j['classPosition'] ?? '').toString(),
        totalStudents: (j['totalStudents'] ?? '').toString(),
        semesterRemark: (j['semesterRemark'] ?? '').toString(),
        scores: (j['scoresList'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ClassResultSubject.fromJson)
                .toList() ??
            const [],
      );
}

// ---- Master Score Sheet (view-master-sheet) --------------------------------

/// One student row (mirrors `MasterScoreSheetRow`). `subjectScores` maps a
/// subject name to that student's total for it.
class MasterSheetRow {
  final String studentId;
  final String studentName;
  final Map<String, double> subjectScores;
  final double studentTotalScore;
  final double studentAverageScore;
  final int position;

  const MasterSheetRow({
    required this.studentId,
    required this.studentName,
    required this.subjectScores,
    required this.studentTotalScore,
    required this.studentAverageScore,
    required this.position,
  });

  factory MasterSheetRow.fromJson(Map<String, dynamic> j) {
    final raw = (j['subjectScores'] as Map?) ?? const {};
    final scores = <String, double>{};
    raw.forEach((k, v) {
      scores[k.toString()] = _toDouble(v);
    });
    return MasterSheetRow(
      studentId: (j['studentId'] ?? '').toString(),
      studentName: (j['studentName'] ?? '').toString(),
      subjectScores: scores,
      studentTotalScore: _toDouble(j['studentTotalScore']),
      studentAverageScore: _toDouble(j['studentAverageScore']),
      position: _toInt(j['position']),
    );
  }
}

/// The whole master sheet (mirrors `MasterScoreSheet`).
class MasterSheet {
  final String className;
  final String semesterName;
  final List<String> subjects;
  final List<MasterSheetRow> records;

  const MasterSheet({
    required this.className,
    required this.semesterName,
    required this.subjects,
    required this.records,
  });

  factory MasterSheet.fromJson(Map<String, dynamic> j) => MasterSheet(
        className: (j['className'] ?? '').toString(),
        semesterName: (j['semesterName'] ?? '').toString(),
        subjects: (j['subjects'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        records: (j['records'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(MasterSheetRow.fromJson)
                .toList() ??
            const [],
      );
}

// ---- SBA (view-sba) --------------------------------------------------------

/// One SBA record (mirrors `SbaRecord`).
class SbaRow {
  final String studentId;
  final String studentName;
  final String classTest1Score;
  final String groupWorkScore;
  final String classTest2Score;
  final String projectScore;
  final String classScore;
  final String examScore;
  final String calculatedExamScore;

  const SbaRow({
    required this.studentId,
    required this.studentName,
    required this.classTest1Score,
    required this.groupWorkScore,
    required this.classTest2Score,
    required this.projectScore,
    required this.classScore,
    required this.examScore,
    required this.calculatedExamScore,
  });

  factory SbaRow.fromJson(Map<String, dynamic> j) => SbaRow(
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? '').toString(),
        classTest1Score: (j['classTest1Score'] ?? '').toString(),
        groupWorkScore: (j['groupWorkScore'] ?? '').toString(),
        classTest2Score: (j['classTest2Score'] ?? '').toString(),
        projectScore: (j['projectScore'] ?? '').toString(),
        classScore: (j['classScore'] ?? '').toString(),
        examScore: (j['examScore'] ?? '').toString(),
        calculatedExamScore: (j['calculatedExamScore'] ?? '').toString(),
      );
}

// ---- Report Card (report-card) ---------------------------------------------

class ReportCardSubject {
  final String subjectName;
  final String classScore;
  final String examScore;
  final String total;
  final String grade;
  final String gradeDescriptor;

  const ReportCardSubject({
    required this.subjectName,
    required this.classScore,
    required this.examScore,
    required this.total,
    required this.grade,
    required this.gradeDescriptor,
  });

  factory ReportCardSubject.fromJson(Map<String, dynamic> j) =>
      ReportCardSubject(
        subjectName: (j['subjectName'] ?? '').toString(),
        classScore: (j['classScore'] ?? '').toString(),
        examScore: (j['examScore'] ?? '').toString(),
        total: (j['total'] ?? '').toString(),
        grade: (j['grade'] ?? '').toString(),
        gradeDescriptor: (j['gradeDescriptor'] ?? '').toString(),
      );
}

class ReportCardConduct {
  final String regular;
  final String punctual;
  final String physicalAppearance;
  final String social;
  final String emotional;
  final String cognitiveSkills;
  final String facilitatorRemark;
  final String peculiarIssue;

  const ReportCardConduct({
    this.regular = '',
    this.punctual = '',
    this.physicalAppearance = '',
    this.social = '',
    this.emotional = '',
    this.cognitiveSkills = '',
    this.facilitatorRemark = '',
    this.peculiarIssue = '',
  });

  factory ReportCardConduct.fromJson(Map<String, dynamic> j) =>
      ReportCardConduct(
        regular: (j['regular'] ?? '').toString(),
        punctual: (j['punctual'] ?? '').toString(),
        physicalAppearance: (j['physicalAppearance'] ?? '').toString(),
        social: (j['social'] ?? '').toString(),
        emotional: (j['emotional'] ?? '').toString(),
        cognitiveSkills: (j['cognitiveSkills'] ?? '').toString(),
        facilitatorRemark: (j['facilitatorRemark'] ?? '').toString(),
        peculiarIssue: (j['peculiarIssue'] ?? '').toString(),
      );
}

/// Full report card (mirrors `StudentReportCard`).
class ReportCard {
  final String schoolName;
  final String studentId;
  final String studentName;
  final String className;
  final String semesterName;
  final String totalScore;
  final String averageScore;
  final String classPosition;
  final String academicYear;
  final String totalStudents;
  final String vacationDate;
  final String resumptionDate;
  final String attendancePresent;
  final String totalAttendance;
  final String instructorName;
  final String currentDate;
  final String promotedTo;
  final List<ReportCardSubject> subjectScores;
  final ReportCardConduct? conduct;

  const ReportCard({
    required this.schoolName,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.semesterName,
    required this.totalScore,
    required this.averageScore,
    required this.classPosition,
    required this.academicYear,
    required this.totalStudents,
    required this.vacationDate,
    required this.resumptionDate,
    required this.attendancePresent,
    required this.totalAttendance,
    required this.instructorName,
    required this.currentDate,
    required this.promotedTo,
    required this.subjectScores,
    required this.conduct,
  });

  factory ReportCard.fromJson(Map<String, dynamic> j) => ReportCard(
        schoolName: (j['schoolName'] ?? '').toString(),
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? '').toString(),
        className: (j['className'] ?? '').toString(),
        semesterName: (j['semesterName'] ?? '').toString(),
        totalScore: (j['totalScore'] ?? '').toString(),
        averageScore: (j['averageScore'] ?? '').toString(),
        classPosition: (j['classPosition'] ?? '').toString(),
        academicYear: (j['academicYear'] ?? '').toString(),
        totalStudents: (j['totalStudents'] ?? '').toString(),
        vacationDate: (j['vacationDate'] ?? '').toString(),
        resumptionDate: (j['resumptionDate'] ?? '').toString(),
        attendancePresent: (j['attendancePresent'] ?? '').toString(),
        totalAttendance: (j['totalAttendance'] ?? '').toString(),
        instructorName: (j['instructorName'] ?? '').toString(),
        currentDate: (j['currentDate'] ?? '').toString(),
        promotedTo: (j['promotedTo'] ?? '').toString(),
        subjectScores: (j['subjectScores'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ReportCardSubject.fromJson)
                .toList() ??
            const [],
        conduct: j['studentConductReport'] is Map<String, dynamic>
            ? ReportCardConduct.fromJson(
                j['studentConductReport'] as Map<String, dynamic>)
            : null,
      );
}

// ---- Finance: Class Payments (fetch-grade-fees-report) ---------------------

/// One student's fee position in a class (mirrors `GradeFeesReport`).
class GradeFeesRow {
  final String studentId;
  final String studentName;
  final String totalAmountToPay;
  final String amountPayed;
  final String outstanding;

  const GradeFeesRow({
    required this.studentId,
    required this.studentName,
    required this.totalAmountToPay,
    required this.amountPayed,
    required this.outstanding,
  });

  factory GradeFeesRow.fromJson(Map<String, dynamic> j) => GradeFeesRow(
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? '').toString(),
        totalAmountToPay: (j['totalAmountToPay'] ?? '').toString(),
        amountPayed: (j['amountPayed'] ?? '').toString(),
        outstanding: (j['outstanding'] ?? '').toString(),
      );
}

// ---- Finance: Student Payments (search-fees-report) ------------------------

class PaymentHistoryRow {
  final String dateOfPayment;
  final String amountPaid;
  final String feesBalance;
  final String personWhoPaid;
  final String contactInfo;

  const PaymentHistoryRow({
    required this.dateOfPayment,
    required this.amountPaid,
    required this.feesBalance,
    required this.personWhoPaid,
    required this.contactInfo,
  });

  factory PaymentHistoryRow.fromJson(Map<String, dynamic> j) =>
      PaymentHistoryRow(
        dateOfPayment: (j['dateOfPayment'] ?? '').toString(),
        amountPaid: (j['amountPaid'] ?? '').toString(),
        feesBalance: (j['feesBalance'] ?? '').toString(),
        personWhoPaid: (j['personWhoPaid'] ?? '').toString(),
        contactInfo: (j['contactInfo'] ?? '').toString(),
      );
}

/// One student's fee report with history (mirrors `StudentFeesPaymentDisplay`).
class StudentFeesReport {
  final String studentId;
  final String studentName;
  final String semesterName;
  final String levelName;
  final String totalFeesAmount;
  final String totalAmountPaid;
  final String feesBalance;
  final List<PaymentHistoryRow> paymentHistory;

  const StudentFeesReport({
    required this.studentId,
    required this.studentName,
    required this.semesterName,
    required this.levelName,
    required this.totalFeesAmount,
    required this.totalAmountPaid,
    required this.feesBalance,
    required this.paymentHistory,
  });

  factory StudentFeesReport.fromJson(Map<String, dynamic> j) =>
      StudentFeesReport(
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? '').toString(),
        semesterName: (j['semesterName'] ?? '').toString(),
        levelName: (j['levelName'] ?? '').toString(),
        totalFeesAmount: (j['totalFeesAmount'] ?? '').toString(),
        totalAmountPaid: (j['totalAmountPaid'] ?? '').toString(),
        feesBalance: (j['feesBalance'] ?? '').toString(),
        paymentHistory: (j['paymentHistory'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(PaymentHistoryRow.fromJson)
                .toList() ??
            const [],
      );
}

// ---- helpers ----

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse((v ?? '').toString().trim()) ?? 0;
}

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse((v ?? '').toString().trim()) ?? 0;
}
