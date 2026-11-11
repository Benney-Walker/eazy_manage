import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eazy_manage/core/api/api_client.dart';
import 'package:eazy_manage/core/api/token_storage.dart';
import 'package:eazy_manage/core/connectivity/outbox.dart';
import 'package:eazy_manage/core/connectivity/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each request path with a scripted status code, or throws a
/// connection error for paths listed in [unreachable]. Records call order.
class _ScriptedAdapter implements HttpClientAdapter {
  final Map<String, int> statusByPath;
  final Set<String> unreachable;
  final List<String> calls = [];

  _ScriptedAdapter({this.statusByPath = const {}, this.unreachable = const {}});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.path);
    if (unreachable.contains(options.path)) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final code = statusByPath[options.path] ?? 200;
    return ResponseBody.fromString(
      jsonEncode({'message': 'status $code'}),
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

OutboxEntry _entry(String id, String path) => OutboxEntry(
      id: id,
      method: OutboxMethod.post,
      path: path,
      description: 'entry $id',
      body: const {'k': 'v'},
      queuedAt: DateTime(2026, 1, 1),
    );

void main() {
  late InMemoryOutbox outbox;
  late _ScriptedAdapter adapter;
  late SyncEngine engine;

  Future<void> arrange(_ScriptedAdapter a, List<OutboxEntry> entries) async {
    adapter = a;
    final dio = Dio(BaseOptions(
      baseUrl: 'http://test.local/api',
      validateStatus: (_) => true,
    ))
      ..httpClientAdapter = adapter;
    // Credentials in memory, so the interceptor never touches secure storage.
    final api = ApiClient(storage: TokenStorage(), dio: dio)
      ..setCredentials(token: 'access', refreshToken: 'refresh');
    outbox = InMemoryOutbox();
    for (final e in entries) {
      await outbox.enqueue(e);
    }
    engine = SyncEngine(api, outbox);
  }

  tearDown(() {
    engine.dispose();
    outbox.dispose();
  });

  test('drains every entry when the server accepts them', () async {
    await arrange(_ScriptedAdapter(), [_entry('1', '/a'), _entry('2', '/b')]);

    await engine.drainNow();

    expect(await outbox.pending(), isEmpty);
    expect(adapter.calls, ['/a', '/b']);
    expect(engine.state.phase, SyncPhase.idle);
    expect(engine.state.rejected, 0);
    expect(engine.state.lastSyncedAt, isNotNull);
  });

  test('a rejected entry stays queued but does not block later entries',
      () async {
    await arrange(
      _ScriptedAdapter(statusByPath: {'/a': 409}),
      [_entry('1', '/a'), _entry('2', '/b')],
    );

    await engine.drainNow();

    final remaining = await outbox.pending();
    expect(remaining.map((e) => e.id), ['1']);
    expect(adapter.calls, ['/a', '/b']);
    expect(engine.state.phase, SyncPhase.error);
    expect(engine.state.rejected, 1);
    expect(engine.state.pending, 1);
    expect(engine.state.lastError, contains('rejected by the server'));
  });

  test('a network failure stops the drain and keeps everything queued',
      () async {
    await arrange(
      _ScriptedAdapter(unreachable: {'/a'}),
      [_entry('1', '/a'), _entry('2', '/b')],
    );

    await engine.drainNow();

    expect((await outbox.pending()).map((e) => e.id), ['1', '2']);
    expect(adapter.calls, ['/a']);
    expect(engine.state.phase, SyncPhase.error);
    expect(engine.state.rejected, 0);
  });

  test('a server error (5xx) stops the drain', () async {
    await arrange(
      _ScriptedAdapter(statusByPath: {'/a': 503}),
      [_entry('1', '/a'), _entry('2', '/b')],
    );

    await engine.drainNow();

    expect(adapter.calls, ['/a']);
    expect((await outbox.pending()).length, 2);
  });

  group('SyncEngine.isTransientFailure', () {
    ApiException ex(ApiFailureKind kind, [int? code]) =>
        ApiException('x', kind, statusCode: code);

    test('retries network, server and session failures', () {
      expect(SyncEngine.isTransientFailure(ex(ApiFailureKind.network)), isTrue);
      expect(SyncEngine.isTransientFailure(ex(ApiFailureKind.server, 500)),
          isTrue);
      expect(
          SyncEngine.isTransientFailure(ex(ApiFailureKind.unauthorized, 401)),
          isTrue);
    });

    test('retries 408 / 429 and status-less unknown failures', () {
      expect(SyncEngine.isTransientFailure(ex(ApiFailureKind.unknown)), isTrue);
      expect(SyncEngine.isTransientFailure(ex(ApiFailureKind.unknown, 408)),
          isTrue);
      expect(SyncEngine.isTransientFailure(ex(ApiFailureKind.unknown, 429)),
          isTrue);
    });

    test('treats other 4xx and 403 as permanent rejections', () {
      expect(SyncEngine.isTransientFailure(ex(ApiFailureKind.forbidden, 403)),
          isFalse);
      for (final code in [400, 404, 409, 422]) {
        expect(SyncEngine.isTransientFailure(ex(ApiFailureKind.unknown, code)),
            isFalse,
            reason: 'status $code');
      }
    });
  });
}
