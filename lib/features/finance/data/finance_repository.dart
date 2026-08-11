import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import 'finance_models.dart';

class FinanceRepository {
  final ApiClient _api;

  FinanceRepository(this._api);

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

  Future<void> addPayment(NewPaymentRequest req) async {
    await _api.post(Endpoints.addFeesPayment, body: req.toJson());
  }

  Future<void> updatePayment(PaymentRecord record) async {
    await _api.put(Endpoints.updatePaymentDetails, body: record.toUpdateJson());
  }
}