import 'package:dartonic_core/dartonic_core.dart';
import 'package:dartonic_sqlite/dartonic_sqlite.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'schema.dart';

/// Opens the app database on the platform default location, applies any
/// pending migrations loaded from `assets/migrations/`, and returns the
/// shared [DartonicDb].
Future<DartonicDb> openAppDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'flutter_todo.db');

  final db = await connectSqlite(
    dbPath,
    schemas: [todos],
    sync: false, // we run migrations explicitly below
  );

  await db.migrate(await _loadMigrations());
  return db;
}

Future<List<Migration>> _loadMigrations() async {
  // Each file under assets/migrations is listed in pubspec.yaml. Add new
  // migrations to this list as you create them.
  const files = ['001_init.sql'];

  final migrations = <Migration>[];
  for (final file in files) {
    final sql = await rootBundle.loadString('assets/migrations/$file');
    migrations.add(Migration(name: file, sql: sql));
  }
  return migrations;
}
