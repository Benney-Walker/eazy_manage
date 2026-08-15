import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import 'report_models.dart';

/// Read-only fetches for the report previews. PDF generation is handled
/// separately by [ReportPdfService]. All reads pass `triggerLogoutOn401: false`
/// (the standard auto-fetch guard).
class ReportsRepository {
  final ApiClient _api;

  ReportsRepository(this._api);

  Future<List<ClassResultRow>> classResults(
      String levelId, String semesterId) async {
    final res = await _api.get(Endpoints.viewClassResults(levelId, semesterId),
        triggerLogoutOn401: false);
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(ClassResultRow.fromJson)
          .toList();
    }
    return const [];
  }

  Future<MasterSheet?> masterSheet(String levelId, String semesterId) async {
    final res = await _api.get(Endpoints.viewMasterSheet(levelId, semesterId),
        triggerLogoutOn401: false);
    final data = res.data;
    if (data is Map<String, dynamic>) return MasterSheet.fromJson(data);
    return null;
  }

  Future<List<SbaRow>> sba(
      String levelId, String subjectId, String semesterId) async {
    final res = await _api.get(
        Endpoints.viewSba(levelId, subjectId, semesterId),
        triggerLogoutOn401: false);
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(SbaRow.fromJson)
          .toList();
    }
    return const [];
  }

  Future<ReportCard?> reportCard(String studentId, String semesterId) async {
    final res = await _api.get(Endpoints.reportCard(studentId, semesterId),
        triggerLogoutOn401: false);
    final data = res.data;
    if (data is Map<String, dynamic>) return ReportCard.fromJson(data);
    return null;
  }

  Future<List<GradeFeesRow>> gradePayments(
      String levelId, String semesterId) async {
    final res = await _api.get(Endpoints.gradeFeesReport(levelId, semesterId),
        triggerLogoutOn401: false);
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(GradeFeesRow.fromJson)
          .toList();
    }
    return const [];
  }

  Future<StudentFeesReport?> studentPayments(
      String studentId, String semesterId, String gradeId) async {
    final res = await _api.get(
        Endpoints.studentFeesReport(studentId, semesterId, gradeId),
        triggerLogoutOn401: false);
    final data = res.data;
    if (data is Map<String, dynamic>) return StudentFeesReport.fromJson(data);
    return null;
  }
}
