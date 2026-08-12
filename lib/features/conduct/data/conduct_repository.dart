import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../../core/connectivity/local_first_writer.dart';
import '../../../core/connectivity/outbox.dart';
import 'conduct_models.dart';

/// Conduct data access. Reads come straight from the API; saves go through the
/// local-first writer, so a save is recorded to the durable outbox immediately
/// (instant, survives restart) and pushed to the backend now if online or on
/// reconnect if offline.
class ConductRepository {
  final ApiClient _api;
  final LocalFirstWriter _writer;

  ConductRepository(this._api, this._writer);

  /// GET /staff/v1/conduct-records?levelId=&semesterId=.
  Future<List<StudentConductRecord>> fetchRecords({
    required String levelId,
    required String semesterId,
  }) async {
    final res = await _api.get(
      Endpoints.conductRecords(levelId, semesterId),
      triggerLogoutOn401: false,
    );
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(StudentConductRecord.fromJson)
          .toList();
    }
    return const [];
  }

  /// Save one student's conduct record — local-first. Returns as soon as the
  /// write is queued durably; the network push happens in the background.
  Future<void> saveRecord(StudentConductRecord record) async {
    await _writer.submit(
      method: OutboxMethod.put,
      path: Endpoints.saveConductRecord,
      description: 'Conduct for ${record.studentName} (${record.studentId})',
      body: record.toSaveJson(),
    );
  }
}
