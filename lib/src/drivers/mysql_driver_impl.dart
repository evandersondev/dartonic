import 'package:mysql1/mysql1.dart' as mysql;

import 'driver.dart';

class MysqlDriverImpl extends DatabaseDriver {
  final String uri;
  late mysql.MySqlConnection _connection;

  MysqlDriverImpl(this.uri);

  @override
  Future<void> connect() async {
    final uri = Uri.parse(this.uri);
    final username = uri.userInfo.split(':').first;
    final password = uri.userInfo.split(':').last;

    final settings = mysql.ConnectionSettings(
      host: uri.host,
      port: uri.port,
      user: username,
      password: password,
      db: uri.path.substring(1),
    );

    _connection = await mysql.MySqlConnection.connect(settings);
  }

  @override
  Future<dynamic> raw(String query, [List<dynamic>? parameters]) async {
    if (parameters == null) {
      return await _connection.query(query);
    } else {
      print('$query, $parameters');
      await _connection.query(
          'INSERT INTO users (username, email) VALUES (?, ?)',
          ["john", "john@mail.com"]);
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
    final cols = columns.entries.map((e) {
      return "${e.key} ${e.value.replaceAll('AUTOINCREMENT', 'AUTO_INCREMENT')}";
    }).join(", ");
    final sql = "CREATE TABLE IF NOT EXISTS $table ($cols);";
    print(sql);
    await _connection.query(sql);
  }
}
