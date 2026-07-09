import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:dartonic_cli/src/commands/generate_command.dart';
import 'package:dartonic_cli/src/commands/init_command.dart';
import 'package:dartonic_cli/src/commands/migrate_command.dart';
import 'package:dartonic_cli/src/commands/studio_command.dart';

void main(List<String> args) async {
  final runner = CommandRunner<void>(
    'dartonic',
    'The official CLI for Dartonic — a type-safe SQL builder for Dart.',
  )
    ..addCommand(InitCommand())
    ..addCommand(MigrateCommand())
    ..addCommand(GenerateCommand())
    ..addCommand(StudioCommand());

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e.message);
    exit(64);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
