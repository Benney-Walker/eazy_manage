abstract final class ApiConfig {

  static const String PRODUCTION_URL = 'https://schoolmanagementsystem-eazymanage.up.railway.app';

  static const String LOCAL_URL = 'http://localhost:8080';

  static const String BASE_URL = PRODUCTION_URL + '/api';

  // URL roots
  static const String finance = '/finance';
  static const String staff = '/staff';
  static const String student = '/student';
  static const String admin = '/admin';
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

  // ---- Dashboard counts (plain-number response bodies) ----
  static const String totalStudents =
      '${ApiConfig.student}${ApiConfig.v1}/total-students';
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
}

