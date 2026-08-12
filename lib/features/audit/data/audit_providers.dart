import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'audit_models.dart';
import 'audit_repository.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(apiClientProvider));
});

/// The active audit-log query: a date range and an optional staff filter.
/// When [selectedStaffId] is null/empty the timely (all-staff) endpoint is
/// used; otherwise the staff-specific endpoint. Null dates means "not yet run".
class AuditFilter {
  final String? fromDate; // ISO yyyy-MM-dd
  final String? toDate;
  final String? selectedStaffId;

  const AuditFilter({this.fromDate, this.toDate, this.selectedStaffId});

  bool get isReady =>
      (fromDate?.isNotEmpty ?? false) && (toDate?.isNotEmpty ?? false);

  bool get isStaffMode =>
      selectedStaffId != null && selectedStaffId!.isNotEmpty;

  AuditFilter copyWith({
    String? fromDate,
    String? toDate,
    String? selectedStaffId,
    bool clearStaff = false,
  }) =>
      AuditFilter(
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        selectedStaffId:
            clearStaff ? null : (selectedStaffId ?? this.selectedStaffId),
      );

  @override
  bool operator ==(Object other) =>
      other is AuditFilter &&
      other.fromDate == fromDate &&
      other.toDate == toDate &&
      other.selectedStaffId == selectedStaffId;

  @override
  int get hashCode => Object.hash(fromDate, toDate, selectedStaffId);
}

/// The current filter (driven by the UI controls).
final auditFilterProvider =
    StateProvider<AuditFilter>((ref) => const AuditFilter());

/// The logs for the current filter. Returns null until a valid range is set.
final auditLogsProvider =
    FutureProvider.autoDispose<List<AuditLog>?>((ref) async {
  final filter = ref.watch(auditFilterProvider);
  if (!filter.isReady) return null;

  final repo = ref.watch(auditRepositoryProvider);
  if (filter.isStaffMode) {
    return repo.staffLogs(
      selectedStaffId: filter.selectedStaffId!,
      fromDate: filter.fromDate!,
      toDate: filter.toDate!,
    );
  }
  return repo.timelyLogs(fromDate: filter.fromDate!, toDate: filter.toDate!);
});
