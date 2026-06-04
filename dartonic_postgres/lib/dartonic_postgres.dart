/// PostgreSQL driver plugin for Dartonic.
///
/// This package only exposes [connectPostgres]. Schema, query builder and
/// types live in `package:dartonic_core/dartonic_core.dart` — import that
/// alongside this driver:
///
/// ```dart
/// import 'package:dartonic_core/dartonic_core.dart';
/// import 'package:dartonic_postgres/dartonic_postgres.dart';
///
/// final db = await connectPostgres('postgres://…', schemas: [users]);
/// ```
library;

export 'src/connect.dart';
