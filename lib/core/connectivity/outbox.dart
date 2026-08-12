import 'dart:async';

enum OutboxMethod { post, put, delete }

class OutboxEntry {
  final String id;
  final OutboxMethod method;
  final String path;

  final Object? body;

  final String description;

  final DateTime queuedAt;

  const OutboxEntry({
    required this.id,
    required this.method,
    required this.path,
    required this.description,
    required this.queuedAt,
    this.body,
  });
}

abstract class Outbox {
  /// All currently queued entries, oldest first.
  Future<List<OutboxEntry>> pending();

  /// Number of queued entries (synchronous convenience for badges/labels).
  int get pendingCount;

  /// Emits the pending count whenever it changes.
  Stream<int> get pendingCountStream;

  Future<void> enqueue(OutboxEntry entry);

  Future<void> remove(String id);

  Future<void> clear();
}

class InMemoryOutbox implements Outbox {
  final List<OutboxEntry> _entries = [];
  final _countController = StreamController<int>.broadcast();

  @override
  Future<List<OutboxEntry>> pending() async =>
      List.unmodifiable(_entries);

  @override
  int get pendingCount => _entries.length;

  @override
  Stream<int> get pendingCountStream => _countController.stream;

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    _entries.add(entry);
    _emit();
  }

  @override
  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    _emit();
  }

  @override
  Future<void> clear() async {
    _entries.clear();
    _emit();
  }

  void _emit() {
    if (!_countController.isClosed) _countController.add(_entries.length);
  }

  void dispose() => _countController.close();
}