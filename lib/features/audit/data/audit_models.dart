/// An audit-log entry (mirrors the JavaFX `LogsDTO`).
class AuditLog {
  final String id;
  final String date;
  final String time;
  final String type;
  final String message;
  final String status;
  final String createdBy;

  const AuditLog({
    required this.id,
    required this.date,
    required this.time,
    required this.type,
    required this.message,
    required this.status,
    required this.createdBy,
  });

  factory AuditLog.fromJson(Map<String, dynamic> j) => AuditLog(
        id: (j['id'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        time: (j['time'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        createdBy: (j['createdBy'] ?? '').toString(),
      );

  /// A loose success/failure read of the status, for colour-coding.
  bool get isSuccess {
    final s = status.toUpperCase();
    return s.contains('SUCCESS') || s == 'OK' || s.contains('PASS');
  }

  bool get isFailure {
    final s = status.toUpperCase();
    return s.contains('FAIL') || s.contains('ERROR') || s.contains('DENIED');
  }
}
