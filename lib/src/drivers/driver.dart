import '../types/table.dart';
import 'mysql_driver_impl.dart';
import 'postgres_driver_impl.dart';
import 'sqlite_driver_impl.dart';

abstract class DatabaseDriver {
  Future<void> connect();
  Future<void> raw(
    String query, [
    List<dynamic>? parameters,
  ]);
  Future<List<Map<String, dynamic>>> execute(
    String query, [
    List<dynamic>? parameters,
  ]);
  Future<void> createTable(
    String table,
    Map<String, String> columns,
  );
  Future<void> beginTransaction();
  Future<void> commitTransaction();
  Future<void> rollbackTransaction();
}

class SqlDriverFactory {
  static Future<DatabaseDriver> getDriver(
      String uri, final Map<String, TableSchema> schemas) async {
    if (uri.startsWith('sqlite')) {
      final driver = SqliteDriverImpl(uri, schemas);
      await driver.connect();

      return driver;
    } else if (uri.startsWith('mysql')) {
      final driver = MysqlDriverImpl(uri, schemas);
      await driver.connect();

      return driver;
    } else if (uri.startsWith('postgres')) {
      final driver = PostgresDriverImpl(uri, schemas);
      await driver.connect();

      return driver;
    }

    throw Exception("Driver don't support");
  }
}
