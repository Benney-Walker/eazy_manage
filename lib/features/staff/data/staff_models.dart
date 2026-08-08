/// Models for the Staff domain, mirroring the JavaFX DTOs
/// (`StaffCaching`, `FindStaffResponse`).

/// The set of staff roles the backend recognizes (mirrors `StaffRoles`).
class StaffRoles {
  static const principal = 'PRINCIPAL';
  static const accountant = 'ACCOUNTANT';
  static const teachingStaff = 'TEACHING_STAFF';
  static const generalStaff = 'GENERAL_STAFF';
  static const administrator = 'ADMINISTRATOR';

  static const all = [
    principal,
    administrator,
    accountant,
    teachingStaff,
    generalStaff,
  ];

  /// Human label for a backend role string (e.g. TEACHING_STAFF -> Teaching Staff).
  static String label(String raw) {
    return switch (raw.toUpperCase()) {
      principal => 'Principal',
      administrator => 'Administrator',
      accountant => 'Accountant',
      teachingStaff => 'Teaching Staff',
      generalStaff => 'General Staff',
      _ => raw,
    };
  }
}

/// Staff status values (mirrors `StaffStatus`).
class StaffStatus {
  static const active = 'ACTIVE';
  static const inactive = 'INACTIVE';
  static const all = [active, inactive];
}

/// A lightweight staff row — what `GET /staff/v1/load-staffs-info` returns
/// (mirrors `StaffCaching`).
class StaffSummary {
  final String staffId;
  final String staffName;

  const StaffSummary({required this.staffId, required this.staffName});

  factory StaffSummary.fromJson(Map<String, dynamic> j) => StaffSummary(
        staffId: (j['staffId'] ?? '').toString(),
        staffName: (j['staffName'] ?? '').toString(),
      );
}

/// Full staff detail — what `GET /staff/v1/find-staff-by-id/{id}` returns and
/// what `PUT /admin/v1/update-staff-info` accepts (mirrors `FindStaffResponse`).
///
/// Note the field name is `surname` here (find/update), which corresponds to
/// `lastName` in the enroll payload.
class StaffDetail {
  final String staffId;
  final String firstName;
  final String surname;
  final String gender;
  final String dateOfBirth;
  final String email;
  final String phoneNumber;
  final List<String> staffRoles;
  final String staffStatus;
  final String dateOfRegistration;

  const StaffDetail({
    required this.staffId,
    required this.firstName,
    required this.surname,
    required this.gender,
    required this.dateOfBirth,
    required this.email,
    required this.phoneNumber,
    required this.staffRoles,
    required this.staffStatus,
    required this.dateOfRegistration,
  });

  String get fullName => [firstName, surname]
      .where((p) => p.trim().isNotEmpty)
      .join(' ')
      .trim();

  factory StaffDetail.fromJson(Map<String, dynamic> j) => StaffDetail(
        staffId: (j['staffId'] ?? '').toString(),
        firstName: (j['firstName'] ?? '').toString(),
        surname: (j['surname'] ?? '').toString(),
        gender: (j['gender'] ?? '').toString(),
        dateOfBirth: (j['dateOfBirth'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        phoneNumber: (j['phoneNumber'] ?? '').toString(),
        staffRoles: (j['staffRoles'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        staffStatus: (j['staffStatus'] ?? '').toString(),
        dateOfRegistration: (j['dateOfRegistration'] ?? '').toString(),
      );

  /// Body for `PUT /admin/v1/update-staff-info`.
  Map<String, dynamic> toUpdateJson() => {
        'staffId': staffId,
        'firstName': firstName,
        'surname': surname,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'email': email,
        'phoneNumber': phoneNumber,
        'staffRoles': staffRoles,
        'staffStatus': staffStatus,
        'dateOfRegistration': dateOfRegistration,
      };

  StaffDetail copyWith({
    String? firstName,
    String? surname,
    String? gender,
    String? dateOfBirth,
    String? email,
    String? phoneNumber,
    List<String>? staffRoles,
    String? staffStatus,
    String? dateOfRegistration,
  }) =>
      StaffDetail(
        staffId: staffId,
        firstName: firstName ?? this.firstName,
        surname: surname ?? this.surname,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        email: email ?? this.email,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        staffRoles: staffRoles ?? this.staffRoles,
        staffStatus: staffStatus ?? this.staffStatus,
        dateOfRegistration: dateOfRegistration ?? this.dateOfRegistration,
      );
}

/// Payload for `POST /auth/v1/enroll-new-staff`. Uses `lastName` (not
/// `surname`) and `roles` (not `staffRoles`), matching the enroll endpoint.
class NewStaffRequest {
  final String firstName;
  final String lastName;
  final String gender;
  final String dateOfBirth; // ISO yyyy-MM-dd
  final String email;
  final String phoneNumber;
  final String institutionId;
  final String password;
  final List<String> roles;

  const NewStaffRequest({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    required this.email,
    required this.phoneNumber,
    required this.institutionId,
    required this.password,
    required this.roles,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'email': email,
        'phoneNumber': phoneNumber,
        'institutionId': institutionId,
        'password': password,
        'roles': roles,
      };
}
