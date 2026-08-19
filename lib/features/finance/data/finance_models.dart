// ===========================================================================
// FEES SETUP
// ===========================================================================

class FeesDetails {
  final int feesId;
  final String amount;
  final String semesterId;
  final String levelId;

  const FeesDetails({
    required this.feesId,
    required this.amount,
    required this.semesterId,
    required this.levelId,
  });

  bool get exists => feesId != 0 && amount.isNotEmpty;

  factory FeesDetails.fromJson(Map<String, dynamic> j) => FeesDetails(
    feesId: (j['feesId'] is num)
        ? (j['feesId'] as num).toInt()
        : int.tryParse('${j['feesId']}') ?? 0,
    amount: (j['amount'] ?? '').toString(),
    semesterId: (j['semesterId'] ?? '').toString(),
    levelId: (j['levelId'] ?? '').toString(),
  );

  Map<String, dynamic> toUpdateJson(String newAmount) => {
    'feesId': feesId,
    'amount': newAmount,
    'semesterId': semesterId,
    'classId': levelId,
  };
}

// ===========================================================================
// PAYMENTS
// ===========================================================================

class PaymentRecord {
  final String paymentId;
  final String dateOfPayment;
  final String studentId;
  final String studentName;
  final String amount;
  final String semesterId;
  final String payerName;
  final String payerContact;

  const PaymentRecord({
    required this.paymentId,
    required this.dateOfPayment,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.semesterId,
    required this.payerName,
    required this.payerContact,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> j) => PaymentRecord(
    paymentId: (j['paymentId'] ?? '').toString(),
    dateOfPayment: (j['dateOfPayment'] ?? '').toString(),
    studentId: (j['studentId'] ?? '').toString(),
    studentName: (j['studentName'] ?? '').toString(),
    amount: (j['amount'] ?? '').toString(),
    semesterId: (j['semesterId'] ?? '').toString(),
    payerName: (j['payerName'] ?? '').toString(),
    payerContact: (j['payerContact'] ?? '').toString(),
  );

  /// Body for `PUT /finance/v1/update-payment-details`.
  Map<String, dynamic> toUpdateJson() => {
    'paymentId': paymentId,
    'dateOfPayment': dateOfPayment,
    'studentId': studentId,
    'studentName': studentName,
    'amount': amount,
    'semesterId': semesterId,
    'payerName': payerName,
    'payerContact': payerContact,
  };

  PaymentRecord copyWith({
    String? dateOfPayment,
    String? amount,
    String? payerName,
    String? payerContact,
  }) =>
      PaymentRecord(
        paymentId: paymentId,
        dateOfPayment: dateOfPayment ?? this.dateOfPayment,
        studentId: studentId,
        studentName: studentName,
        amount: amount ?? this.amount,
        semesterId: semesterId,
        payerName: payerName ?? this.payerName,
        payerContact: payerContact ?? this.payerContact,
      );
}

class NewPaymentRequest {
  final String studentId;
  final String levelId;
  final String semesterId;
  final String amountPaid;
  final String payerName;
  final String payerPhone;

  const NewPaymentRequest({
    required this.studentId,
    required this.levelId,
    required this.semesterId,
    required this.amountPaid,
    required this.payerName,
    required this.payerPhone,
  });

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'levelId': levelId,
    'semesterId': semesterId,
    'amountPaid': amountPaid,
    'payerName': payerName,
    'payerPhone': payerPhone,
  };
}

// ---- Special payments -------------------------------------------------------

/// The only payment types the backend accepts.
enum SpecialPaymentType {
  stationary,
  admissionFee,
  other;

  /// Exact value the backend enum expects.
  String get backendValue => switch (this) {
    SpecialPaymentType.stationary => 'STATIONARY',
    SpecialPaymentType.admissionFee => 'ADMISSION_FEE',
    SpecialPaymentType.other => 'OTHER',
  };

  /// Human-friendly label for the UI.
  String get label => switch (this) {
    SpecialPaymentType.stationary => 'Stationary',
    SpecialPaymentType.admissionFee => 'Admission Fee',
    SpecialPaymentType.other => 'Other',
  };

  static SpecialPaymentType fromBackend(String v) => switch (v.toUpperCase()) {
    'STATIONARY' => SpecialPaymentType.stationary,
    'ADMISSION_FEE' => SpecialPaymentType.admissionFee,
    _ => SpecialPaymentType.other,
  };
}

/// One special-payment row (a payment expands to one row per class on load).
class SpecialPaymentRecord {
  final String id;
  final String type; // backend enum value
  final double amount;
  final String levelName;
  final String description;
  final String createdAt;

  const SpecialPaymentRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.levelName,
    required this.description,
    required this.createdAt,
  });

  factory SpecialPaymentRecord.fromJson(Map<String, dynamic> j) =>
      SpecialPaymentRecord(
        id: (j['id'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        levelName: (j['levelName'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        createdAt: (j['createdAt'] ?? '').toString(),
      );
}

class NewSpecialPaymentRequest {
  final SpecialPaymentType paymentType;
  final double amount;
  final List<String> levelList; // levelIds
  final String description;

  const NewSpecialPaymentRequest({
    required this.paymentType,
    required this.amount,
    required this.levelList,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'paymentType': paymentType.backendValue,
    'amount': amount,
    'levelList': levelList,
    'description': description,
  };
}

class UpdateSpecialPaymentRequest {
  final String id;
  final double amount;
  final String description;

  const UpdateSpecialPaymentRequest({
    required this.id,
    required this.amount,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'description': description,
  };
}

// ---- Expenses ---------------------------------------------------------------

class ExpensesRecord {
  final String expensesId;
  final String description;
  final double amountSpent;
  final String extraInfo;
  final String expenseDate;

  const ExpensesRecord({
    required this.expensesId,
    required this.description,
    required this.amountSpent,
    required this.extraInfo,
    required this.expenseDate,
  });

  factory ExpensesRecord.fromJson(Map<String, dynamic> j) => ExpensesRecord(
    expensesId: (j['expensesId'] ?? '').toString(),
    description: (j['description'] ?? '').toString(),
    amountSpent: (j['amountSpent'] as num?)?.toDouble() ?? 0,
    extraInfo: (j['extraInfo'] ?? '').toString(),
    expenseDate: (j['expenseDate'] ?? '').toString(),
  );
}

/// Blank extra info is sent as "no information" per the backend contract.
String _extraInfoOrDefault(String v) =>
    v.trim().isEmpty ? 'no information' : v.trim();

class NewExpensesRequest {
  final String description;
  final String extraInfo;
  final double amountSpent;
  final String semesterId;

  const NewExpensesRequest({
    required this.description,
    required this.extraInfo,
    required this.amountSpent,
    required this.semesterId,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'extraInfo': _extraInfoOrDefault(extraInfo),
    'amountSpent': amountSpent,
    'semesterId': semesterId,
  };
}

class UpdateExpensesRequest {
  final String expensesId;
  final String description;
  final double amountSpent;
  final String extraInfo;
  final String semesterId;

  const UpdateExpensesRequest({
    required this.expensesId,
    required this.description,
    required this.amountSpent,
    required this.extraInfo,
    required this.semesterId,
  });

  Map<String, dynamic> toJson() => {
    'expensesId': expensesId,
    'description': description,
    'amountSpent': amountSpent,
    'extraInfo': _extraInfoOrDefault(extraInfo),
    'semesterId': semesterId,
  };
}
