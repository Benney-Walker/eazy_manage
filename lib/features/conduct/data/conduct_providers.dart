import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/connectivity/connectivity_providers.dart';
import 'conduct_models.dart';
import 'conduct_repository.dart';

final conductRepositoryProvider = Provider<ConductRepository>((ref) {
  return ConductRepository(
    ref.watch(apiClientProvider),
    ref.watch(localFirstWriterProvider),
  );
});

/// The class + semester being worked in.
final conductLevelIdProvider = StateProvider<String?>((ref) => null);
final conductSemesterIdProvider = StateProvider<String?>((ref) => null);

/// True once both class and semester are chosen.
final conductContextReadyProvider = Provider<bool>((ref) {
  return ref.watch(conductLevelIdProvider) != null &&
      ref.watch(conductSemesterIdProvider) != null;
});

/// The conduct records for the chosen class + semester.
final conductRecordsProvider =
    FutureProvider.autoDispose<List<StudentConductRecord>>((ref) async {
  final levelId = ref.watch(conductLevelIdProvider);
  final semesterId = ref.watch(conductSemesterIdProvider);
  if (levelId == null || semesterId == null) return const [];
  return ref.watch(conductRepositoryProvider).fetchRecords(
        levelId: levelId,
        semesterId: semesterId,
      );
});
