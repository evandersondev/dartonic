import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

class InitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description => 'Initialise Dartonic in the current project.';

  @override
  Future<void> run() async {
    final cwd = Directory.current.path;

    // Create db/ directory structure
    final dirs = [
      p.join(cwd, 'db', 'migrations'),
      p.join(cwd, 'db', 'schema'),
    ];

    for (final dir in dirs) {
      Directory(dir).createSync(recursive: true);
      stdout.writeln('  created $dir');
    }

    // Create a sample schema file if none exists
    final schemaFile = File(p.join(cwd, 'db', 'schema', 'schema.dart'));
    if (!schemaFile.existsSync()) {
      schemaFile.writeAsStringSync(_sampleSchema);
      stdout.writeln('  created ${schemaFile.path}');
    }

    // Create a sample migration placeholder
    final migrationFile = File(
      p.join(cwd, 'db', 'migrations', '001_init.sql'),
    );
    if (!migrationFile.existsSync()) {
      migrationFile.writeAsStringSync('-- Initial migration\n');
      stdout.writeln('  created ${migrationFile.path}');
    }

    stdout.writeln('\nDartonic initialised. Next steps:');
    stdout.writeln('  1. Edit db/schema/schema.dart to define your tables');
    stdout.writeln('  2. Add SQL to db/migrations/001_init.sql');
    stdout.writeln('  3. Run: dartonic migrate');
  }

  static const _sampleSchema = '''
import 'package:dartonic_core/dartonic_core.dart';

final users = sqliteTable('users', {
  'id': integer().primaryKey(autoIncrement: true),
  'name': text().notNull(),
  'email': text().notNull().unique(),
  'created_at': datetime().defaultNow(),
});
''';
}
