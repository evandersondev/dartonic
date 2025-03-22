import 'driver.dart';

class PostgresDriverImpl extends DatabaseDriver {
  @override
  Future<void> connect() async {}

  @override
  Future<void> raw(String query, [List<dynamic>? parameters]) async {}

  @override
  Future<List<Map<String, dynamic>>> execute(String query,
      [List<dynamic>? parameters]) async {
    return [];
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    final cols = columns.entries.map((e) => "${e.key} ${e.value}").join(", ");
    final sql = "CREATE TABLE IF NOT EXISTS $table ($cols);";
    await raw(sql);
  }
}
