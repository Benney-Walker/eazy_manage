class StudentSummary {
  final String studentId;
  final String studentName;

  const StudentSummary({required this.studentId, required this.studentName});

  factory StudentSummary.fromJson(Map<String, dynamic> j) => StudentSummary(
    studentId: (j['studentId'] ?? '').toString(),
    studentName: (j['studentName'] ?? '').toString(),
  );
}

class ClassOption {
  final String levelId;
  final String levelName;

  const ClassOption({required this.levelId, required this.levelName});

  factory ClassOption.fromJson(Map<String, dynamic> j) => ClassOption(
    levelId: (j['levelId'] ?? '').toString(),
    levelName: (j['levelName'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'levelId': levelId,
    'levelName': levelName,
  };

  @override
  bool operator ==(Object other) =>
      other is ClassOption && other.levelId == levelId;

  @override
  int get hashCode => levelId.hashCode;
}

class StudentDetail {
  final String studentId;
  final String firstName;
  final String lastName;
  final String gender;
  final String dateOfBirth;
  final String parentName;
  final String parentPhoneNumber;
  final String gradeId;
  final String status;
  final String homeTown;

  const StudentDetail({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    required this.parentName,
    required this.parentPhoneNumber,
    required this.gradeId,
    required this.status,
    required this.homeTown,
  });

  String get fullName => [firstName, lastName]
      .where((p) => p.trim().isNotEmpty)
      .join(' ')
      .trim();

  factory StudentDetail.fromJson(Map<String, dynamic> j) => StudentDetail(
    studentId: (j['studentId'] ?? '').toString(),
    firstName: (j['firstName'] ?? '').toString(),
    lastName: (j['lastName'] ?? '').toString(),
    gender: (j['gender'] ?? '').toString(),
    dateOfBirth: (j['dateOfBirth'] ?? '').toString(),
    parentName: (j['parentName'] ?? '').toString(),
    parentPhoneNumber: (j['parentPhoneNumber'] ?? '').toString(),
    gradeId: (j['gradeId'] ?? '').toString(),
    status: (j['status'] ?? '').toString(),
    homeTown: (j['homeTown'] ?? '').toString(),
  );

  /// Body for the update endpoint — the field names the backend expects.
  Map<String, dynamic> toUpdateJson() => {
    'studentId': studentId,
    'firstName': firstName,
    'lastName': lastName,
    'gender': gender,
    'dateOfBirth': dateOfBirth,
    'parentName': parentName,
    'parentPhoneNumber': parentPhoneNumber,
    'gradeId': gradeId,
    'status': status,
    'homeTown': homeTown,
  };

  StudentDetail copyWith({
    String? firstName,
    String? lastName,
    String? gender,
    String? dateOfBirth,
    String? parentName,
    String? parentPhoneNumber,
    String? gradeId,
    String? status,
    String? homeTown,
  }) =>
      StudentDetail(
        studentId: studentId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        parentName: parentName ?? this.parentName,
        parentPhoneNumber: parentPhoneNumber ?? this.parentPhoneNumber,
        gradeId: gradeId ?? this.gradeId,
        status: status ?? this.status,
        homeTown: homeTown ?? this.homeTown,
      );
}

/// Payload for `POST /student/v1/add-new-student`. Note the backend uses
/// `levelId`, `hometown` (lowercase t), and `guardianContact` here — distinct
/// from the update endpoint's field names.
class NewStudentRequest {
  final String firstName;
  final String lastName;
  final String levelId;
  final String gender;
  final String dateOfBirth; // ISO yyyy-MM-dd
  final String hometown;
  final String parentName;
  final String guardianContact;
  final bool isNew;

  const NewStudentRequest({
    required this.firstName,
    required this.lastName,
    required this.levelId,
    required this.gender,
    required this.dateOfBirth,
    required this.hometown,
    required this.parentName,
    required this.guardianContact,
    this.isNew = false,
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'levelId': levelId,
    'gender': gender,
    'dateOfBirth': dateOfBirth,
    'hometown': hometown,
    'parentName': parentName,
    'guardianContact': guardianContact,
    'isNew': isNew,
  };
}