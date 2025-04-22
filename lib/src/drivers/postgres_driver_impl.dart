import 'package:postgres/postgres.dart';

import '../types/types.dart';
import 'driver.dart';

class PostgresDriverImpl extends DatabaseDriver {
  final String uri;
  final Map<String, TableSchema> _schemas;
  late Connection _connection;

  PostgresDriverImpl(this.uri, Map<String, TableSchema> schemas)
      : _schemas = schemas;

  @override
  Future<void> connect() async {
    final parsedUri = Uri.parse(uri);
    final username = parsedUri.userInfo.split(':').first;
    final password = parsedUri.userInfo.split(':').last;

    final endpoint = Endpoint(
      host: parsedUri.host,
      database: parsedUri.path.substring(1),
      username: username,
      password: password,
    );

    final conn = await Connection.open(
      endpoint,
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    _connection = conn;
  }

  @override
  Future<void> raw(String query, [List<dynamic>? parameters]) async {
    if (parameters == null) {
      _connection.execute(query);
    } else {
      String sqlRaw = query;

      for (var i = 1; i <= parameters.length; i++) {
        sqlRaw = sqlRaw.replaceFirst('?', '\$$i');
      }

      await _connection.execute(sqlRaw, parameters: parameters);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> execute(String query,
      [List<dynamic>? parameters]) async {
    Result result;

    if (parameters == null) {
      result = await _connection.execute(query);
    } else {
      String sqlRaw = query;

      for (var i = 1; i <= parameters.length; i++) {
        sqlRaw = sqlRaw.replaceFirst('?', '\$$i');
      }

      result = await _connection.execute(sqlRaw, parameters: parameters);
    }

    final rows = result.map((row) => row.toColumnMap()).toList();
    return rows;
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    try {
      final schema = _schemas[table];
      final columnDefinitions = columns.entries
          .map((e) =>
              "${e.key} ${e.value.replaceAll('AUTOINCREMENT', 'AUTO_INCREMENT')}")
          .toList();

      if (schema?.foreignKeys != null && schema!.foreignKeys.isNotEmpty) {
        columnDefinitions.addAll(
          schema.foreignKeys.map((fk) => fk.toSql()),
        );
      }

      final sql =
          "CREATE TABLE IF NOT EXISTS $table (${columnDefinitions.join(', ')})";
      await _connection.execute(sql);
    } catch (e) {
      rethrow;
    }
  }
}
