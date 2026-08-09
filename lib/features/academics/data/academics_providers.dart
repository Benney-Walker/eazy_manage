import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'academics_models.dart';
import 'academics_repository.dart';

final academicsRepositoryProvider = Provider<AcademicsRepository>((ref) {
  return AcademicsRepository(ref.watch(apiClientProvider));
});

// ---- Semesters ------------------------------------------------------------

final semestersProvider =
    FutureProvider.autoDispose<List<SemesterSummary>>((ref) async {
  return ref.watch(academicsRepositoryProvider).loadSemesters();
});

final semesterDetailProvider = FutureProvider.autoDispose
    .family<SemesterDetail, String>((ref, id) async {
  return ref.watch(academicsRepositoryProvider).findSemester(id);
});

// ---- Subjects (scoped to a selected class) --------------------------------

/// The class selected in the Subjects tab (levelId). Null = none chosen.
final subjectsClassProvider = StateProvider<String?>((ref) => null);

final subjectsProvider =
    FutureProvider.autoDispose<List<SubjectSummary>>((ref) async {
  final levelId = ref.watch(subjectsClassProvider);
  if (levelId == null) return const [];
  return ref.watch(academicsRepositoryProvider).loadSubjects(levelId);
});

final subjectDetailProvider =
    FutureProvider.autoDispose.family<SubjectDetail, String>((ref, id) async {
  return ref.watch(academicsRepositoryProvider).findSubject(id);
});

// ---- Grading --------------------------------------------------------------

final gradingCriteriaProvider =
    FutureProvider.autoDispose<List<GradingCriteria>>((ref) async {
  final list = await ref.watch(academicsRepositoryProvider).loadGradingCriteria();
  // Sort by lowerRange descending so the highest band shows first (A at top).
  final sorted = [...list]..sort((a, b) => b.lowerRange.compareTo(a.lowerRange));
  return sorted;
});
