import 'package:dartonic_core/dartonic_core.dart';

import 'sqlite_driver.dart';

/// Creates a [DartonicDb] connected to a SQLite database.
///
/// [path] may be `:memory:` for an in-memory DB or a real filesystem path.
/// On Flutter, resolve the path with `path_provider` first; the driver does
/// not create parent directories. Add `sqlite3_flutter_libs` to your Flutter
/// app's pubspec to bundle the native binaries.
///
/// ```dart
/// final db = await connectSqlite(
///   ':memory:',
///   schemas: [Users(), Posts()],
/// );
/// ```
Future<DartonicDb> connectSqlite(
  String path, {
  required List<Table> schemas,
  List<ViewSchema> views = const [],
  List<RelationsTable> relations = const [],
  bool sync = true,
}) async {
  validateTablesForDialect([...schemas, ...relations], Dialect.sqlite);
  final driver = SqliteDriver(path);
  await driver.connect();
  final db = DartonicDb(
    driver: driver,
    schemas: schemas,
    dialect: Dialect.sqlite,
    views: views,
    relations: relations,
  );
  if (sync) await db.sync();
  return db;
}
