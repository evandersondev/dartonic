import 'mysql_driver_impl.dart';
import 'postgres_driver_impl.dart';
import 'sqlite_driver_impl.dart';

abstract class DatabaseDriver {
  Future<void> connect();
  Future<void> raw(String query, [List<dynamic>? parameters]);
  Future<List<Map<String, dynamic>>> execute(String query,
      [List<dynamic>? parameters]);
  Future<void> createTable(String table, Map<String, String> columns);
}

class SqlDriverFactory {
  static Future<DatabaseDriver> getDriver(String uri) async {
    if (uri.startsWith('sqlite')) {
      final driver = SqliteDriverImpl(uri);
      await driver.connect();
      return driver;
    } else if (uri.startsWith('mysql')) {
      final driver = MysqlDriverImpl(uri);
      await driver.connect();
      return driver;
    } else if (uri.startsWith('postgres')) {
      final driver = PostgresDriverImpl();
      await driver.connect();
      return driver;
    }
    throw Exception('Driver não suportado!');
  }
}
