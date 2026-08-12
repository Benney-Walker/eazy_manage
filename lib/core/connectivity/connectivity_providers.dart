import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../database/app_database.dart';
import 'connectivity_service.dart';
import 'drift_outbox.dart';
import 'local_first_writer.dart';
import 'outbox.dart';
import 'sync_engine.dart';

/// The connectivity service singleton. Started lazily the first time the
/// network status is watched.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// The app's live network status, driven automatically by the service — there
/// is no manual toggle. `checking` shows only until the first probe resolves.
class NetworkStatusController extends Notifier<NetworkStatus> {
  StreamSubscription<NetworkStatus>? _sub;

  @override
  NetworkStatus build() {
    final service = ref.watch(connectivityServiceProvider);

    _sub = service.onStatusChange.listen((status) => state = status);
    ref.onDispose(() => _sub?.cancel());

    // Start interface monitoring + the periodic re-probe.
    service.start();

    // Do the first check directly and push the result into state, rather than
    // relying on the broadcast stream (which doesn't buffer, so a fast initial
    // emission can be missed before this listener is pumping). This guarantees
    // we move off `checking` as soon as the first probe resolves.
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

/// The durable Drift database (holds the outbox on disk).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// The outbox of unsent writes — durable, backed by Drift/SQLite, so pending
/// offline writes survive an app restart.
final outboxProvider = Provider<Outbox>((ref) {
  return DriftOutbox(ref.watch(appDatabaseProvider));
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

/// The shared local-first write path for offline-capable domains (conduct,
/// results, payments). Records a write to the durable outbox immediately, then
/// pushes to the backend now if online — otherwise it drains on reconnect.
final localFirstWriterProvider = Provider<LocalFirstWriter>((ref) {
  return LocalFirstWriter(
    outbox: ref.watch(outboxProvider),
    engine: ref.watch(syncEngineProvider),
    isOnline: () => ref.read(isOnlineProvider),
  );
});
