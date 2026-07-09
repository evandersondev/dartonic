import 'dart:collection';

import 'package:dartonic_core/dartonic_core.dart' hide Database;
import 'package:sqlite3/sqlite3.dart';

/// SQLite driver using the `sqlite3` FFI package.
///
/// **Note**: the driver does not create parent directories for the database
/// file. On a CLI/server runtime, ensure the directory exists yourself; on
/// Flutter, resolve the path via `path_provider` and pass it in.
///
/// **Statement caching**: prepared statements are cached per connection keyed
/// by the SQL text (bounded LRU, see [statementCacheSize]). Repeated queries
/// with the same SQL reuse the compiled statement instead of re-preparing it.
/// DDL (`CREATE`/`ALTER`/`DROP`/`PRAGMA`) is never cached — it runs once and
/// caching it wastes a slot and risks holding stale schema handles.
class SqliteDriver implements DatabaseDriver {
  /// File path or `:memory:` (also accepts the legacy `sqlite::memory:` and
  /// `sqlite:<path>` prefixes).
  final String path;

  /// Maximum number of prepared statements to keep in the LRU cache.
  final int statementCacheSize;

  late Database _db;

  /// LRU cache of prepared statements keyed by SQL text. A [LinkedHashMap]
  /// preserves insertion/access order so we can evict the oldest entry.
  final LinkedHashMap<String, PreparedStatement> _stmtCache =
      LinkedHashMap<String, PreparedStatement>();

  SqliteDriver(this.path, {this.statementCacheSize = 128});

  @override
  Future<void> connect() async {
    final resolved = _resolvePath(path);
    if (resolved == ':memory:') {
      _db = sqlite3.openInMemory();
    } else {
      _db = sqlite3.open(resolved);
    }
    _db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Returns whether [sql] is safe to cache. DDL and PRAGMA statements are
  /// excluded — they run rarely and can invalidate schema-bound handles.
  static bool _isCacheable(String sql) {
    final head = sql.trimLeft();
    // Compare the leading keyword case-insensitively.
    for (final kw in const ['CREATE', 'ALTER', 'DROP', 'PRAGMA']) {
      if (head.length >= kw.length &&
          head.substring(0, kw.length).toUpperCase() == kw) {
        return false;
      }
    }
    return true;
  }

  /// Returns a prepared statement for [sql], reusing a cached one when
  /// possible. Non-cacheable SQL is prepared fresh and the caller must dispose
  /// it (signalled by the returned [_Prepared.owned] flag).
  _Prepared _prepareCached(String sql) {
    if (!_isCacheable(sql)) {
      return _Prepared(_db.prepare(sql), owned: true);
    }
    final existing = _stmtCache.remove(sql);
    if (existing != null) {
      // Re-insert to mark as most-recently-used.
      _stmtCache[sql] = existing;
      return _Prepared(existing, owned: false);
    }
    final stmt = _db.prepare(sql);
    _stmtCache[sql] = stmt;
    // Evict least-recently-used entries beyond the bound.
    while (_stmtCache.length > statementCacheSize) {
      final oldestKey = _stmtCache.keys.first;
      final evicted = _stmtCache.remove(oldestKey);
      evicted?.dispose();
    }
    return _Prepared(stmt, owned: false);
  }

  static String _resolvePath(String input) {
    if (input == ':memory:' || input == 'sqlite::memory:') return ':memory:';
    if (input.startsWith('sqlite:')) return input.substring('sqlite:'.length);
    return input;
  }

  @override
  Future<void> raw(String query, [List<Object?>? parameters]) async {
    final prepared = _prepareCached(query);
    try {
      final stmt = prepared.stmt;
      parameters == null ? stmt.execute() : stmt.execute(parameters);
    } catch (e) {
      _mapAndThrow(e);
    } finally {
      if (prepared.owned) prepared.stmt.dispose();
    }
  }

  @override
  Future<RawQueryResult> execute(String query,
      [List<Object?>? parameters]) async {
    final prepared = _prepareCached(query);
    try {
      final result = parameters == null
          ? prepared.stmt.select()
          : prepared.stmt.select(parameters);

      return result.map((row) {
        final nested = row.toTableColumnMap();
        if (nested == null) return Map<String, Object?>.from(row);
        final flat = <String, Object?>{};
        nested.forEach((_, cols) => flat.addAll(cols.cast<String, Object?>()));
        return flat;
      }).toList();
    } catch (e) {
      _mapAndThrow(e);
    } finally {
      if (prepared.owned) prepared.stmt.dispose();
    }
  }

  /// Translates a native [SqliteException] into a typed [DatabaseError].
  /// Constraint failures become [UniqueViolationError] / [ForeignKeyError] /
  /// [NotNullViolationError]; everything else becomes [ExecutionError].
  Never _mapAndThrow(Object e) {
    if (e is DatabaseError) throw e;
    if (e is SqliteException) {
      // Extended result codes: see https://sqlite.org/rescode.html
      switch (e.extendedResultCode) {
        case 2067: // SQLITE_CONSTRAINT_UNIQUE
        case 1555: // SQLITE_CONSTRAINT_PRIMARYKEY
          throw UniqueViolationError(e.message, e);
        case 787: // SQLITE_CONSTRAINT_FOREIGNKEY
          throw ForeignKeyError(e.message, e);
        case 1299: // SQLITE_CONSTRAINT_NOTNULL
          throw NotNullViolationError(e.message, e);
      }
    }
    throw ExecutionError('SQLite query failed', e);
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    final defs = columns.entries.map((e) => '"${e.key}" ${e.value}').toList();
    _db.execute('CREATE TABLE IF NOT EXISTS "$table" (${defs.join(', \n')})');
  }

  @override
  Future<void> beginTransaction() async => raw('BEGIN');

  @override
  Future<void> commitTransaction() async => raw('COMMIT');

  @override
  Future<void> rollbackTransaction() async => raw('ROLLBACK');

  @override
  Future<void> close() async {
    for (final stmt in _stmtCache.values) {
      stmt.dispose();
    }
    _stmtCache.clear();
    _db.dispose();
  }
}

/// A prepared statement handed back by [SqliteDriver._prepareCached].
///
/// [owned] is true when the statement is NOT in the cache and must be disposed
/// by the caller after use; false when it belongs to the cache and lives on.
class _Prepared {
  final PreparedStatement stmt;
  final bool owned;
  const _Prepared(this.stmt, {required this.owned});
}
