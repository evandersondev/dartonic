import 'package:dartonic_core/dartonic_core.dart';

import 'mysql_driver.dart';

/// Creates a [DartonicDb] connected to a MySQL database.
///
/// [uri] format: `mysql://user:password@host:port/database`
///
/// Example:
/// ```dart
/// import 'package:dartonic_mysql/dartonic_mysql.dart';
///
/// final db = await connectMysql(
///   'mysql://user:pass@localhost:3306/mydb',
///   schemas: [users, posts],
///   pool: const PoolConfig(max: 20),
/// );
/// await db.migrate();
/// ```
///
/// Pass [pool] to use an internal connection pool so concurrent requests
/// don't serialize on a single connection. Transactions still pin one
/// connection for their duration, and every pooled connection has
/// `ANSI_QUOTES` enabled.
Future<DartonicDb> connectMysql(
  String uri, {
  required List<Table> schemas,
  List<ViewSchema> views = const [],
  List<RelationsTable> relations = const [],
  bool sync = true,
  PoolConfig? pool,
}) async {
  validateTablesForDialect([...schemas, ...relations], Dialect.mysql);
  final driver = MysqlDriver(uri, poolConfig: pool);
  await driver.connect();
  final db = DartonicDb(
    driver: driver,
    schemas: schemas,
    dialect: Dialect.mysql,
    views: views,
    relations: relations,
  );
  if (sync) await db.sync();
  return db;
}
