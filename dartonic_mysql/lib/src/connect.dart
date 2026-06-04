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
/// );
/// await db.migrate();
/// ```
Future<DartonicDb> connectMysql(
  String uri, {
  required List<Table> schemas,
  List<ViewSchema> views = const [],
  List<RelationsTable> relations = const [],
  bool sync = true,
}) async {
  validateTablesForDialect([...schemas, ...relations], Dialect.mysql);
  final driver = MysqlDriver(uri);
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
