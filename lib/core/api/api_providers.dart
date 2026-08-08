import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'token_storage.dart';

/// Secure storage singleton.
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// The Dio-backed API client. Its `onUnauthorized` hook is wired in the auth
/// controller so a 401 anywhere clears the session and routes to login.
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(storage: storage);
});
