import 'package:dartonic_core/dartonic_core.dart';

import 'postgres_driver.dart';

/// Creates a [DartonicDb] connected to a PostgreSQL database.
///
/// [uri] format: `postgres://user:password@host:port/database?sslmode=require`
///
/// Example:
/// ```dart
/// import 'package:dartonic_postgres/dartonic_postgres.dart';
///
/// final db = await connectPostgres(
///   'postgres://user:pass@localhost:5432/mydb',
///   schemas: [users, posts],
/// );
/// await db.migrate();
/// ```
Future<DartonicDb> connectPostgres(
  String uri, {
  required List<Table> schemas,
  List<ViewSchema> views = const [],
  List<RelationsTable> relations = const [],
  bool sync = true,
}) async {
  validateTablesForDialect([...schemas, ...relations], Dialect.postgres);
  final driver = PostgresDriver(uri);
  await driver.connect();
  final db = DartonicDb(
    driver: driver,
    schemas: schemas,
    dialect: Dialect.postgres,
    views: views,
    relations: relations,
  );
  if (sync) await db.sync();
  return db;
}
