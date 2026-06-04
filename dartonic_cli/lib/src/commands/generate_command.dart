import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

class GenerateCommand extends Command<void> {
  GenerateCommand() {
    argParser.addOption(
      'schema',
      abbr: 's',
      defaultsTo: 'db/schema/schema.dart',
      help: 'Path to the schema file.',
    );
  }

  @override
  String get name => 'generate';

  @override
  String get description => 'Generate typed model helpers from your schema.';

  @override
  Future<void> run() async {
    final schemaPath = p.join(
      Directory.current.path,
      argResults!['schema'] as String,
    );

    if (!File(schemaPath).existsSync()) {
      stderr.writeln('Schema file not found: $schemaPath');
      stderr.writeln('Run `dartonic init` first.');
      exit(1);
    }

    stdout.writeln('Schema: $schemaPath');
    stdout.writeln(
      '\nNote: Full code generation (typed model classes) requires '
      'build_runner integration — coming in a future release.\n'
      'For now, use .mapTo<T>() for typed query results:\n\n'
      '  final users = await db.instance\n'
      '    .select()\n'
      '    .from(\'users\')\n'
      '    .mapTo(User.fromJson);\n',
    );
  }
}
