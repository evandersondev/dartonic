import 'dart:io';

import 'package:dartonic_migrations_fs/dartonic_migrations_fs.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('dartonic_mig_'));
  tearDown(() => dir.deleteSync(recursive: true));

  File write(String name, String content) =>
      File('${dir.path}/$name')..writeAsStringSync(content);

  test('loads .sql files sorted by name', () {
    write('002_second.sql', 'SELECT 2;');
    write('001_first.sql', 'SELECT 1;');
    write('010_tenth.sql', 'SELECT 10;');

    final migrations = loadMigrationsFromDir(dir.path);
    expect(migrations.map((m) => m.name),
        ['001_first.sql', '002_second.sql', '010_tenth.sql']);
    expect(migrations.first.sql, 'SELECT 1;');
  });

  test('ignores non-.sql files', () {
    write('001_init.sql', 'SELECT 1;');
    write('README.md', '# not a migration');
    write('notes.txt', 'ignore me');

    final migrations = loadMigrationsFromDir(dir.path);
    expect(migrations.map((m) => m.name), ['001_init.sql']);
  });

  test('missing directory yields an empty list', () {
    expect(loadMigrationsFromDir('${dir.path}/does_not_exist'), isEmpty);
  });

  test('empty directory yields an empty list', () {
    expect(loadMigrationsFromDir(dir.path), isEmpty);
  });
}
