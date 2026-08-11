/// Models for the (view-only) Attendance domain. Marking now happens in the
/// Eazy Attendance Android app; the desktop app only views records.
/// Field names mirror the JavaFX DTOs `DatesMarked` and `StudentAttendance`.

/// A date on which attendance was marked for a class —
/// `GET /student/v1/dates-marked/{levelId}` (mirrors `DatesMarked`).
class MarkedDate {
  final String dateMarked; // ISO yyyy-MM-dd
  final String dayMarked; // e.g. "Monday"
  final String staffName; // who marked it

  const MarkedDate({
    required this.dateMarked,
    required this.dayMarked,
    required this.staffName,
  });

  factory MarkedDate.fromJson(Map<String, dynamic> j) => MarkedDate(
        dateMarked: (j['dateMarked'] ?? '').toString(),
        dayMarked: (j['dayMarked'] ?? '').toString(),
        staffName: (j['staffName'] ?? '').toString(),
      );
}

/// Attendance status values (mirrors `AttendanceStatus`).
class AttendanceStatus {
  static const present = 'PRESENT';
  static const absent = 'ABSENT';

  static String label(String raw) {
    return switch (raw.toUpperCase()) {
      present => 'Present',
      absent => 'Absent',
      _ => raw,
    };
  }

  static bool isPresent(String raw) => raw.toUpperCase() == present;
}

/// One student's attendance on a given date —
/// `GET /student/v1/attendance-records` (mirrors `StudentAttendance`).
class StudentAttendance {
  final String studentId;
  final String studentName;
  final String status;

  const StudentAttendance({
    required this.studentId,
    required this.studentName,
    required this.status,
  });

  factory StudentAttendance.fromJson(Map<String, dynamic> j) =>
      StudentAttendance(
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
      );

  bool get isPresent => AttendanceStatus.isPresent(status);
}
