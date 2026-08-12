import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../../core/connectivity/local_first_writer.dart';
import '../../../core/connectivity/outbox.dart';
import 'results_models.dart';

/// Results (Enter Scores) data access. The roster comes straight from the API;
/// the batch score save is **local-first** — recorded to the durable outbox
/// immediately, then pushed now if online or on reconnect if offline.
class ResultsRepository {
  final ApiClient _api;
  final LocalFirstWriter _writer;

  ResultsRepository(this._api, this._writer);

  /// GET /student/v1/load-subject-students/{subjectId}/{semesterId}
  /// → the subject's students with any existing scores.
  Future<SubjectScores> loadSubjectStudents({
    required String subjectId,
    required String semesterId,
  }) async {
    final res = await _api.get(
      Endpoints.loadSubjectStudents(subjectId, semesterId),
      triggerLogoutOn401: false,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return SubjectScores.fromJson(data);
    // Some backends may return a bare list; wrap it.
    if (data is List) {
      return SubjectScores(
        subjectId: subjectId,
        subjectName: '',
        rows: data
            .whereType<Map<String, dynamic>>()
            .map(ScoreRow.fromJson)
            .toList(),
      );
    }
    return SubjectScores(subjectId: subjectId, subjectName: '', rows: const []);
  }

  /// POST /student/v1/save-scores — a JSON ARRAY of all rows (batch), sent
  /// local-first. Returns as soon as the batch is queued durably.
  Future<void> saveScores({
    required String subjectName,
    required List<ScoreRow> rows,
  }) async {
    final body = rows.map((r) => r.toJson()).toList();
    await _writer.submit(
      method: OutboxMethod.post,
      path: Endpoints.saveScores,
      description: 'Scores for $subjectName (${rows.length} students)',
      body: body,
    );
  }
}
