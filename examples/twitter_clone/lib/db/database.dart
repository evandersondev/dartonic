import 'package:dartonic_core/dartonic_core.dart';
import 'package:dartonic_sqlite/dartonic_sqlite.dart';

import 'schema.dart';

/// Opens an in-memory SQLite database with the app schema.
///
/// Use a file path (e.g. `'twitter.db'`) to persist data across runs.
Future<DartonicDb> openDatabase({String path = ':memory:'}) =>
    connectSqlite(path, schemas: [users, posts]);
