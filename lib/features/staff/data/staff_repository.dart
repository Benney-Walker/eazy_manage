import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import 'staff_models.dart';

/// All staff data access. Endpoints mirror the JavaFX `StaffService`,
/// `AuthService.resetPassword`, and the enroll flow.
class StaffRepository {
  final ApiClient _api;

  StaffRepository(this._api);

  /// GET /staff/v1/load-staffs-info → the staff roster.
  Future<List<StaffSummary>> loadStaff() async {
    final res = await _api.get(Endpoints.loadStaffs);
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(StaffSummary.fromJson)
          .toList();
    }
    return const [];
  }

  /// GET /staff/v1/find-staff-by-id/{id} → full detail.
  Future<StaffDetail> findStaff(String staffId) async {
    final res = await _api.get(Endpoints.findStaff(staffId));
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StaffDetail.fromJson(data);
    }
    throw const ApiException(
      'Could not read staff data.',
      ApiFailureKind.unknown,
    );
  }

  /// PUT /admin/v1/update-staff-info.
  Future<void> updateStaff(StaffDetail detail) async {
    await _api.put(Endpoints.updateStaff, body: detail.toUpdateJson());
  }

  /// POST /auth/v1/enroll-new-staff.
  Future<void> enrollStaff(NewStaffRequest req) async {
    await _api.post(Endpoints.enrollStaff, body: req.toJson());
  }

  /// POST /admin/v1/reset-staff-password?newPasswordStaffId=..&newPassword=..
  /// (no body — the values ride in the query string, matching the JavaFX call).
  /// Values are URL-encoded so special characters in a password don't break
  /// the request.
  Future<void> resetPassword({
    required String targetStaffId,
    required String newPassword,
  }) async {
    final path = Endpoints.resetStaffPassword(
      Uri.encodeQueryComponent(targetStaffId),
      Uri.encodeQueryComponent(newPassword),
    );
    await _api.post(path);
  }
}
