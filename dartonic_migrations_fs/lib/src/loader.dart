import 'dart:io';

import 'package:dartonic_core/dartonic_core.dart';

/// Reads `.sql` migration files from [directory] and returns them sorted by
/// filename. Only available on the Dart VM (CLI / server / desktop) — uses
/// `dart:io`. On Flutter, load migrations via `rootBundle` instead.
///
/// File naming convention: `001_init.sql`, `002_add_users.sql`. The filename
/// is used as the migration name recorded in `__dartonic_migrations`.
List<Migration> loadMigrationsFromDir(String directory) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return const [];
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  return files
      .map((f) => Migration(
            name: f.uri.pathSegments.last,
            sql: f.readAsStringSync(),
          ))
      .toList(growable: false);
}
