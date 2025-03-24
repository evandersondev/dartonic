import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'driver.dart';

class SqliteDriverImpl extends DatabaseDriver {
  final String uri;
  late Database _connection;

  SqliteDriverImpl(this.uri);

  @override
  Future<void> connect() async {
    if (uri == 'sqlite::memory:') {
      _connection = sqlite3.openInMemory();
    } else if (uri.startsWith("sqlite:")) {
      // Remove o prefixo "sqlite:" para obter o caminho do arquivo
      final filePath = uri.replaceFirst("sqlite:", "");
      // Se o caminho for relativo, cria o diretório pai, se necessário.
      final file = File(filePath);
      final directory = file.parent;
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      _connection = sqlite3.open(filePath);
    } else {
      throw Exception("Unsupported URI scheme");
    }
  }

  @override
  Future<dynamic> raw(String query, [List<dynamic>? parameters]) async {
    final stmt = _connection.prepare(query);

    if (parameters == null) {
      return stmt.execute();
    } else {
      return stmt.execute(parameters);
    }
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    final cols = columns.entries.map((e) => "${e.key} ${e.value}").join(", ");
    final sql = "CREATE TABLE IF NOT EXISTS $table ($cols);";
    _connection.execute(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> execute(String query,
      [List? parameters]) async {
    final result = parameters == null
        ? _connection.select(query)
        : _connection.select(query, parameters);

    final rows = result.map((row) {
      final nestedMap = row.toTableColumnMap();
      final flattened = <String, dynamic>{};
      nestedMap?.forEach((_, colMap) {
        flattened.addAll(colMap);
      });
      return flattened;
    }).toList();

    return Future.value(rows);
  }
}
