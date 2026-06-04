import '../drivers/driver.dart';
import '../types/database_error.dart';

/// One SQL migration. The runner applies migrations in declaration order and
/// records the [name] in the `__dartonic_migrations` table so they only run
/// once.
class Migration {
  final String name;
  final String sql;
  const Migration({required this.name, required this.sql});
}

/// Applies pending migrations against a [DatabaseDriver].
///
/// Pure Dart — no filesystem access. Use the optional `dartonic_migrations_fs`
/// package if you want to read migrations from `.sql` files on disk in a
/// CLI/server environment. On Flutter, load them via `rootBundle` from your
/// assets folder.
class MigrationRunner {
  final DatabaseDriver _driver;
  final List<Migration> migrations;

  MigrationRunner(this._driver, {required this.migrations});

  Future<void> migrate() async {
    try {
      await _ensureTable();
      final executed = await _getExecuted();

      for (final m in migrations) {
        if (executed.contains(m.name)) continue;
        final sql = m.sql.trim();
        if (sql.isEmpty) continue;

        try {
          for (final stmt in sql
              .split(';')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)) {
            await _driver.raw('$stmt;');
          }
          await _driver.raw(
            'INSERT INTO "__dartonic_migrations" (name) VALUES (?)',
            [m.name],
          );
        } catch (e) {
          throw ExecutionError('Migration "${m.name}" failed', e);
        }
      }
    } catch (e) {
      if (e is DatabaseError) rethrow;
      throw ExecutionError('Migration runner failed', e);
    }
  }

  Future<void> _ensureTable() => _driver.raw('''
    CREATE TABLE IF NOT EXISTS "__dartonic_migrations" (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  Future<Set<String>> _getExecuted() async {
    final rows = await _driver.execute(
      'SELECT name FROM "__dartonic_migrations" ORDER BY name',
    );
    return rows.map((r) => r['name'] as String).toSet();
  }
}
