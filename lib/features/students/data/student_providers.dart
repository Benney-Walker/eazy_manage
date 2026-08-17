import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/cache/reference_cache.dart';
import '../../../core/connectivity/connectivity_providers.dart';
import 'student_models.dart';
import 'student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(apiClientProvider));
});

/// The class/grade options. Backed by a durable TTL cache: served from cache
/// while fresh, refreshed from the network when stale and online, and falling
/// back to the last cached copy when offline — so classes are available
/// instantly on launch and survive being offline.
final classesProvider = FutureProvider<List<ClassOption>>((ref) async {
  return readThroughCache<ClassOption>(
    cache: ref.read(referenceCacheProvider),
    isOnline: ref.read(isOnlineProvider),
    key: ReferenceCacheKeys.classes,
    ttl: kReferenceCacheTtl,
    fetch: () => ref.read(studentRepositoryProvider).loadClasses(),
    fromJson: ClassOption.fromJson,
    toJson: (c) => c.toJson(),
  );
});

/// Force a fresh network load of classes: drop the cache, then re-run the
/// provider. Use after a mutation (add/edit) or a manual "refresh" tap so the
/// change shows immediately instead of waiting for the TTL.
Future<void> refreshClasses(WidgetRef ref) async {
  await ref.read(referenceCacheProvider).bust(ReferenceCacheKeys.classes);
  ref.invalidate(classesProvider);
}

/// The currently selected class in the Browse screen (null = none yet).
final selectedClassProvider = StateProvider<ClassOption?>((ref) => null);

/// The free-text search filter applied to the roster.
final studentSearchProvider = StateProvider<String>((ref) => '');

/// The roster for the selected class. Empty when no class is chosen.
final rosterProvider = FutureProvider.autoDispose<List<StudentSummary>>((ref) async {
  final selected = ref.watch(selectedClassProvider);
  if (selected == null) return const [];
  return ref.watch(studentRepositoryProvider).loadStudents(selected.levelId);
});

/// The roster filtered by the current search text (case-insensitive match on
/// name or id).
final filteredRosterProvider =
Provider.autoDispose<AsyncValue<List<StudentSummary>>>((ref) {
  final asyncRoster = ref.watch(rosterProvider);
  final query = ref.watch(studentSearchProvider).trim().toLowerCase();

  return asyncRoster.whenData((roster) {
    if (query.isEmpty) return roster;
    return roster.where((s) {
      return s.studentName.toLowerCase().contains(query) ||
          s.studentId.toLowerCase().contains(query);
    }).toList();
  });
});

/// Detail for a single student, keyed by id.
final studentDetailProvider =
FutureProvider.autoDispose.family<StudentDetail, String>((ref, studentId) async {
  return ref.watch(studentRepositoryProvider).findStudent(studentId);
});
