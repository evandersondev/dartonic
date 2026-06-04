/// SQLite driver plugin for Dartonic.
///
/// This package only exposes [connectSqlite]. Schema, query builder and types
/// live in `package:dartonic_core/dartonic_core.dart` — import that
/// alongside this driver:
///
/// ```dart
/// import 'package:dartonic_core/dartonic_core.dart';
/// import 'package:dartonic_sqlite/dartonic_sqlite.dart';
///
/// final db = await connectSqlite(':memory:', schemas: [users]);
/// ```
library;

export 'src/connect.dart';
