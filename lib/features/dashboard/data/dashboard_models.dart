/// Lightweight models for the dashboard. The count endpoints return a bare
/// number as the response body (e.g. `1284`), so those don't need a model —
/// the repository parses them to int directly. These types cover the list
/// endpoints.

/// A row in the "absent students today" list.
class AbsentStudent {
  final String studentId;
  final String studentName;
  final String className;

  const AbsentStudent({
    required this.studentId,
    required this.studentName,
    required this.className,
  });

  factory AbsentStudent.fromJson(Map<String, dynamic> j) => AbsentStudent(
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? j['fullName'] ?? '').toString(),
        className: (j['className'] ?? j['levelName'] ?? '').toString(),
      );
}

/// A recent fees transaction row.
class FeesTransaction {
  final String studentName;
  final String amount;
  final String date;

  const FeesTransaction({
    required this.studentName,
    required this.amount,
    required this.date,
  });

  factory FeesTransaction.fromJson(Map<String, dynamic> j) => FeesTransaction(
        studentName: (j['studentName'] ?? j['payerName'] ?? '').toString(),
        amount: (j['amount'] ?? j['amountPaid'] ?? '').toString(),
        date: (j['date'] ?? j['paidAt'] ?? j['createdAt'] ?? '').toString(),
      );
}

/// A recent system/audit log row.
class RecentLog {
  final String action;
  final String createdBy;
  final String date;

  const RecentLog({
    required this.action,
    required this.createdBy,
    required this.date,
  });

  factory RecentLog.fromJson(Map<String, dynamic> j) => RecentLog(
        action: (j['action'] ?? j['message'] ?? j['description'] ?? '').toString(),
        createdBy: (j['createdBy'] ?? j['actor'] ?? '').toString(),
        date: (j['date'] ?? j['time'] ?? j['createdAt'] ?? '').toString(),
      );
}

/// The full set of dashboard data for a role. Any field may be null when the
/// role doesn't surface that stat (e.g. teaching staff don't see fees).
class DashboardData {
  final int? totalStudents;
  final int? totalStaff;
  final int? totalTeachingStaff;
  final int? totalFees;
  final int? feesPaid;
  final List<AbsentStudent> absentStudents;
  final List<FeesTransaction> recentTransactions;
  final List<RecentLog> recentLogs;

  const DashboardData({
    this.totalStudents,
    this.totalStaff,
    this.totalTeachingStaff,
    this.totalFees,
    this.feesPaid,
    this.absentStudents = const [],
    this.recentTransactions = const [],
    this.recentLogs = const [],
  });
}
