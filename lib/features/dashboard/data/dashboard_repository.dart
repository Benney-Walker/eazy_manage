import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../../core/navigation/nav_item.dart';
import 'dashboard_models.dart';

/// Fetches the dashboard payload for a given role. Mirrors the JavaFX
/// `DashboardService` split: principal/admin see the counts + logs, accountant
/// sees fees, teaching staff see a lighter set.
///
/// The count endpoints return a bare number as the body; [_count] parses that
/// tolerantly (handles quotes/whitespace just in case).
class DashboardRepository {
  final ApiClient _api;

  DashboardRepository(this._api);

  Future<DashboardData> load(AppRole role) async {
    switch (role) {
      case AppRole.principal:
        return _principal();
      case AppRole.administrator:
        return _admin();
      case AppRole.accountant:
        return _finance();
      case AppRole.teachingStaff:
      case AppRole.generalStaff:
        return _staff();
    }
  }

  // ---- Role bundles -------------------------------------------------------

  Future<DashboardData> _principal() async {
    final results = await Future.wait([
      _count(Endpoints.totalStudents),
      _count(Endpoints.totalStaff),
      _count(Endpoints.totalTeachingStaff),
      _count(Endpoints.totalFees),
      _count(Endpoints.feesPaid),
    ]);
    return DashboardData(
      totalStudents: results[0],
      totalStaff: results[1],
      totalTeachingStaff: results[2],
      totalFees: results[3],
      feesPaid: results[4],
    );
  }

  Future<DashboardData> _admin() async {
    final counts = await Future.wait([
      _count(Endpoints.totalStudents),
      _count(Endpoints.totalStaff),
      _count(Endpoints.totalTeachingStaff),
    ]);
    final logs = await _recentLogs();
    return DashboardData(
      totalStudents: counts[0],
      totalStaff: counts[1],
      totalTeachingStaff: counts[2],
      recentLogs: logs,
    );
  }

  Future<DashboardData> _finance() async {
    final counts = await Future.wait([
      _count(Endpoints.totalFees),
      _count(Endpoints.feesPaid),
      _count(Endpoints.totalStudents),
    ]);
    final txns = await _recentTransactions();
    return DashboardData(
      totalFees: counts[0],
      feesPaid: counts[1],
      totalStudents: counts[2],
      recentTransactions: txns,
    );
  }

  Future<DashboardData> _staff() async {
    final students = await _count(Endpoints.totalStudents);
    final absent = await _absentStudents();
    return DashboardData(
      totalStudents: students,
      absentStudents: absent,
    );
  }

  // ---- Primitives ---------------------------------------------------------

  /// GET a count endpoint whose body is a bare number.
  Future<int?> _count(String path) async {
    try {
      final res = await _api.get(path);
      final body = res.data;
      if (body is int) return body;
      if (body is num) return body.toInt();
      final s = body.toString().replaceAll(RegExp(r'[^0-9\-]'), '');
      if (s.isEmpty) return null;
      return int.tryParse(s);
    } on ApiException {
      // A single failing stat shouldn't blow up the whole dashboard.
      return null;
    }
  }

  Future<List<AbsentStudent>> _absentStudents() async {
    try {
      final res = await _api.get(Endpoints.absentStudents);
      final list = res.data;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(AbsentStudent.fromJson)
            .toList();
      }
    } on ApiException {
      // ignore — return empty
    }
    return const [];
  }

  Future<List<FeesTransaction>> _recentTransactions() async {
    try {
      final res = await _api.get(Endpoints.recentFeesTransactions);
      final list = res.data;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(FeesTransaction.fromJson)
            .toList();
      }
    } on ApiException {
      // ignore
    }
    return const [];
  }

  Future<List<RecentLog>> _recentLogs() async {
    try {
      final res = await _api.get(Endpoints.recentLogs);
      final list = res.data;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(RecentLog.fromJson)
            .toList();
      }
    } on ApiException {
      // ignore
    }
    return const [];
  }
}
