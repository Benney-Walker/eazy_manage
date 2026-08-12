import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The durable outbox: one row per queued write. Persists on disk so pending
/// offline writes survive an app restart.
///
/// Columns mirror an `OutboxEntry`: the HTTP method, path, optional JSON body
/// (stored as a text blob), a human description, and when it was queued.
class OutboxRows extends Table {
  /// Client-generated unique id (also the OutboxEntry id).
  TextColumn get id => text()();

  /// 'post' | 'put' | 'delete' (OutboxMethod.name).
  TextColumn get method => text()();

  TextColumn get path => text()();

  /// JSON-encoded body, or null.
  TextColumn get body => text().nullable()();

  TextColumn get description => text().withDefault(const Constant(''))();

  DateTimeColumn get queuedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [OutboxRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test/alternate constructor allowing an injected executor.
  AppDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  // ---- Outbox queries ----

  Future<List<OutboxRow>> allOutbox() {
    return (select(outboxRows)
          ..orderBy([(t) => OrderingTerm.asc(t.queuedAt)]))
        .get();
  }

  Future<void> insertOutbox(OutboxRow row) =>
      into(outboxRows).insertOnConflictUpdate(row);

  Future<void> deleteOutbox(String id) =>
      (delete(outboxRows)..where((t) => t.id.equals(id))).go();

  Future<void> clearOutbox() => delete(outboxRows).go();

  Stream<int> watchOutboxCount() {
    final countExp = outboxRows.id.count();
    final query = selectOnly(outboxRows)..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'eazymanage.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
