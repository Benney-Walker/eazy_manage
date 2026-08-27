import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime at;
  final LogLevel level;
  final String category;
  final String message;
  final String? detail;

  const LogEntry({
    required this.at,
    required this.level,
    required this.category,
    required this.message,
    this.detail,
  });
}

/// Client-side activity log. Records app activity (API calls, navigation, auth,
/// sync, errors) to an in-memory ring buffer and a rotating file on disk, for
/// later diagnostics. Metadata only — never request/response bodies, passwords,
/// or tokens. This is not shown to end users; it exists so issues can be
/// investigated from the log file (a future update may offer to share it).
///
/// Logging must never throw or block the UI: every I/O path is guarded and
/// file writes are serialised on a background Future chain.
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  static const int _maxMemEntries = 800;
  static const int _maxFileBytes = 1024 * 1024; // 1 MB, then rotate once.

  /// Minimum level to record. Bump to [LogLevel.debug] when investigating.
  LogLevel minLevel = LogLevel.info;

  final List<LogEntry> _buffer = [];
  final List<String> _pending = []; // lines logged before the file is ready
  File? _file;
  bool _ready = false;
  Future<void> _writes = Future<void>.value();

  Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logDir = Directory('${dir.path}${Platform.pathSeparator}logs');
      if (!await logDir.exists()) await logDir.create(recursive: true);
      _file = File('${logDir.path}${Platform.pathSeparator}activity.log');
      _ready = true;
      if (_pending.isNotEmpty) {
        final backlog = _pending.join();
        _pending.clear();
        _enqueue(backlog);
      }
      log(LogLevel.info, 'app', 'Logger ready');
    } catch (_) {
      // Never let logging setup break app startup.
    }
  }

  void log(LogLevel level, String category, String message, [String? detail]) {
    if (level.index < minLevel.index) return;
    final entry = LogEntry(
      at: DateTime.now(),
      level: level,
      category: category,
      message: message,
      detail: detail,
    );
    _buffer.add(entry);
    if (_buffer.length > _maxMemEntries) {
      _buffer.removeRange(0, _buffer.length - _maxMemEntries);
    }
    final line = _format(entry);
    if (_ready) {
      _enqueue(line);
    } else {
      _pending.add(line);
      if (_pending.length > _maxMemEntries) {
        _pending.removeRange(0, _pending.length - _maxMemEntries);
      }
    }
  }

  void _enqueue(String data) {
    _writes = _writes.then((_) async {
      try {
        var f = _file;
        if (f == null) return;
        if (await f.exists() && await f.length() > _maxFileBytes) {
          final prev = File('${f.path}.1');
          if (await prev.exists()) await prev.delete();
          await f.rename(prev.path);
          f = File(f.path); // fresh handle at the original path
          _file = f;
        }
        await f.writeAsString(data, mode: FileMode.append, flush: false);
      } catch (_) {
        // Swallow — a failed write must not surface anywhere.
      }
    });
  }

  String _format(LogEntry e) {
    final ts = e.at.toIso8601String();
    final lvl = e.level.name.toUpperCase().padRight(5);
    final base = '$ts  $lvl  [${e.category}]  ${e.message}';
    return e.detail == null ? '$base\n' : '$base  |  ${e.detail}\n';
  }

  /// In-memory snapshot (newest last). Not shown to users yet, but handy for a
  /// future in-app viewer / share-with-developer opt-in.
  List<LogEntry> get entries => List.unmodifiable(_buffer);

  /// Absolute path to the current log file, once [init] has run.
  String? get filePath => _file?.path;
}

/// Terse global helpers. Categories are free-form strings; the app uses
/// 'app', 'api', 'nav', 'auth', 'sync', 'error'.
class AppLog {
  const AppLog._();
  static void d(String category, String message, [String? detail]) =>
      AppLogger.instance.log(LogLevel.debug, category, message, detail);
  static void i(String category, String message, [String? detail]) =>
      AppLogger.instance.log(LogLevel.info, category, message, detail);
  static void w(String category, String message, [String? detail]) =>
      AppLogger.instance.log(LogLevel.warning, category, message, detail);
  static void e(String category, String message, [String? detail]) =>
      AppLogger.instance.log(LogLevel.error, category, message, detail);
}