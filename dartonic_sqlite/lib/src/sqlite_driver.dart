import 'package:dartonic_core/dartonic_core.dart' hide Database;
import 'package:sqlite3/sqlite3.dart';

/// SQLite driver using the `sqlite3` FFI package.
///
/// **Note**: the driver does not create parent directories for the database
/// file. On a CLI/server runtime, ensure the directory exists yourself; on
/// Flutter, resolve the path via `path_provider` and pass it in.
class SqliteDriver implements DatabaseDriver {
  /// File path or `:memory:` (also accepts the legacy `sqlite::memory:` and
  /// `sqlite:<path>` prefixes).
  final String path;
  late Database _db;

  SqliteDriver(this.path);

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

  static String _resolvePath(String input) {
    if (input == ':memory:' || input == 'sqlite::memory:') return ':memory:';
    if (input.startsWith('sqlite:')) return input.substring('sqlite:'.length);
    return input;
  }

  @override
  Future<void> raw(String query, [List<Object?>? parameters]) async {
    try {
      final stmt = _db.prepare(query);
      try {
        parameters == null ? stmt.execute() : stmt.execute(parameters);
      } finally {
        stmt.dispose();
      }
    } catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<RawQueryResult> execute(String query,
      [List<Object?>? parameters]) async {
    try {
      final result = parameters == null
          ? _db.select(query)
          : _db.select(query, parameters);

      return result.map((row) {
        final nested = row.toTableColumnMap();
        if (nested == null) return Map<String, Object?>.from(row);
        final flat = <String, Object?>{};
        nested.forEach((_, cols) => flat.addAll(cols.cast<String, Object?>()));
        return flat;
      }).toList();
    } catch (e) {
      _mapAndThrow(e);
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
  Future<void> close() async => _db.dispose();
}
