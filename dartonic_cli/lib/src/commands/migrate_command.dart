import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

class MigrateCommand extends Command<void> {
  MigrateCommand() {
    argParser
      ..addOption(
        'dir',
        abbr: 'd',
        defaultsTo: 'db/migrations',
        help: 'Directory containing .sql migration files.',
      )
      ..addOption(
        'create',
        abbr: 'c',
        help: 'Create a new migration file with the given name.',
      )
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'List pending migrations without executing them.',
      );
  }

  @override
  String get name => 'migrate';

  @override
  String get description => 'Run pending SQL migrations from db/migrations/.';

  @override
  Future<void> run() async {
    final dir = argResults!['dir'] as String;
    final dryRun = argResults!['dry-run'] as bool;
    final create = argResults!['create'] as String?;
    final migrationsDir = Directory(p.join(Directory.current.path, dir));

    if (create != null) {
      migrationsDir.createSync(recursive: true);
      final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final safeName = create.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final fileName = '${ts}_$safeName.sql';
      final file = File(p.join(migrationsDir.path, fileName));
      file.writeAsStringSync('-- Migration: $create\n');
      stdout.writeln('Created: ${file.path}');
      return;
    }

    if (!migrationsDir.existsSync()) {
      stderr.writeln('Migrations directory not found: ${migrationsDir.path}');
      stderr.writeln('Run `dartonic init` first.');
      exit(1);
    }

    final files = migrationsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (files.isEmpty) {
      stdout.writeln('No migration files found in ${migrationsDir.path}');
      return;
    }

    if (dryRun) {
      stdout.writeln('Pending migrations (dry run):');
      for (final f in files) {
        stdout.writeln('  ${p.basename(f.path)}');
      }
      return;
    }

    stdout.writeln(
      'Found ${files.length} migration file(s). '
      'Run your app with db.migrate() to apply them.',
    );
    stdout.writeln(
      '\nExample:\n'
      '  await db.sync();\n'
      '  await db.migrate(migrationsDir: \'$dir\');',
    );
  }
}
