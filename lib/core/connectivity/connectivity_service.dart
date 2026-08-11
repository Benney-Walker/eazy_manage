import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../api/api_config.dart';

enum NetworkStatus { online, offline, checking }


class ConnectivityService {
  final Connectivity _connectivity;
  final Dio _probe;

  final _controller = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _timer;

  NetworkStatus _last = NetworkStatus.checking;

  ConnectivityService({Connectivity? connectivity, Dio? probeClient})
      : _connectivity = connectivity ?? Connectivity(),
        _probe = probeClient ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.BASE_URL,
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
              // Any status is a valid "response" for reachability purposes.
              validateStatus: (_) => true,
            ));

  /// Broadcast stream of status changes. Late subscribers get the current
  /// status replayed via [current].
  Stream<NetworkStatus> get onStatusChange => _controller.stream;

  NetworkStatus get current => _last;

  /// Begin monitoring. Safe to call once; wires the interface listener and
  /// starts the periodic re-probe. The initial probe is driven by the caller
  /// via [checkNow] so its result can be awaited directly.
  void start() {
    _sub ??= _connectivity.onConnectivityChanged.listen((_) => _evaluate());
    _timer ??= Timer.periodic(
      const Duration(seconds: 20),
          (_) => _evaluate(),
    );
  }

  /// Force an immediate re-check (used by the manual "Sync now" flow and on
  /// app resume). Returns the freshly determined status.
  Future<NetworkStatus> checkNow() => _evaluate();

  Future<NetworkStatus> _evaluate() async {
    final status = await _determine();
    if (status != _last) {
      _last = status;
      if (!_controller.isClosed) _controller.add(status);
    }
    return status;
  }

  Future<NetworkStatus> _determine() async {
    // 1) Interface check. If connectivity_plus fails or is unreliable on this
    // platform (it can be flaky on desktop), don't get stuck — fall through to
    // the reachability probe, which is the authoritative signal anyway.
    try {
      final results = await _connectivity.checkConnectivity();
      final hasInterface =
          results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        // No interface reported. Double-check with the probe before declaring
        // offline, since desktop connectivity_plus sometimes under-reports.
        return await _probeReachable();
      }
    } catch (_) {
      // Ignore and let the probe decide.
    }

    // 2) Reachability probe against the server (authoritative).
    return _probeReachable();
  }

  Future<NetworkStatus> _probeReachable() async {
    try {
      // A GET to the server root. We don't care about the status code — a 404
      // or 401 still proves the server answered, which is all "reachable"
      // means. HEAD is avoided because some servers reject or hang on it.
      await _probe.get('/');
      return NetworkStatus.online;
    } on DioException catch (e) {
      // Only genuine connection failures mean offline; any HTTP response
      // (even an error status) means the server was reachable.
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.badCertificate) {
        return NetworkStatus.offline;
      }
      // badResponse / cancel / unknown-with-a-response → server answered.
      return NetworkStatus.online;
    } catch (_) {
      return NetworkStatus.offline;
    }
  }

  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    _controller.close();
  }
}