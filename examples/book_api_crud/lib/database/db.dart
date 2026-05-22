import 'package:dartonic_core/dartonic_core.dart';
import 'package:dartonic_sqlite/dartonic_sqlite.dart';

import 'schemas.dart';

/// Shared database handle. Initialized once via [initDatabase] in `main()`,
/// then imported and used directly from anywhere in the app.
late final DartonicDb db;

/// Opens the single shared connection. Call exactly once at startup.
Future<void> initDatabase() async {
  db = await connectSqlite(':memory:', schemas: [books]);
}
