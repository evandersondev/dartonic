import 'package:mysql1/mysql1.dart' as mysql;

import 'driver.dart';

class MysqlDriverImpl extends DatabaseDriver {
  final String uri;
  late mysql.MySqlConnection _connection;

  MysqlDriverImpl(this.uri);

  @override
  Future<void> connect() async {
    final parsedUri = Uri.parse(uri);
    final username = parsedUri.userInfo.split(':').first;
    final password = parsedUri.userInfo.split(':').last;

    final settings = mysql.ConnectionSettings(
      host: parsedUri.host,
      port: parsedUri.port,
      user: username,
      password: password,
      db: parsedUri.path.substring(1),
    );

    _connection = await mysql.MySqlConnection.connect(settings);
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Future<dynamic> raw(String query, [List<dynamic>? parameters]) async {
    if (parameters == null) {
      return _connection.query(query);
    } else {
      return _connection.query(query, parameters);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> execute(String query,
      [List<dynamic>? parameters]) async {
    final result = parameters == null
        ? await _connection.query(query)
        : await _connection.query(query, parameters);
    final rows = result.map((row) => row.fields).toList();
    return rows;
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    final cols = columns.entries
        .map((e) =>
            "${e.key} ${e.value.replaceAll('AUTOINCREMENT', 'AUTO_INCREMENT')}")
        .join(", ");
    final sql = "CREATE TABLE IF NOT EXISTS $table ($cols);";
    await _connection.query(sql);
  }
}
