import 'dart:async';

import '../api/api_client.dart';
import 'connectivity_service.dart';
import 'outbox.dart';

/// What the drain engine is currently doing.
enum SyncPhase { idle, syncing, error }

/// A snapshot of sync state for the UI.
class SyncState {
  final SyncPhase phase;
  final int pending;
  final DateTime? lastSyncedAt;
  final String? lastError;

  const SyncState({
    required this.phase,
    required this.pending,
    this.lastSyncedAt,
    this.lastError,
  });

  const SyncState.initial()
      : phase = SyncPhase.idle,
        pending = 0,
        lastSyncedAt = null,
        lastError = null;

  SyncState copyWith({
    SyncPhase? phase,
    int? pending,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearError = false,
  }) =>
      SyncState(
        phase: phase ?? this.phase,
        pending: pending ?? this.pending,
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
  Future<void> drainNow() async {
    if (_draining) return;
    final entries = await _outbox.pending();
    if (entries.isEmpty) {
      _update(_state.copyWith(phase: SyncPhase.idle, clearError: true));
      return;
    }

    _draining = true;
    _update(_state.copyWith(phase: SyncPhase.syncing, clearError: true));

    var hadError = false;
    String? firstError;

    for (final entry in entries) {
      try {
        await _replay(entry);
        await _outbox.remove(entry.id);
      } on ApiException catch (e) {
        // Stop on the first failure so we don't hammer a down server; the
        // remaining entries stay queued for the next attempt.
        hadError = true;
        firstError = e.message;
        break;
      } catch (e) {
        hadError = true;
        firstError = 'Unexpected error while syncing.';
        break;
      }
    }

    _draining = false;

    if (hadError) {
      _update(_state.copyWith(
        phase: SyncPhase.error,
        pending: _outbox.pendingCount,
        lastError: firstError,
      ));
    } else {
      _update(_state.copyWith(
        phase: SyncPhase.idle,
        pending: _outbox.pendingCount,
        lastSyncedAt: DateTime.now(),
        clearError: true,
      ));
    }
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
