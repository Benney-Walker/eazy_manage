import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/connectivity/connectivity_providers.dart';
import '../../academics/data/academics_models.dart';
import '../../academics/data/academics_providers.dart';
import 'results_models.dart';
import 'results_repository.dart';

final resultsRepositoryProvider = Provider<ResultsRepository>((ref) {
  return ResultsRepository(
    ref.watch(apiClientProvider),
    ref.watch(localFirstWriterProvider),
  );
});

/// The class → subject → term context for score entry.
final resultsLevelIdProvider = StateProvider<String?>((ref) => null);
final resultsSubjectIdProvider = StateProvider<String?>((ref) => null);
final resultsSemesterIdProvider = StateProvider<String?>((ref) => null);

/// Subjects available for the chosen class (reuses the academics subjects
/// endpoint). Empty until a class is picked.
final resultsSubjectsProvider =
FutureProvider.autoDispose<List<SubjectSummary>>((ref) async {
  final levelId = ref.watch(resultsLevelIdProvider);
  if (levelId == null) return const [];
  return ref.watch(academicsRepositoryProvider).loadSubjects(levelId);
});

/// True once class + subject + term are all chosen.
final resultsContextReadyProvider = Provider<bool>((ref) {
  return ref.watch(resultsLevelIdProvider) != null &&
      ref.watch(resultsSubjectIdProvider) != null &&
      ref.watch(resultsSemesterIdProvider) != null;
});

/// The loaded subject roster + existing scores for the chosen context.
final subjectScoresProvider =
FutureProvider.autoDispose<SubjectScores?>((ref) async {
  final subjectId = ref.watch(resultsSubjectIdProvider);
  final semesterId = ref.watch(resultsSemesterIdProvider);
  if (subjectId == null || semesterId == null) return null;
  return ref.watch(resultsRepositoryProvider).loadSubjectStudents(
    subjectId: subjectId,
    semesterId: semesterId,
  );
});
