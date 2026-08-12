import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import 'audit_models.dart';

/// Read-only access to audit logs. Two modes mirror the JavaFX `LoggingService`:
///  - a specific staff member's logs in a date range (`get-staff-logs`), and
///  - all logs in a date range (`get-timely-logs`).
/// Reads pass `triggerLogoutOn401: false` (the standard auto-fetch guard).
class AuditRepository {
  final ApiClient _api;

  AuditRepository(this._api);

  /// GET /admin/v1/get-staff-logs?selectedStaffId=&fromDate=&toDate=
  Future<List<AuditLog>> staffLogs({
    required String selectedStaffId,
    required String fromDate,
    required String toDate,
  }) async {
    final res = await _api.get(
      Endpoints.staffLogs(selectedStaffId, fromDate, toDate),
      triggerLogoutOn401: false,
    );
    return _parse(res.data);
  }

  /// GET /admin/v1/get-timely-logs?fromDate=&toDate=
  Future<List<AuditLog>> timelyLogs({
    required String fromDate,
    required String toDate,
  }) async {
    final res = await _api.get(
      Endpoints.timelyLogs(fromDate, toDate),
      triggerLogoutOn401: false,
    );
    return _parse(res.data);
  }

  List<AuditLog> _parse(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(AuditLog.fromJson)
          .toList();
    }
    return const [];
  }
}
