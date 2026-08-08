import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'staff_models.dart';
import 'staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(apiClientProvider));
});

/// The full staff roster.
final staffRosterProvider =
    FutureProvider.autoDispose<List<StaffSummary>>((ref) async {
  return ref.watch(staffRepositoryProvider).loadStaff();
});

/// Free-text search over the roster.
final staffSearchProvider = StateProvider<String>((ref) => '');

/// Roster filtered by the current search text (name or id).
final filteredStaffProvider =
    Provider.autoDispose<AsyncValue<List<StaffSummary>>>((ref) {
  final async = ref.watch(staffRosterProvider);
  final query = ref.watch(staffSearchProvider).trim().toLowerCase();
  return async.whenData((roster) {
    if (query.isEmpty) return roster;
    return roster
        .where((s) =>
            s.staffName.toLowerCase().contains(query) ||
            s.staffId.toLowerCase().contains(query))
        .toList();
  });
});

/// Detail for a single staff member, keyed by id.
final staffDetailProvider =
    FutureProvider.autoDispose.family<StaffDetail, String>((ref, staffId) async {
  return ref.watch(staffRepositoryProvider).findStaff(staffId);
});
