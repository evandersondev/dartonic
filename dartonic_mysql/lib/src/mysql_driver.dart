import 'package:dartonic_core/dartonic_core.dart';
import 'package:mysql1/mysql1.dart' as mysql;

class MysqlDriver implements DatabaseDriver {
  final String uri;
  late mysql.MySqlConnection _conn;

  MysqlDriver(this.uri);

  @override
  Future<void> connect() async {
    try {
      final parsed = Uri.parse(uri);
      final parts = parsed.userInfo.split(':');
      _conn = await mysql.MySqlConnection.connect(mysql.ConnectionSettings(
        host: parsed.host,
        port: parsed.port,
        user: parts.first,
        password: parts.length > 1 ? parts.last : null,
        db: parsed.path.substring(1),
      ));
      // Dartonic's query builder quotes identifiers with double quotes
      // (`"table"."column"`), which MySQL only accepts in ANSI_QUOTES mode.
      // Enable it for the session (appended so STRICT/other modes survive).
      await _conn.query(
          "SET SESSION sql_mode = CONCAT(@@SESSION.sql_mode, ',ANSI_QUOTES')");
    } catch (e) {
      throw ConnectionError('Failed to connect to MySQL', e);
    }
  }

  @override
  Future<void> raw(String query, [List<Object?>? parameters]) async {
    try {
      parameters == null
          ? await _conn.query(query)
          : await _conn.query(query, parameters);
    } catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<RawQueryResult> execute(String query,
      [List<Object?>? parameters]) async {
    try {
      final result = parameters == null
          ? await _conn.query(query)
          : await _conn.query(query, parameters);
      return result
          .map((row) => Map<String, Object?>.from(row.fields))
          .toList();
    } catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    final defs = columns.entries
        .map((e) =>
            '`${e.key}` ${e.value.replaceAll('AUTOINCREMENT', 'AUTO_INCREMENT').replaceAll('AUTOGENERATE', '')}')
        .join(', ');
    await _conn.query('CREATE TABLE IF NOT EXISTS `$table` ($defs)');
  }

  @override
  Future<void> beginTransaction() => raw('BEGIN');

  @override
  Future<void> commitTransaction() => raw('COMMIT');

  @override
  Future<void> rollbackTransaction() => raw('ROLLBACK');

  @override
  Future<void> close() => _conn.close();

  /// Translates a native [mysql.MySqlException] into a typed [DatabaseError]
  /// using the MySQL error number; non-constraint errors become
  /// [ExecutionError].
  Never _mapAndThrow(Object e) {
    if (e is DatabaseError) throw e;
    if (e is mysql.MySqlException) {
      switch (e.errorNumber) {
        case 1062: // ER_DUP_ENTRY
          throw UniqueViolationError(e.message, e);
        case 1452: // ER_NO_REFERENCED_ROW_2
          throw ForeignKeyError(e.message, e);
        case 1048: // ER_BAD_NULL_ERROR
          throw NotNullViolationError(e.message, e);
      }
    }
    throw ExecutionError('MySQL query failed', e);
  }
}
