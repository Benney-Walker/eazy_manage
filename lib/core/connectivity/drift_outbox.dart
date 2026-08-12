import 'dart:convert';

import '../database/app_database.dart';
import 'outbox.dart';

/// A durable [Outbox] backed by Drift/SQLite. Queued writes persist on disk, so
/// pending offline records survive an app restart. Drop-in replacement for
/// [InMemoryOutbox] — same interface, swapped at the provider.
class DriftOutbox implements Outbox {
  final AppDatabase _db;

  DriftOutbox(this._db);

  int _cachedCount = 0;

  @override
  Future<List<OutboxEntry>> pending() async {
    final rows = await _db.allOutbox();
    _cachedCount = rows.length;
    return rows.map(_toEntry).toList();
  }

  @override
  int get pendingCount => _cachedCount;

  @override
  Stream<int> get pendingCountStream =>
      _db.watchOutboxCount().map((c) {
        _cachedCount = c;
        return c;
      });

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    await _db.insertOutbox(_toRow(entry));
  }

  @override
  Future<void> remove(String id) async {
    await _db.deleteOutbox(id);
  }

  @override
  Future<void> clear() async {
    await _db.clearOutbox();
  }

  // ---- Mapping ----

  OutboxEntry _toEntry(OutboxRow r) => OutboxEntry(
        id: r.id,
        method: OutboxMethod.values.firstWhere(
          (m) => m.name == r.method,
          orElse: () => OutboxMethod.post,
        ),
        path: r.path,
        description: r.description,
        queuedAt: r.queuedAt,
        body: r.body == null
            ? null
            : (jsonDecode(r.body!) as Map<String, dynamic>),
      );

  OutboxRow _toRow(OutboxEntry e) => OutboxRow(
        id: e.id,
        method: e.method.name,
        path: e.path,
        description: e.description,
        queuedAt: e.queuedAt,
        body: e.body == null ? null : jsonEncode(e.body),
      );
}
