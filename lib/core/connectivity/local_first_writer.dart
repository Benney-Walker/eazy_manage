import 'dart:async';

import 'outbox.dart';
import 'sync_engine.dart';

/// A tiny helper that gives repositories a **local-first write**: the write is
/// recorded to the [Outbox] immediately (so the UI can treat it as saved and
/// return instantly), and — if the app is online — a drain is kicked off right
/// away so it reaches the backend without waiting for the periodic sync.
///
/// When offline, the entry simply stays queued and the [SyncEngine] drains it
/// automatically on reconnect. Callers therefore never have to branch on
/// connectivity themselves.
///
/// This is the shared write path for the offline-capable domains (conduct,
/// results, payments).
class LocalFirstWriter {
  final Outbox _outbox;
  final SyncEngine _engine;
  final bool Function() _isOnline;

  LocalFirstWriter({
    required Outbox outbox,
    required SyncEngine engine,
    required bool Function() isOnline,
  })  : _outbox = outbox,
        _engine = engine,
        _isOnline = isOnline;

  /// Record a write locally, then push now if connected. Returns once the entry
  /// is queued (fast) — the actual network push happens in the background drain
  /// so the UI is never blocked on it.
  Future<void> submit({
    required OutboxMethod method,
    required String path,
    required String description,
    Object? body,
  }) async {
    final entry = OutboxEntry(
      id: _newId(),
      method: method,
      path: path,
      description: description,
      body: body,
      queuedAt: DateTime.now(),
    );
    await _outbox.enqueue(entry);

    // If we're online, drain immediately so the record reaches the server now
    // rather than on the next periodic sweep. Fire-and-forget: the engine
    // guards against concurrent drains and reports progress via its state.
    if (_isOnline()) {
      unawaited(_engine.drainNow());
    }
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  static int _counter = 0;
}