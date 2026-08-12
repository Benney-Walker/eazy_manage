import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import 'broadcast_models.dart';

/// Sends SMS and email broadcasts. These are online, user-initiated actions
/// (not part of the offline-capable set), so they use the API directly and let
/// auth failures surface normally.
class BroadcastRepository {
  final ApiClient _api;

  BroadcastRepository(this._api);

  /// POST /admin/v1/broadcasts-message.
  Future<void> sendSms(BroadcastSmsRequest req) async {
    await _api.post(Endpoints.broadcastSms, body: req.toJson());
  }

  /// POST /admin/v1/broadcast-email.
  Future<void> sendEmail(BroadcastEmailRequest req) async {
    await _api.post(Endpoints.broadcastEmail, body: req.toJson());
  }
}
