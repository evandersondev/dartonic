import 'package:dartonic_core/dartonic_core.dart';
import 'package:dartonic_sqlite/dartonic_sqlite.dart';

import '../database/tables.dart';

/// Opens the database connection. `sync: true` (the default) issues
/// `CREATE TABLE IF NOT EXISTS` for every table in [allSchemas], foreign keys
/// included. Uses in-memory SQLite so the example is dependency-free.
Future<DartonicDb> openDatabase() {
  return connectSqlite(':memory:', schemas: allSchemas);
}
