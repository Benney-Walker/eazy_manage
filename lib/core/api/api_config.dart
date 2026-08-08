abstract final class ApiConfig {

  static const String LOCAL_URL = 'http://localhost:8080/api';

  static const String PRODUCTION_URL = 'https://schoolmanagementsystem-eazymanage.up.railway.app/api';

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
}
