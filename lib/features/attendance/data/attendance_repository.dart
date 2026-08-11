import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import 'attendance_models.dart';

class AttendanceRepository {
  final ApiClient _api;

  AttendanceRepository(this._api);

  Future<List<MarkedDate>> datesMarked(String levelId, String semesterId) async {
    final res = await _api.get(
      Endpoints.datesMarked(levelId, semesterId),
      triggerLogoutOn401: false,
    );
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(MarkedDate.fromJson)
          .toList();
    }
    return const [];
  }

  /// GET /student/v1/attendance-records?levelId=&semesterId=&date= — each
  /// student's status for the chosen class + semester + date.
  Future<List<StudentAttendance>> attendanceRecords({
    required String levelId,
    required String semesterId,
    required String date,
  }) async {
    final res = await _api.get(
      Endpoints.attendanceRecords(levelId, semesterId, date),
      triggerLogoutOn401: false,
    );
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(StudentAttendance.fromJson)
          .toList();
    }
    return const [];
  }
}
