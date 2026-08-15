import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Well-known cache keys for reference data that barely changes.
class ReferenceCacheKeys {
  static const classes = 'classes';
  static const terms = 'terms';
}

/// How long cached reference data is considered fresh. Classes and terms change
/// rarely (roughly once a term/year), so a long TTL keeps launches fast and
/// offline-friendly while still picking up admin changes within a day. Adjust
/// here if you want faster propagation.
const Duration kReferenceCacheTtl = Duration(hours: 12);

/// One cached payload plus when it was written.
class CacheEnvelope {
  final int cachedAtMs;
  final List<dynamic> data;
  const CacheEnvelope({required this.cachedAtMs, required this.data});

  bool isFresh(Duration ttl) =>
      DateTime.now().millisecondsSinceEpoch - cachedAtMs < ttl.inMilliseconds;
}

/// A tiny durable cache for reference lists, stored as JSON files in the app
/// support directory so it survives restarts. Best-effort: any IO error is
/// swallowed and treated as "no cache" rather than surfacing to the UI.
class ReferenceCache {
  Directory? _dirCache;

  Future<Directory> _dir() async {
    if (_dirCache != null) return _dirCache!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'reference_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _dirCache = dir;
  }

  Future<File> _fileFor(String key) async =>
      File(p.join((await _dir()).path, '$key.json'));

  /// Read a cached envelope for [key], or null if absent/unreadable.
  Future<CacheEnvelope?> read(String key) async {
    try {
      final f = await _fileFor(key);
      if (!await f.exists()) return null;
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map) return null;
      final data = decoded['data'];
      if (data is! List) return null;
      final cachedAt = (decoded['cachedAt'] as num?)?.toInt() ?? 0;
      return CacheEnvelope(cachedAtMs: cachedAt, data: data);
    } catch (_) {
      return null;
    }
  }

  /// Write [data] (a JSON-encodable list) under [key], stamped with now.
  Future<void> write(String key, List<dynamic> data) async {
    try {
      final f = await _fileFor(key);
      await f.writeAsString(jsonEncode({
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }));
    } catch (_) {
      // Best-effort; a failed cache write must never break the flow.
    }
  }

  /// Drop a single cached entry (call after a mutation or a manual refresh so
  /// the next read goes to the network).
  Future<void> bust(String key) async {
    try {
      final f = await _fileFor(key);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Drop everything (e.g. on sign-out if you want a clean slate).
  Future<void> clearAll() async {
    try {
      final dir = await _dir();
      if (await dir.exists()) await dir.delete(recursive: true);
      _dirCache = null;
    } catch (_) {}
  }
}

final referenceCacheProvider = Provider<ReferenceCache>((ref) => ReferenceCache());

/// Read-through cache with a TTL and network-awareness:
///  - fresh cache (within [ttl]) → served immediately, no network,
///  - stale/missing + online → fetch, refresh the cache, return fresh,
///  - stale/missing + offline → serve stale if present (else fetch attempt),
///  - fetch fails but stale exists → fall back to stale rather than error.
Future<List<T>> readThroughCache<T>({
  required ReferenceCache cache,
  required bool isOnline,
  required String key,
  required Duration ttl,
  required Future<List<T>> Function() fetch,
  required T Function(Map<String, dynamic>) fromJson,
  required Map<String, dynamic> Function(T) toJson,
}) async {
  final env = await cache.read(key);

  List<T> decode(CacheEnvelope e) => e.data
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList();

  // Fresh cache short-circuits everything.
  if (env != null && env.isFresh(ttl)) return decode(env);

  // Stale or missing. Offline → best we can do is serve stale.
  if (!isOnline && env != null) return decode(env);

  try {
    final fresh = await fetch();
    await cache.write(key, fresh.map(toJson).toList());
    return fresh;
  } catch (_) {
    // Network fetch failed — fall back to stale cache if we have it.
    if (env != null) return decode(env);
    rethrow;
  }
}
