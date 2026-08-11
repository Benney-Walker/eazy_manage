import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import 'academics_models.dart';

class AcademicsRepository {
  final ApiClient _api;

  AcademicsRepository(this._api);

  // ---- Semesters ----------------------------------------------------------

  Future<List<SemesterSummary>> loadSemesters() async {
    final res = await _api.get(Endpoints.loadSemesters, triggerLogoutOn401: false);
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(SemesterSummary.fromJson)
          .toList();
    }
    return const [];
  }

  Future<SemesterDetail> findSemester(String id) async {
    final res = await _api.get(Endpoints.searchSemester(id), triggerLogoutOn401: false);
    final data = res.data;
    if (data is Map<String, dynamic>) return SemesterDetail.fromJson(data);
    throw const ApiException('Could not read semester.', ApiFailureKind.unknown);
  }

  Future<void> addSemester(NewSemesterRequest req) async {
    await _api.post(Endpoints.addSemester, body: req.toJson());
  }

  Future<void> updateSemester(SemesterDetail detail) async {
    await _api.put(Endpoints.updateSemester, body: detail.toUpdateJson());
  }

  // ---- Subjects -----------------------------------------------------------

  Future<List<SubjectSummary>> loadSubjects(String levelId) async {
    final res = await _api.get(Endpoints.loadSubjects(levelId), triggerLogoutOn401: false);
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(SubjectSummary.fromJson)
          .toList();
    }
    return const [];
  }

  Future<SubjectDetail> findSubject(String subjectId) async {
    final res = await _api.get(Endpoints.loadSubjectData(subjectId), triggerLogoutOn401: false);
    final data = res.data;
    if (data is Map<String, dynamic>) return SubjectDetail.fromJson(data);
    throw const ApiException('Could not read subject.', ApiFailureKind.unknown);
  }

  Future<void> addSubject(NewSubjectRequest req) async {
    await _api.post(Endpoints.addSubject, body: req.toJson());
  }

  Future<void> updateSubject(SubjectDetail detail) async {
    await _api.put(Endpoints.updateSubject, body: detail.toUpdateJson());
  }

  // ---- Grading ------------------------------------------------------------

  Future<List<GradingCriteria>> loadGradingCriteria() async {
    final res = await _api.get(Endpoints.loadGradingCriteria, triggerLogoutOn401: false);
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(GradingCriteria.fromJson)
          .toList();
    }
    return const [];
  }

  Future<void> saveGradingCriteria(GradingCriteria criteria) async {
    await _api.post(Endpoints.newGradingCriteria, body: criteria.toJson());
  }
}