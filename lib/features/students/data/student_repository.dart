import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import 'student_models.dart';

/// All student data access. Endpoints mirror the JavaFX `StudentService` +
/// `AcademicsService.loadClassStudents` + `DashboardService.loadClasses`.
class StudentRepository {
  final ApiClient _api;

  StudentRepository(this._api);

  /// GET /staff/v1/load-classes → the class/grade options for filters + forms.
  Future<List<ClassOption>> loadClasses() async {
    final res = await _api.get(Endpoints.loadClasses);
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(ClassOption.fromJson)
          .toList();
    }
    return const [];
  }

  /// GET /student/v1/load-students/{levelId} → roster for a class.
  Future<List<StudentSummary>> loadStudents(String levelId) async {
    final res = await _api.get(Endpoints.loadStudents(levelId));
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(StudentSummary.fromJson)
          .toList();
    }
    return const [];
  }

  /// GET /student/v1/find-student/{id} → full detail for one student.
  Future<StudentDetail> findStudent(String studentId) async {
    final res = await _api.get(Endpoints.findStudent(studentId));
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentDetail.fromJson(data);
    }
    throw const ApiException(
      'Could not read student data.',
      ApiFailureKind.unknown,
    );
  }

  /// POST /student/v1/add-new-student.
  Future<void> addStudent(NewStudentRequest req) async {
    await _api.post(Endpoints.addStudent, body: req.toJson());
  }

  /// PUT /student/v1/update-student-data.
  Future<void> updateStudent(StudentDetail detail) async {
    await _api.put(Endpoints.updateStudent, body: detail.toUpdateJson());
  }
}