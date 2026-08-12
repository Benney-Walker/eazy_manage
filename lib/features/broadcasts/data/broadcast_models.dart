/// Models for the Broadcasts (messaging) domain. The JSON keys below match the
/// EXACT wire format serialized by the JavaFX `MessagingService` — note these
/// differ from the DTO field names (smsText -> "message", mailSubject ->
/// "subject", mailBody -> "body"). The `audience` is a flat list of role keys
/// (e.g. TEACHING_STAFF) and/or class levelIds.

/// The staff roles that can be targeted (mirrors STAFF_ROLE_LABELS).
class BroadcastRoles {
  static const entries = <MapEntry<String, String>>[
    MapEntry('PRINCIPAL', 'Principal'),
    MapEntry('ADMINISTRATOR', 'Administrator'),
    MapEntry('ACCOUNTANT', 'Accountant'),
    MapEntry('TEACHING_STAFF', 'Teaching staff'),
    MapEntry('GENERAL_STAFF', 'General staff'),
  ];
}

/// Request body for `POST /admin/v1/broadcasts-message`.
/// Serializes to: { "message": ..., "audience": [...] }
class BroadcastSmsRequest {
  final String message;
  final List<String> audience;

  const BroadcastSmsRequest({required this.message, required this.audience});

  Map<String, dynamic> toJson() => {
        'message': message,
        'audience': audience,
      };
}

/// Request body for `POST /admin/v1/broadcast-email`.
/// Serializes to: { "subject": ..., "body": ..., "audience": [...] }
class BroadcastEmailRequest {
  final String subject;
  final String body;
  final List<String> audience;

  const BroadcastEmailRequest({
    required this.subject,
    required this.body,
    required this.audience,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'body': body,
        'audience': audience,
      };
}
