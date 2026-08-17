import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/cache/reference_cache.dart';
import '../../../core/connectivity/connectivity_providers.dart';
import 'academics_models.dart';
import 'academics_repository.dart';

final academicsRepositoryProvider = Provider<AcademicsRepository>((ref) {
  return AcademicsRepository(ref.watch(apiClientProvider));
});

// ---- Semesters ------------------------------------------------------------

final semestersProvider =
FutureProvider<List<SemesterSummary>>((ref) async {
  return readThroughCache<SemesterSummary>(
    cache: ref.read(referenceCacheProvider),
    isOnline: ref.read(isOnlineProvider),
    key: ReferenceCacheKeys.semesters,
    ttl: kReferenceCacheTtl,
    fetch: () => ref.read(academicsRepositoryProvider).loadSemesters(),
    fromJson: SemesterSummary.fromJson,
    toJson: (s) => s.toJson(),
  );
});

Future<void> refreshSemesters(WidgetRef ref) async {
  await ref.read(referenceCacheProvider).bust(ReferenceCacheKeys.semesters);
  ref.invalidate(semestersProvider);
}

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

// ---- Classes---------------------------------------------------------

/// Full detail for one class, keyed by levelId (for the edit sheet).
final classDetailProvider =
FutureProvider.autoDispose.family<ClassDetail, String>((ref, levelId) async {
  return ref.watch(academicsRepositoryProvider).findClass(levelId);
});

// ---- Holidays --------------------------------------------------------

final holidaysProvider =
FutureProvider.autoDispose<List<Holiday>>((ref) async {
  final list = await ref.watch(academicsRepositoryProvider).loadHolidays();
  // Most recent first by start date (string ISO sorts correctly).
  final sorted = [...list]..sort((a, b) => b.startDate.compareTo(a.startDate));
  return sorted;
});