import 'package:dartonic_core/dartonic_core.dart';
import 'package:postgres/postgres.dart';

class PostgresDriver implements DatabaseDriver {
  final String uri;
  late Connection _conn;

  PostgresDriver(this.uri);

  @override
  Future<void> connect() async {
    try {
      final parsed = Uri.parse(uri);
      final parts = parsed.userInfo.split(':');
      final endpoint = Endpoint(
        host: parsed.host,
        port: parsed.port,
        database: parsed.path.substring(1),
        username: parts.first,
        password: parts.length > 1 ? parts.last : null,
      );
      _conn = await Connection.open(
        endpoint,
        settings: ConnectionSettings(
          sslMode: switch (parsed.queryParameters['sslmode']) {
            'require' => SslMode.require,
            'verify-full' => SslMode.verifyFull,
            _ => SslMode.disable,
          },
        ),
      );
    } catch (e) {
      throw ConnectionError('Failed to connect to PostgreSQL', e);
    }
  }

  @override
  Future<void> raw(String query, [List<Object?>? parameters]) async {
    try {
      if (parameters == null) {
        await _conn.execute(query);
      } else {
        await _conn.execute(_toPositional(query, parameters),
            parameters: parameters);
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
          ? await _conn.execute(query)
          : await _conn.execute(_toPositional(query, parameters),
              parameters: parameters);
      return result.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    final defs = columns.entries
        .map((e) =>
            '"${e.key}" ${e.value.replaceAll('AUTOINCREMENT', '').replaceAll('AUTOGENERATE', '')}')
        .join(', ');
    await _conn.execute('CREATE TABLE IF NOT EXISTS "$table" ($defs)');
  }

  @override
  Future<void> beginTransaction() => raw('BEGIN');

  @override
  Future<void> commitTransaction() => raw('COMMIT');

  @override
  Future<void> rollbackTransaction() => raw('ROLLBACK');

  @override
  Future<void> close() => _conn.close();

  String _toPositional(String sql, List<Object?> params) {
    var i = 0;
    return sql.replaceAllMapped(RegExp(r'\?'), (_) => '\$${++i}');
  }

  /// Translates a native [ServerException] into a typed [DatabaseError] using
  /// the SQLSTATE code; non-constraint errors become [ExecutionError].
  Never _mapAndThrow(Object e) {
    if (e is DatabaseError) throw e;
    if (e is ServerException) {
      switch (e.code) {
        case '23505': // unique_violation
          throw UniqueViolationError(e.message, e);
        case '23503': // foreign_key_violation
          throw ForeignKeyError(e.message, e);
        case '23502': // not_null_violation
          throw NotNullViolationError(e.message, e);
      }
    }
    throw ExecutionError('PostgreSQL query failed', e);
  }
}
