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

  Future<FeesDetails?> fetchFeesDetails({
    required String semesterId,
    required String levelId,
  }) async {
    try {
      final res = await _api.get(
        Endpoints.fetchFeesDetails(semesterId, levelId),
        triggerLogoutOn401: false,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final fees = FeesDetails.fromJson(data);
        return fees.exists ? fees : null;
      }
      return null;
    } on ApiException catch (e) {
      // No fee set yet is commonly a 404 — treat that as "not configured"
      // rather than surfacing an error state.
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /finance/v2/new-fees?classId=&semesterId=&feesAmount= (no body).
  Future<void> addFees({
    required String classId,
    required String semesterId,
    required String feesAmount,
  }) async {
    final path = Endpoints.newFees(
      Uri.encodeQueryComponent(classId),
      Uri.encodeQueryComponent(semesterId),
      Uri.encodeQueryComponent(feesAmount),
    );
    await _api.post(path);
  }

  /// PUT /finance/v2/update-semester-fees.
  Future<void> updateFees(FeesDetails existing, String newAmount) async {
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
}