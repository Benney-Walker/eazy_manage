import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../academics/data/academics_models.dart';
import '../../academics/data/academics_providers.dart';
import '../../students/data/student_models.dart';
import '../../students/data/student_providers.dart';
import 'reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(apiClientProvider));
});

/// Students in a specific class, for report student-pickers. Keyed by levelId
/// so it doesn't disturb the roster screen's own selected-class state.
final reportStudentsProvider = FutureProvider.autoDispose
    .family<List<StudentSummary>, String>((ref, levelId) async {
  if (levelId.isEmpty) return const [];
  return ref.watch(studentRepositoryProvider).loadStudents(levelId);
});

/// Subjects in a specific class, for report subject-pickers. Keyed by levelId
/// so it doesn't disturb the academics screen's own selected-class state.
final reportSubjectsProvider = FutureProvider.autoDispose
    .family<List<SubjectSummary>, String>((ref, levelId) async {
  if (levelId.isEmpty) return const [];
  return ref.watch(academicsRepositoryProvider).loadSubjects(levelId);
});
