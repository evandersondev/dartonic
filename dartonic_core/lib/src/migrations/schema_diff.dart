import '../drivers/driver.dart';
import '../types/table.dart';

/// The result of diffing declared [Table]s against a live database schema.
///
/// [statements] are DDL statements (in dependency-agnostic order:
/// CREATE TABLE first, then ADD COLUMN) that, when applied, bring the live
/// schema closer to the declared one.
class SchemaDiff {
  /// Ordered DDL statements to apply. Empty when the live schema already
  /// matches the declared tables for the cases we cover.
  final List<String> statements;

  /// Tables that exist in the declaration but not in the database.
  final List<String> createdTables;

  /// Columns added to existing tables, as `table.column` entries.
  final List<String> addedColumns;

  const SchemaDiff({
    this.statements = const [],
    this.createdTables = const [],
    this.addedColumns = const [],
  });

  bool get isEmpty => statements.isEmpty;
}

/// Introspects the live schema reachable through [driver] and diffs it against
/// the declared [tables], returning the DDL needed to reconcile the two.
///
/// ## Scope (INTENTIONALLY LIMITED — this is the foundation only)
///
/// COVERED:
///   * Tables present in [tables] but missing from the DB → `CREATE TABLE`.
///   * Columns present on a declared table but missing from the live table
///     → `ALTER TABLE ... ADD COLUMN`.
///
/// NOT COVERED (deliberately deferred; a real migration planner is a larger
/// effort and doing these half-way is dangerous):
///   * Dropped tables / dropped columns (no DROP is ever emitted — safer to
///     require an explicit migration).
///   * Renames (indistinguishable from drop+add without extra hints).
///   * Column TYPE changes, nullability changes, default changes.
///   * Constraint diffs: primary keys, unique, foreign keys, check, indexes.
///   * Column ordering.
///
/// The introspection uses each dialect's catalog:
///   * SQLite   → `PRAGMA table_info` + `sqlite_master`
///   * Postgres → `information_schema.tables` / `information_schema.columns`
///   * MySQL    → `information_schema.tables` / `information_schema.columns`
Future<SchemaDiff> diffSchema(
  DatabaseDriver driver,
  List<Table> tables, {
  required Dialect dialect,
}) async {
  final statements = <String>[];
  final createdTables = <String>[];
  final addedColumns = <String>[];

  final liveTables = await _liveTableNames(driver, dialect);

  for (final table in tables) {
    final name = table.tableName;
    if (!liveTables.contains(name)) {
      // Whole table is missing → CREATE TABLE.
      statements.add(_createTableSql(table, dialect));
      createdTables.add(name);
      continue;
    }

    // Table exists → diff columns and emit ADD COLUMN for the missing ones.
    final liveCols = await _liveColumnNames(driver, dialect, name);
    for (final col in table.columns) {
      if (!liveCols.contains(col.column)) {
        statements.add(_addColumnSql(name, col.column, col.toDdl(), dialect));
        addedColumns.add('$name.${col.column}');
      }
    }
  }

  return SchemaDiff(
    statements: statements,
    createdTables: createdTables,
    addedColumns: addedColumns,
  );
}

// ── DDL emission ────────────────────────────────────────────────────────────

String _quote(String id, Dialect dialect) =>
    dialect == Dialect.mysql ? '`$id`' : '"$id"';

/// Adapts a column DDL fragment for the target dialect, mirroring the
/// substitutions each driver's createTable() performs.
String _adaptDdl(String ddl, Dialect dialect) {
  switch (dialect) {
    case Dialect.mysql:
      return ddl
          .replaceAll('AUTOINCREMENT', 'AUTO_INCREMENT')
          .replaceAll('AUTOGENERATE', '');
    case Dialect.postgres:
      return ddl.replaceAll('AUTOINCREMENT', '').replaceAll('AUTOGENERATE', '');
    case Dialect.sqlite:
      return ddl;
  }
}

String _createTableSql(Table table, Dialect dialect) {
  final defs = table.columns
      .map((c) =>
          '${_quote(c.column, dialect)} ${_adaptDdl(c.toDdl(), dialect)}')
      .join(', ');
  return 'CREATE TABLE IF NOT EXISTS ${_quote(table.tableName, dialect)} '
      '($defs);';
}

String _addColumnSql(
    String table, String column, String ddl, Dialect dialect) {
  return 'ALTER TABLE ${_quote(table, dialect)} ADD COLUMN '
      '${_quote(column, dialect)} ${_adaptDdl(ddl, dialect)};';
}

// ── Introspection ───────────────────────────────────────────────────────────

Future<Set<String>> _liveTableNames(
    DatabaseDriver driver, Dialect dialect) async {
  switch (dialect) {
    case Dialect.sqlite:
      final rows = await driver.execute(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      );
      return rows.map((r) => r['name'] as String).toSet();
    case Dialect.postgres:
      final rows = await driver.execute(
        "SELECT table_name FROM information_schema.tables "
        "WHERE table_schema = 'public'",
      );
      return rows.map((r) => r['table_name'] as String).toSet();
    case Dialect.mysql:
      final rows = await driver.execute(
        'SELECT table_name FROM information_schema.tables '
        'WHERE table_schema = DATABASE()',
      );
      // MySQL may return the column as table_name or TABLE_NAME depending on
      // version/case settings.
      return rows
          .map((r) => (r['table_name'] ?? r['TABLE_NAME']) as String)
          .toSet();
  }
}

Future<Set<String>> _liveColumnNames(
    DatabaseDriver driver, Dialect dialect, String table) async {
  switch (dialect) {
    case Dialect.sqlite:
      final rows = await driver.execute('PRAGMA table_info("$table")');
      return rows.map((r) => r['name'] as String).toSet();
    case Dialect.postgres:
      final rows = await driver.execute(
        "SELECT column_name FROM information_schema.columns "
        "WHERE table_schema = 'public' AND table_name = ?",
        [table],
      );
      return rows.map((r) => r['column_name'] as String).toSet();
    case Dialect.mysql:
      final rows = await driver.execute(
        'SELECT column_name FROM information_schema.columns '
        'WHERE table_schema = DATABASE() AND table_name = ?',
        [table],
      );
      return rows
          .map((r) => (r['column_name'] ?? r['COLUMN_NAME']) as String)
          .toSet();
  }
}
