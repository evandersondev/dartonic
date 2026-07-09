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
///   pool: const PoolConfig(max: 20),
/// );
/// await db.migrate();
/// ```
///
/// Pass [pool] to run queries through a connection pool so concurrent
/// requests don't serialize on a single socket. Transactions still pin one
/// connection for their duration.
Future<DartonicDb> connectPostgres(
  String uri, {
  required List<Table> schemas,
  List<ViewSchema> views = const [],
  List<RelationsTable> relations = const [],
  bool sync = true,
  PoolConfig? pool,
}) async {
  validateTablesForDialect([...schemas, ...relations], Dialect.postgres);
  final driver = PostgresDriver(uri, poolConfig: pool);
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
