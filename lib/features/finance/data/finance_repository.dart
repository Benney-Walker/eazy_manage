import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../../core/connectivity/local_first_writer.dart';
import '../../../core/connectivity/outbox.dart';
import 'finance_models.dart';

class FinanceRepository {
  final ApiClient _api;
  final LocalFirstWriter _writer;

  FinanceRepository(this._api, this._writer);

  // ---- Fees Setup ---------------------------------------------------------

  Future<List<FeesDetails>> fetchFeesDetails(String semesterId) async {
    try {
      final res = await _api.get(
        Endpoints.fetchFeesDetails(semesterId),
        triggerLogoutOn401: false,
      );
      final list = res.data;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(FeesDetails.fromJson)
            .toList();
      }
      return const [];
    } on ApiException catch (e) {
      // No fees set for the term yet is commonly a 404 — treat as empty.
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// POST /finance/v2/new-fees?classId=&semesterId=&feesAmount= (no body).
  Future<void> addFees(NewFeesRequest req) async {
    await _api.post(Endpoints.newFees, body: req.toJson());
  }

  /// PUT /finance/v2/update-semester-fees.
  Future<void> updateFees(FeesDetails existing, double newAmount) async {
    await _api.put(
      Endpoints.updateSemesterFees,
      body: existing.toUpdateJson(newAmount),
    );
  }

  // ---- Payments -----------------------------------------------------------

  /// GET /finance/v1/fetch-payment-records?studentId=&levelId=&semesterId=.
  Future<List<PaymentRecord>> fetchPaymentRecords({
    required String studentId,
    required String levelId,
    required String semesterId,
  }) async {
    final res = await _api.get(
      Endpoints.fetchPaymentRecords(studentId, levelId, semesterId),
      triggerLogoutOn401: false,
    );
    final list = res.data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(PaymentRecord.fromJson)
          .toList();
    }
    return const [];
  }

  /// POST /finance/v1/add-fees-payment — local-first. Returns as soon as the
  /// write is queued durably; the network push happens in the background.
  Future<void> addPayment(NewPaymentRequest req) async {
    await _writer.submit(
      method: OutboxMethod.post,
      path: Endpoints.addFeesPayment,
      description: 'Payment for student ${req.studentId}',
      body: req.toJson(),
    );
  }

  /// PUT /finance/v1/update-payment-details — local-first.
  Future<void> updatePayment(PaymentRecord record) async {
    await _writer.submit(
      method: OutboxMethod.put,
      path: Endpoints.updatePaymentDetails,
      description:
      'Payment update for ${record.studentName} (${record.studentId})',
      body: record.toUpdateJson(),
    );
  }

  // ---- Special payments ---------------------------------------------------

  Future<List<SpecialPaymentRecord>> loadSpecialFees(
      SpecialPaymentType type) async {
    try {
      final res = await _api.get(
        Endpoints.loadSpecialFees(type.backendValue),
        triggerLogoutOn401: false,
      );
      final list = res.data;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(SpecialPaymentRecord.fromJson)
            .toList();
      }
      return const [];
    } on ApiException catch (e) {
      // Backend returns 404 when there are none of this type yet.
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<void> addSpecialFee(NewSpecialPaymentRequest req) async {
    await _api.post(Endpoints.addSpecialFee, body: req.toJson());
  }

  Future<void> updateSpecialFee(UpdateSpecialPaymentRequest req) async {
    await _api.put(Endpoints.updateSpecialFee, body: req.toJson());
  }

  // ---- Expenses -----------------------------------------------------------

  Future<List<ExpensesRecord>> readExpenses(String semesterId) async {
    try {
      final res = await _api.get(
        Endpoints.readExpensesRecords(semesterId),
        triggerLogoutOn401: false,
      );
      final list = res.data;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(ExpensesRecord.fromJson)
            .toList();
      }
      return const [];
    } on ApiException catch (e) {
      // 404 = no expenses recorded for this term yet.
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<void> addExpense(NewExpensesRequest req) async {
    await _api.post(Endpoints.addNewExpenses, body: req.toJson());
  }

  Future<void> updateExpense(UpdateExpensesRequest req) async {
    await _api.put(Endpoints.updateExpenseRecord, body: req.toJson());
  }

  Future<void> deleteExpense(String expensesId) async {
    await _api.delete(Endpoints.deleteExpenses(expensesId));
  }

  Future<double> totalExpenses() async {
    try {
      final res =
      await _api.get(Endpoints.totalExpenses, triggerLogoutOn401: false);
      final d = res.data;
      if (d is num) return d.toDouble();
      if (d is String) return double.tryParse(d) ?? 0;
      if (d is Map) {
        final v = d['total'] ?? d['totalExpenses'] ?? d['amount'];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v) ?? 0;
      }
      return 0;
    } on ApiException catch (e) {
      // 404 = no expenses (or no current term) → treat as zero.
      if (e.statusCode == 404) return 0;
      rethrow;
    }
  }
}