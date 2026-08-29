import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../../core/navigation/nav_item.dart';
import 'dashboard_models.dart';

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
        return _staff();
    }
  }

  // ---- Role bundles -------------------------------------------------------

  Future<DashboardData> _principal() async {
    final counts = await Future.wait([
      _count(Endpoints.totalStudents),
      _count(Endpoints.totalStaff),
      _count(Endpoints.totalTeachingStaff),
    ]);
    final money = await Future.wait([
      _money(Endpoints.totalFees),
      _money(Endpoints.feesPaid),
      _money(Endpoints.totalExpenses),
    ]);
    // The principal's overview includes today's absentees (mirrors the JavaFX
    // principal dashboard, which loads absent-students).
    final absent = await _absentStudents();
    return DashboardData(
      totalStudents: counts[0],
      totalStaff: counts[1],
      totalTeachingStaff: counts[2],
      totalFees: money[0],
      feesPaid: money[1],
      totalExpenses: money[2],
      absentStudents: absent,
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
    final money = await Future.wait([
      _money(Endpoints.totalFees),
      _money(Endpoints.feesPaid),
      _money(Endpoints.totalExpenses),
    ]);
    final txns = await _recentTransactions();
    return DashboardData(
      totalFees: money[0],
      feesPaid: money[1],
      totalExpenses: money[2],
      recentTransactions: txns,
    );
  }

  Future<DashboardData> _staff() async {
    try {
      final res = await _api.get(Endpoints.classInfo,
          triggerLogoutOn401: false);
      final info = ClassInfo.fromJson(res.data);
      return DashboardData(
          className: info.className,
          totalClassStudents: info.classSize
      );
    } on ApiException{
      return DashboardData(
          className: 'No assigned class',
          totalClassStudents: 0
      );
    }
  }

  Future<ClassInfo?> _getClassInfo() async {
    try {
      final res = await _api.get(Endpoints.totalStudents,
          triggerLogoutOn401: false);
      final body = res.data;
      if (body is Map<String, dynamic>) return ClassInfo.fromJson(body);
      return null;
    } on ApiException {

      return null;
    }
  }

  // ---- Primitives ---------------------------------------------------------

  /// GET a count endpoint whose body is a bare number.
  Future<int?> _count(String path) async {
    try {
      final res = await _api.get(path, triggerLogoutOn401: false);
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

  /// Fetch a money total as a double, keeping decimals (pesewas). Unlike
  /// [_count] this never strips the decimal point. A 404 (e.g. the backend's
  /// "no expenses yet" / "no current term" responses) is treated as "unknown"
  /// so the card shows a dash rather than a wrong figure.
  Future<double?> _money(String path) async {
    try {
      final res = await _api.get(path, triggerLogoutOn401: false);
      final body = res.data;
      if (body is num) return body.toDouble();
      if (body is String) return double.tryParse(body.trim());
      return null;
    } on ApiException {
      return null;
    }
  }

  Future<List<AbsentStudent>> _absentStudents() async {
    try {
      final res = await _api.get(Endpoints.absentStudents, triggerLogoutOn401: false);
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
      final res = await _api.get(Endpoints.recentFeesTransactions, triggerLogoutOn401: false);
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
      final res = await _api.get(Endpoints.recentLogs, triggerLogoutOn401: false);
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