import 'dart:async';

import '../api/api_client.dart';
import '../logging/app_logger.dart';
import 'connectivity_service.dart';
import 'outbox.dart';

/// What the drain engine is currently doing.
enum SyncPhase { idle, syncing, error }

/// A snapshot of sync state for the UI.
class SyncState {
  final SyncPhase phase;
  final int pending;

  /// Entries the server rejected outright (4xx) on the last drain. They stay
  /// queued — nothing is dropped silently — but no longer block later writes.
  final int rejected;
  final DateTime? lastSyncedAt;
  final String? lastError;

  const SyncState({
    required this.phase,
    required this.pending,
    this.rejected = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  const SyncState.initial()
      : phase = SyncPhase.idle,
        pending = 0,
        rejected = 0,
        lastSyncedAt = null,
        lastError = null;

  SyncState copyWith({
    SyncPhase? phase,
    int? pending,
    int? rejected,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearError = false,
  }) =>
      SyncState(
        phase: phase ?? this.phase,
        pending: pending ?? this.pending,
        rejected: rejected ?? this.rejected,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}

/// Drains the [Outbox] against the API. Draining happens:
///  - automatically when connectivity transitions to online, and
///  - manually via [drainNow] (the "Sync now" button in Settings).
///
/// The engine reports progress through an [onState] stream so the UI can show
/// syncing / pending count / last error without owning any of this logic.
class SyncEngine {
  final ApiClient _api;
  final Outbox _outbox;

  final _stateController = StreamController<SyncState>.broadcast();
  SyncState _state = const SyncState.initial();

  bool _draining = false;

  SyncEngine(this._api, this._outbox) {
    _state = _state.copyWith(pending: _outbox.pendingCount);
    // Keep the pending count fresh as repositories enqueue writes.
    _outbox.pendingCountStream.listen((count) {
      _update(_state.copyWith(pending: count));
    });
  }

  Stream<SyncState> get onState => _stateController.stream;
  SyncState get state => _state;

  /// Called by the connectivity binding when the network status changes.
  void onNetworkStatus(NetworkStatus status) {
    if (status == NetworkStatus.online) {
      // Fire-and-forget; draining guards against re-entry.
      drainNow();
    }
  }

  /// Attempt to send every queued write. Safe to call repeatedly and while a
  /// drain is already in progress (the second call is ignored).
  ///
  /// Failures are split in two:
  ///  - transient (offline, timeout, 5xx, session/refresh trouble): stop the
  ///    drain so we don't hammer a down server; everything stays queued.
  ///  - permanent (the server answered 4xx — validation, conflict, forbidden,
  ///    not found): keep the entry queued so nothing is lost silently, record
  ///    it as rejected, and carry on with the rest. One bad record must not
  ///    block every payment queued after it.
  Future<void> drainNow() async {
    if (_draining) return;
    final entries = await _outbox.pending();
    if (entries.isEmpty) {
      _update(_state.copyWith(
          phase: SyncPhase.idle, rejected: 0, clearError: true));
      return;
    }

    _draining = true;
    _update(_state.copyWith(phase: SyncPhase.syncing, clearError: true));

    var stopped = false;
    var rejected = 0;
    String? firstError;

    try {
      for (final entry in entries) {
        try {
          await _replay(entry);
          await _outbox.remove(entry.id);
        } on ApiException catch (e) {
          if (isTransientFailure(e)) {
            stopped = true;
            firstError ??= e.message;
            AppLog.w('sync', 'Sync paused at "${entry.description}"', e.message);
            break;
          }
          rejected++;
          firstError ??= '${entry.description}: ${e.message}';
          AppLog.w('sync', 'Server rejected "${entry.description}" '
              '(${e.statusCode ?? e.kind.name}) — kept in queue', e.message);
        } catch (e) {
          stopped = true;
          firstError ??= 'Unexpected error while syncing.';
          AppLog.e('sync', 'Unexpected error at "${entry.description}"',
              e.toString());
          break;
        }
      }
    } finally {
      _draining = false;
    }

    final pending = (await _outbox.pending()).length;

    if (stopped || rejected > 0) {
      _update(_state.copyWith(
        phase: SyncPhase.error,
        pending: pending,
        rejected: rejected,
        lastError: rejected > 0 && !stopped
            ? '$rejected change(s) were rejected by the server and remain '
                'queued. First: $firstError'
            : firstError,
      ));
    } else {
      _update(_state.copyWith(
        phase: SyncPhase.idle,
        pending: pending,
        rejected: 0,
        lastSyncedAt: DateTime.now(),
        clearError: true,
      ));
    }
  }

  /// Whether [e] is worth retrying later (as opposed to a permanent rejection
  /// of this particular request).
  static bool isTransientFailure(ApiException e) {
    final code = e.statusCode;
    return switch (e.kind) {
      ApiFailureKind.network ||
      ApiFailureKind.server ||
      ApiFailureKind.unauthorized =>
        true,
      ApiFailureKind.forbidden => false,
      // No status = transport-level oddity; 408/429 = try again later;
      // any other 4xx is a permanent rejection of this request.
      ApiFailureKind.unknown =>
        code == null || code == 408 || code == 429 || code < 400 || code >= 500,
    };
  }

  Future<void> _replay(OutboxEntry entry) async {
    switch (entry.method) {
      case OutboxMethod.post:
        await _api.post(entry.path, body: entry.body);
      case OutboxMethod.put:
        await _api.put(entry.path, body: entry.body);
      case OutboxMethod.delete:
        await _api.delete(entry.path);
    }
  }

  void _update(SyncState next) {
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  void dispose() => _stateController.close();
}
