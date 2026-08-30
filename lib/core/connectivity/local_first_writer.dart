import 'dart:async';

import 'outbox.dart';
import 'sync_engine.dart';

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

    if (_isOnline()) {
      unawaited(_engine.drainNow());
    }
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  static int _counter = 0;
}