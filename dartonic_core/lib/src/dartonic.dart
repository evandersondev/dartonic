import 'drivers/driver.dart';
import 'migrations/migration_runner.dart';
import 'migrations/schema_diff.dart';
import 'orm/orm_table.dart';
import 'query_builder/condition.dart';
import 'query_builder/database_facade.dart';
import 'query_builder/query_builder.dart';
import 'types/cte.dart';
import 'types/database_error.dart';
import 'types/relation.dart';
import 'types/table.dart';
import 'types/view.dart';

/// Driver-agnostic Dartonic database handle.
///
/// ```dart
/// final db = await connectSqlite(
///   'sqlite::memory:',
///   schemas: [Users(), Posts()],
/// );
/// final rows = await db.select(usersTable);
/// ```
class DartonicDb implements Database {
  final DatabaseDriver _driver;
  final List<Table> _schemas;
  final List<ViewSchema> _views;
  final List<RelationsTable> _relations;
  final Dialect _dialect;
  late final DatabaseFacade _facade;

  DartonicDb({
    required DatabaseDriver driver,
    required List<Table> schemas,
    Dialect dialect = Dialect.sqlite,
    List<ViewSchema> views = const [],
    List<RelationsTable> relations = const [],
  })  : _driver = driver,
        _schemas = schemas,
        _views = views,
        _relations = relations,
        _dialect = dialect {
    _facade = DatabaseFacade(_driver, dialect: dialect);
  }

  // ── Query methods (delegated to facade) ──────────────────────────────────

  @override
  QueryBuilder select([Object? projection]) => _facade.select(projection);

  @override
  QueryBuilder insert(Table table) => _facade.insert(table);

  @override
  QueryBuilder update(Table table) => _facade.update(table);

  @override
  QueryBuilder delete(Table table) => _facade.delete(table);

  @override
  Future<void> transaction(Future<void> Function(Database tx) callback) =>
      _facade.transaction(callback);

  @override
  void rollback() => _facade.rollback();

  @override
  CteBuilder withCte(String name) => _facade.withCte(name);

  @override
  QueryBuilder fromCte(CommonTableExpression cte) => _facade.fromCte(cte);

  // ── Schema / ORM helpers ─────────────────────────────────────────────────

  /// Returns the [OrmTable] helper for high-level find operations on [table].
  /// The helper is wired with this db's declared relations so
  /// `findManyWithRelations(with_: {...})` can resolve them.
  OrmTable<T> orm<T extends Table>(T table) => OrmTable<T>(
        table,
        _facade,
        relations: {
          for (final r in _relations) r.tableName: r.relations,
        },
        tableResolver: _resolveTable,
      );

  /// Resolves a table by name across registered schemas and relation tables.
  Table? _resolveTable(String name) {
    for (final t in _schemas) {
      if (t.tableName == name) return t;
    }
    for (final r in _relations) {
      if (r.tableName == name) return r;
    }
    return null;
  }

  /// All registered tables.
  List<Table> get schemas => List.unmodifiable(_schemas);

  /// Returns the [Table] for [name], or null if not registered.
  Table? schema(String name) {
    for (final t in _schemas) {
      if (t.tableName == name) return t;
    }
    return null;
  }

  /// Runs raw SQL and returns the rows untyped. Prefer typed query builder
  /// methods for application code.
  Future<List<Map<String, Object?>>> rawQuery(String sql,
          [List<Object?>? params]) =>
      _driver.execute(sql, params);

  /// Issues `CREATE TABLE IF NOT EXISTS` for every registered schema/view.
  Future<void> sync() async {
    try {
      for (final schema in _schemas) {
        try {
          await _driver.createTable(
            schema.tableName,
            {for (final c in schema.columns) c.column: c.toDdl()},
          );
        } catch (e) {
          throw ExecutionError(
              'Failed to create table ${schema.tableName}', e);
        }
      }

      for (final rel in _relations) {
        try {
          await _driver.createTable(
            rel.tableName,
            {for (final c in rel.columns) c.column: c.toDdl()},
          );
        } catch (e) {
          throw ExecutionError(
              'Failed to create relation table ${rel.tableName}', e);
        }
      }

      // Indexes — emitted after CREATE TABLE.
      for (final schema in _schemas) {
        for (final idx in schema.indexes) {
          try {
            await _driver.raw(idx.toSql());
          } catch (e) {
            throw ExecutionError(
                'Failed to create index ${idx.name} on ${schema.tableName}', e);
          }
        }
      }

      for (final view in _views) {
        try {
          final qb = QueryBuilder(_driver, null);
          final query = view.queryCallback(qb);
          // SQLite (and most engines) reject bind parameters inside CREATE
          // VIEW, so inline literals before sending.
          final body = inlineLiterals(
            query.toSql().trim().replaceAll(';', ''),
            query.getParameters(),
          );
          final sql = 'CREATE VIEW IF NOT EXISTS "${view.name}" AS $body';
          await _driver.raw(sql);
        } catch (e) {
          throw ExecutionError('Failed to create view ${view.name}', e);
        }
      }
    } catch (e) {
      if (e is DatabaseError) rethrow;
      throw ConnectionError('Failed to sync database', e);
    }
  }

  /// Applies pending [migrations] in order. See [MigrationRunner].
  Future<void> migrate(List<Migration> migrations) =>
      MigrationRunner(_driver, migrations: migrations).migrate();

  /// Diffs the declared schemas (and relation tables) against the live
  /// database schema and returns the DDL needed to reconcile them.
  ///
  /// This is the foundation for auto-migrations: it currently emits
  /// `CREATE TABLE` for missing tables and `ALTER TABLE ... ADD COLUMN` for
  /// missing columns. It does NOT detect drops, renames, type changes or
  /// constraint diffs — see [diffSchema] for the full scope. Intended to be
  /// driven by the CLI's `generate` command to scaffold a migration file.
  ///
  /// This is read-only: it introspects but never applies anything.
  Future<SchemaDiff> diff() =>
      diffSchema(_driver, [..._schemas, ..._relations], dialect: _dialect);

  /// Closes the underlying database connection and releases its resources.
  /// Call this when you're done with the database (e.g. on app shutdown) to
  /// avoid leaking sockets (Postgres/MySQL) or file handles (SQLite).
  Future<void> close() => _driver.close();
}
