import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'finance_models.dart';
import 'finance_repository.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.watch(apiClientProvider));
});

final financeLevelIdProvider = StateProvider<String?>((ref) => null);
final financeSemesterIdProvider = StateProvider<String?>((ref) => null);

/// True once both a class and a semester are chosen.
final financeContextReadyProvider = Provider<bool>((ref) {
  return ref.watch(financeLevelIdProvider) != null &&
      ref.watch(financeSemesterIdProvider) != null;
});

// ---- Fees Setup -----------------------------------------------------------

/// The fee for the current class + semester (null = not configured yet).
final feesDetailsProvider =
    FutureProvider.autoDispose<FeesDetails?>((ref) async {
  final levelId = ref.watch(financeLevelIdProvider);
  final semesterId = ref.watch(financeSemesterIdProvider);
  if (levelId == null || semesterId == null) return null;
  return ref
      .watch(financeRepositoryProvider)
      .fetchFeesDetails(semesterId: semesterId, levelId: levelId);
});

// ---- Payments -------------------------------------------------------------

/// The student whose payments are being recorded/viewed (null = none chosen).
final financeStudentIdProvider = StateProvider<String?>((ref) => null);

/// Payment records for the chosen student in the current class + semester.
final paymentRecordsProvider =
    FutureProvider.autoDispose<List<PaymentRecord>>((ref) async {
  final levelId = ref.watch(financeLevelIdProvider);
  final semesterId = ref.watch(financeSemesterIdProvider);
  final studentId = ref.watch(financeStudentIdProvider);
  if (levelId == null || semesterId == null || studentId == null) {
    return const [];
  }
  return ref.watch(financeRepositoryProvider).fetchPaymentRecords(
        studentId: studentId,
        levelId: levelId,
        semesterId: semesterId,
      );
});
