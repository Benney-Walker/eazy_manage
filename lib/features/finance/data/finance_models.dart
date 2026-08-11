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

  /// Body for `PUT /finance/v2/update-semester-fees`.
  /// Note: the update endpoint calls the class field `classId`, not `levelId`.
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
