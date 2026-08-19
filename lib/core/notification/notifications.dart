import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single user-facing message, captured the moment it's shown so users can
/// revisit anything they missed. In-memory only — cleared on restart/sign-out.
class AppNotification {
  final String id;

  /// What the user was doing (e.g. "Add expense", "Sign in").
  final String action;

  /// The message that was shown.
  final String message;

  final bool isError;
  final DateTime at;
  final bool read;

  const AppNotification({
    required this.id,
    required this.action,
    required this.message,
    required this.isError,
    required this.at,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    action: action,
    message: message,
    isError: isError,
    at: at,
    read: read ?? this.read,
  );
}

class NotificationsController extends Notifier<List<AppNotification>> {
  static const _cap = 50;
  int _seq = 0;

  @override
  List<AppNotification> build() => const [];

  void add({
    required String action,
    required String message,
    required bool isError,
  }) {
    if (message.trim().isEmpty) return;
    final entry = AppNotification(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      action: action,
      message: message,
      isError: isError,
      at: DateTime.now(),
    );
    // Newest first, capped so it never grows without bound.
    final next = [entry, ...state];
    state = next.length > _cap ? next.sublist(0, _cap) : next;
  }

  void markAllRead() {
    if (state.every((n) => n.read)) return;
    state = [for (final n in state) n.copyWith(read: true)];
  }

  void clearAll() {
    if (state.isEmpty) return;
    state = const [];
  }
}

final notificationsProvider =
NotifierProvider<NotificationsController, List<AppNotification>>(
    NotificationsController.new);

/// Count of unread notifications, for the bell badge.
final unreadCountProvider = Provider<int>(
        (ref) => ref.watch(notificationsProvider).where((n) => !n.read).length);

/// Record a user-facing message into the notification center and, by default,
/// show it as a snackbar. Pass [showSnackbar] false when the message is already
/// visible inline (e.g. an error banner) so it isn't surfaced twice.
void notify(
    WidgetRef ref,
    BuildContext context, {
      required String action,
      required String message,
      bool isError = false,
      bool showSnackbar = true,
    }) {
  ref
      .read(notificationsProvider.notifier)
      .add(action: action, message: message, isError: isError);
  if (showSnackbar) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
