abstract final class ApiConfig {

  static const bool useLocal =  false;

  static const String PRODUCTION_URL = 'https://schoolmanagementsystem-production-46c3.up.railway.app';

  static const String LOCAL_URL = 'http://localhost:8080';

  static String get BASE_URL => '${useLocal ? LOCAL_URL : PRODUCTION_URL}/api';

  // URL roots
  static const String finance = '/finance';
  static const String staff = '/staff';
  static const String student = '/student';
  static const String admin = '/admin';
  static const String message = '/message';
  static const String offline = '/offline';
  static const String auth = '/auth';

  // Versions
  static const String v1 = '/v1';
  static const String v2 = '/v2';
  static const String v3 = '/v3';
}

/// Concrete endpoint paths, composed from [ApiConfig]. Grouped by domain.
abstract final class Endpoints {
  // ---- Auth ----
  static const String staffLogin = '${ApiConfig.auth}${ApiConfig.v1}/staff-login';
  static const String refreshToken =
      '${ApiConfig.auth}${ApiConfig.v1}/refresh-token';

  // ---- Dashboard counts (plain-number response bodies) ----
  static const String totalStudents =
      '${ApiConfig.student}${ApiConfig.v1}/total-students';
  static const String classInfo =
      '${ApiConfig.staff}${ApiConfig.v1}/load-class-info';
  static const String totalStaff =
      '${ApiConfig.staff}${ApiConfig.v1}/total-staffs';
  static const String totalTeachingStaff =
      '${ApiConfig.staff}${ApiConfig.v1}/total-teaching-staffs';
  static const String totalFees =
      '${ApiConfig.finance}${ApiConfig.v1}/total-fees';
  static const String feesPaid =
      '${ApiConfig.finance}${ApiConfig.v1}/fees-paid';

  // ---- Dashboard lists ----
  static const String absentStudents =
      '${ApiConfig.student}${ApiConfig.v1}/absent-students';
  static const String recentFeesTransactions =
      '${ApiConfig.finance}${ApiConfig.v1}/recent-fees-transactions';
  static const String recentLogs =
      '${ApiConfig.admin}${ApiConfig.v1}/recent-logs';

  // ---- Students ----
  static const String loadClasses = '${ApiConfig.staff}${ApiConfig.v1}/load-classes';
  static String loadStudents(String levelId) =>
      '${ApiConfig.student}${ApiConfig.v1}/load-students/$levelId';
  static String findStudent(String studentId) =>
      '${ApiConfig.student}${ApiConfig.v1}/find-student/$studentId';
  static const String addStudent =
      '${ApiConfig.student}${ApiConfig.v1}/add-new-student';
  static const String updateStudent =
      '${ApiConfig.student}${ApiConfig.v1}/update-student-data';

  // ---- Staff ----
  static const String loadStaffs =
      '${ApiConfig.staff}${ApiConfig.v1}/load-staffs-info';
  static String findStaff(String staffId) =>
      '${ApiConfig.staff}${ApiConfig.v1}/find-staff-by-id/$staffId';
  static const String updateStaff =
      '${ApiConfig.admin}${ApiConfig.v1}/update-staff-info';
  static const String enrollStaff =
      '${ApiConfig.auth}${ApiConfig.v1}/enroll-new-staff';
  static const String schoolSubscription =
      '${ApiConfig.auth}${ApiConfig.v1}/school-subscription';
  static String resetStaffPassword(String newPasswordStaffId, String newPassword) =>
      '${ApiConfig.admin}${ApiConfig.v1}/reset-staff-password'
          '?newPasswordStaffId=$newPasswordStaffId&newPassword=$newPassword';

  // ---- Academics: Semesters ----
  static const String loadSemesters =
      '${ApiConfig.staff}${ApiConfig.v1}/load-semesters';
  static String searchSemester(String id) =>
      '${ApiConfig.admin}${ApiConfig.v1}/search-semester/$id';
  static const String addSemester =
      '${ApiConfig.admin}${ApiConfig.v1}/add-semester';
  static const String updateSemester =
      '${ApiConfig.admin}${ApiConfig.v1}/update-semester-info';

  // ---- Academics: Subjects ----
  static String loadSubjects(String levelId) =>
      '${ApiConfig.staff}${ApiConfig.v1}/load-subjects/$levelId';
  static String loadSubjectData(String subjectId) =>
      '${ApiConfig.admin}${ApiConfig.v1}/load-subject-data/$subjectId';
  static const String addSubject =
      '${ApiConfig.admin}${ApiConfig.v1}/add-subject';
  static const String updateSubject =
      '${ApiConfig.admin}${ApiConfig.v1}/update-subject-details';

  // ---- Academics: Grading ----
  static const String loadGradingCriteria =
      '${ApiConfig.admin}${ApiConfig.v1}/load-grading-criteria';
  static const String newGradingCriteria =
      '${ApiConfig.admin}${ApiConfig.v1}/new-grading-criteria';

  // ---- Academics: Classes ----
  static String findClassInfo(String levelId) =>
      '${ApiConfig.admin}${ApiConfig.v1}/find-class-info/$levelId';
  static String addNewClass(String gradeName, String instructorId) =>
      '${ApiConfig.admin}${ApiConfig.v1}/add-new-class'
          '?gradeName=$gradeName&instructorId=$instructorId';
  static const String updateClassInfo =
      '${ApiConfig.admin}${ApiConfig.v1}/update-class-info';

  // ---- Academics: Holidays ----
  static const String loadHolidays =
      '${ApiConfig.admin}${ApiConfig.v1}/load-holidays';
  static const String addHoliday =
      '${ApiConfig.admin}${ApiConfig.v1}/add-holiday';
  static const String updateHoliday =
      '${ApiConfig.admin}${ApiConfig.v1}/update-holiday';

  // ---- Finance: Fees Setup ----
  static String fetchFeesDetails(String semesterId) =>
      '${ApiConfig.finance}${ApiConfig.v1}/fetch-fees-details/$semesterId';
  static const String newFees = '${ApiConfig.finance}${ApiConfig.v2}/new-fees';
  static const String updateSemesterFees =
      '${ApiConfig.finance}${ApiConfig.v2}/update-semester-fees';

  // ---- Finance: Special payments ---
  static const String addSpecialFee =
      '${ApiConfig.finance}${ApiConfig.v1}/add-special-fee';
  static String loadSpecialFees(String paymentType) =>
      '${ApiConfig.finance}${ApiConfig.v1}/load-special-fees/$paymentType';
  static const String updateSpecialFee =
      '${ApiConfig.finance}${ApiConfig.v1}/update-special-fee';

  // ---- Finance: Expenses ----
  static const String addNewExpenses =
      '${ApiConfig.finance}${ApiConfig.v1}/add-new-expenses';
  static String readExpensesRecords(String semesterId) =>
      '${ApiConfig.finance}${ApiConfig.v1}/read-expenses-records/$semesterId';
  static const String totalExpenses =
      '${ApiConfig.finance}${ApiConfig.v1}/total-expenses';
  static const String updateExpenseRecord =
      '${ApiConfig.finance}${ApiConfig.v1}/update-expense-record';
  static String deleteExpenses(String expensesId) =>
      '${ApiConfig.finance}${ApiConfig.v1}/delete-expenses/$expensesId';

  // ---- Finance: Payments ----
  static const String addFeesPayment =
      '${ApiConfig.finance}${ApiConfig.v1}/add-fees-payment';
  static const String updatePaymentDetails =
      '${ApiConfig.finance}${ApiConfig.v1}/update-payment-details';
  static String fetchPaymentRecords(String studentId, String levelId, String semesterId) =>
      '${ApiConfig.finance}${ApiConfig.v1}/fetch-payment-records'
          '?studentId=$studentId&levelId=$levelId&semesterId=$semesterId';

  // ---- Attendance (view-only) ----
  static String datesMarked(String levelId, String semesterId) =>
      '${ApiConfig.student}${ApiConfig.v1}/dates-marked/$levelId/$semesterId';
  static String attendanceRecords(String levelId, String semesterId, String date) =>
      '${ApiConfig.student}${ApiConfig.v1}/attendance-records'
          '?levelId=$levelId&semesterId=$semesterId&date=$date';

  // ---- Conduct ----
  static String conductRecords(String levelId, String semesterId) =>
      '${ApiConfig.staff}${ApiConfig.v1}/conduct-records'
          '?levelId=$levelId&semesterId=$semesterId';
  static const String saveConductRecord =
      '${ApiConfig.staff}${ApiConfig.v1}/save-conduct-record';

  // ---- Results (Enter Scores) ----
  static String loadSubjectStudents(String subjectId, String semesterId) =>
      '${ApiConfig.student}${ApiConfig.v1}/load-subject-students/$subjectId/$semesterId';
  static String saveScores(String subjectId, String semesterId) =>
      '${ApiConfig.student}${ApiConfig.v1}/save-scores/$subjectId/$semesterId';

  // ---- Reports: end-of-year progression (third-term only) ----
  // PUT, no body; staffId travels in the header via the interceptor.
  static String promoteStudent(
      String studentId, String promotionClassId, String semesterId) =>
      '${ApiConfig.student}${ApiConfig.v1}/promote-student'
          '?studentId=$studentId'
          '&promotionClassId=$promotionClassId'
          '&semesterId=$semesterId';
  static String repeatStudent(String studentId, String semesterId) =>
      '${ApiConfig.student}${ApiConfig.v1}/repeat-student'
          '?studentId=$studentId&semesterId=$semesterId';

  // ---- Broadcasts (messaging) ----
  static const String broadcastSms =
      '${ApiConfig.message}${ApiConfig.v1}/broadcast-sms';
  static const String broadcastEmail =
      '${ApiConfig.message}${ApiConfig.v1}/broadcast-email';

  // ---- Audit Logs ----
  static String staffLogs(String selectedStaffId, String fromDate, String toDate) =>
      '${ApiConfig.admin}${ApiConfig.v1}/get-staff-logs'
          '?selectedStaffId=$selectedStaffId&fromDate=$fromDate&toDate=$toDate';
  static String timelyLogs(String fromDate, String toDate) =>
      '${ApiConfig.admin}${ApiConfig.v1}/get-timely-logs'
          '?fromDate=$fromDate&toDate=$toDate';

  // ---- Reports: previews (JSON) ----
  static String viewClassResults(String levelId, String semesterId) =>
      '${ApiConfig.staff}${ApiConfig.v1}/view-class-results?levelId=$levelId&semesterId=$semesterId';
  static String viewMasterSheet(String levelId, String semesterId) =>
      '${ApiConfig.staff}${ApiConfig.v1}/view-master-sheet?levelId=$levelId&semesterId=$semesterId';
  static String viewSba(String levelId, String subjectId, String semesterId) =>
      '${ApiConfig.staff}${ApiConfig.v1}/view-sba?classId=$levelId&subjectId=$subjectId&semesterId=$semesterId';
  static String reportCard(String studentId, String semesterId) =>
      '${ApiConfig.staff}${ApiConfig.v1}/report-card?studentId=$studentId&semesterId=$semesterId';
  static String gradeFeesReport(String levelId, String semesterId) =>
      '${ApiConfig.finance}${ApiConfig.v1}/fetch-grade-fees-report/$levelId/$semesterId';
  static String studentFeesReport(String studentId, String semesterId, String gradeId) =>
      '${ApiConfig.finance}${ApiConfig.v1}/search-fees-report?studentId=$studentId&semesterId=$semesterId&gradeId=$gradeId';

  // ---- Reports: PDF generation (bytes) ----
  static String generateClassReport(String levelId, String semesterId) =>
      '${ApiConfig.admin}${ApiConfig.v2}/generate-class-report?levelId=$levelId&semesterId=$semesterId';
  static String generateMasterSheet(String levelId, String semesterId) =>
      '${ApiConfig.admin}${ApiConfig.v2}/generate-master-sheet?levelId=$levelId&semesterId=$semesterId';
  static String generateSbaReport(String levelId, String subjectId, String semesterId) =>
      '${ApiConfig.admin}${ApiConfig.v2}/generate-sba-report?levelId=$levelId&subjectId=$subjectId&semesterId=$semesterId';
  static String generateReportCard(String studentId, String semesterId) =>
      '${ApiConfig.student}${ApiConfig.v3}/generate-report-card?studentId=$studentId&semesterId=$semesterId';
  static String generateExpensesReport(String semesterId) =>
      '${ApiConfig.finance}${ApiConfig.v1}/generate-expenses-report/$semesterId';
}