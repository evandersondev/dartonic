import 'dart:io';

import 'package:args/command_runner.dart';

class StudioCommand extends Command<void> {
  @override
  String get name => 'studio';

  @override
  String get description => 'Instructions for starting Dartonic Studio locally.';

  @override
  Future<void> run() async {
    stdout.writeln('Dartonic Studio\n');
    stdout.writeln('Add the following to your Dart application entry point:\n');
    stdout.writeln('''  import 'package:dartonic_studio/dartonic_studio.dart';

  void main() async {
    final db = await connectSqlite('app.db', schemas: [users, posts]);
    await startStudio(db, port: 4444);
    // Open: http://localhost:4444/tables
  }
''');
    stdout.writeln('Available endpoints:');
    stdout.writeln('  GET  /tables          — list all registered tables');
    stdout.writeln('  GET  /tables/:name    — describe table columns');
    stdout.writeln('  POST /query           — run a SELECT query');
  }
}
