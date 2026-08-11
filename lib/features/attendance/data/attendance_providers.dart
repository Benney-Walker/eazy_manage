import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'attendance_models.dart';
import 'attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(apiClientProvider));
});

/// The class + semester being viewed.
final attendanceLevelIdProvider = StateProvider<String?>((ref) => null);
final attendanceSemesterIdProvider = StateProvider<String?>((ref) => null);

/// The date the user picked from the marked-dates list.
final attendanceDateProvider = StateProvider<String?>((ref) => null);

/// True once a class is chosen (dates-marked only needs the class).
final attendanceClassChosenProvider = Provider<bool>((ref) {
  return ref.watch(attendanceLevelIdProvider) != null;
});

/// True once class + semester + date are all chosen (records need all three).
final attendanceRecordsReadyProvider = Provider<bool>((ref) {
  return ref.watch(attendanceLevelIdProvider) != null &&
      ref.watch(attendanceSemesterIdProvider) != null &&
      ref.watch(attendanceDateProvider) != null;
});

/// The dates that have marked attendance for the chosen class.
final markedDatesProvider =
    FutureProvider.autoDispose<List<MarkedDate>>((ref) async {
  final levelId = ref.watch(attendanceLevelIdProvider);
  final semesterId = ref.watch(attendanceSemesterIdProvider);
  if (levelId == null || semesterId == null) return const [];
  final list = await ref.watch(attendanceRepositoryProvider).datesMarked(levelId, semesterId);
  // Most recent first (ISO date strings sort correctly).
  final sorted = [...list]..sort((a, b) => b.dateMarked.compareTo(a.dateMarked));
  return sorted;
});

/// The attendance records for the chosen class + semester + date.
final attendanceRecordsProvider =
    FutureProvider.autoDispose<List<StudentAttendance>>((ref) async {
  final levelId = ref.watch(attendanceLevelIdProvider);
  final semesterId = ref.watch(attendanceSemesterIdProvider);
  final date = ref.watch(attendanceDateProvider);
  if (levelId == null || semesterId == null || date == null) return const [];
  return ref.watch(attendanceRepositoryProvider).attendanceRecords(
        levelId: levelId,
        semesterId: semesterId,
        date: date,
      );
});
