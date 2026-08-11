import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import 'connectivity_service.dart';
import 'outbox.dart';
import 'sync_engine.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

class NetworkStatusController extends Notifier<NetworkStatus> {
  StreamSubscription<NetworkStatus>? _sub;

  @override
  NetworkStatus build() {
    final service = ref.watch(connectivityServiceProvider);

    _sub = service.onStatusChange.listen((status) => state = status);
    ref.onDispose(() => _sub?.cancel());

    // Start interface monitoring + the periodic re-probe.
    service.start();

    service.checkNow().then((status) {
      state = status;
    });

    return service.current;
  }

  /// Force an immediate re-check (used by "Sync now" and on app resume).
  Future<void> refresh() async {
    await ref.read(connectivityServiceProvider).checkNow();
  }
}

final networkStatusProvider =
NotifierProvider<NetworkStatusController, NetworkStatus>(
    NetworkStatusController.new);

/// Convenience: true when the app currently has a reachable server.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(networkStatusProvider) == NetworkStatus.online;
});

/// The outbox of unsent writes. In-memory for now; a durable implementation
/// can be swapped in here later without touching callers.
final outboxProvider = Provider<Outbox>((ref) {
  final box = InMemoryOutbox();
  ref.onDispose(box.dispose);
  return box;
});

/// The drain engine. Watches network status and auto-drains on reconnect.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    ref.watch(apiClientProvider),
    ref.watch(outboxProvider),
  );
  ref.onDispose(engine.dispose);

  // Bind connectivity → engine: whenever the status changes, tell the engine,
  // so becoming online triggers an automatic drain.
  ref.listen<NetworkStatus>(networkStatusProvider, (_, next) {
    engine.onNetworkStatus(next);
  }, fireImmediately: true);

  return engine;
});

/// The engine's live [SyncState] for the Settings UI (syncing / pending / etc).
final syncStateProvider = StreamProvider<SyncState>((ref) {
  final engine = ref.watch(syncEngineProvider);
  // Seed with the current state, then follow updates.
  return Stream<SyncState>.multi((controller) {
    controller.add(engine.state);
    final sub = engine.onState.listen(controller.add);
    ref.onDispose(sub.cancel);
  });
});