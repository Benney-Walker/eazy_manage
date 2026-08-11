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

  Stream<NetworkStatus> get onStatusChange => _controller.stream;

  NetworkStatus get current => _last;

  void start() {
    _sub ??= _connectivity.onConnectivityChanged.listen((_) => _evaluate());
    _timer ??= Timer.periodic(
      const Duration(seconds: 20),
      (_) => _evaluate(),
    );
    // Fire an initial evaluation.
    _evaluate();
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
    // 1) Interface check.
    final results = await _connectivity.checkConnectivity();
    final hasInterface =
        results.any((r) => r != ConnectivityResult.none) && results.isNotEmpty;
    if (!hasInterface) return NetworkStatus.offline;

    // 2) Reachability probe against the API.
    try {
      // A HEAD to the base URL; any HTTP response means the server answered.
      await _probe.head('/');
      return NetworkStatus.online;
    } on DioException catch (e) {
      // Only genuine connection failures mean offline; an HTTP error status
      // still means the server was reachable.
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return NetworkStatus.offline;
      }
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
