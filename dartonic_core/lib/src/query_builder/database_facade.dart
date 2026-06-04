import '../drivers/driver.dart';
import '../types/cte.dart';
import '../types/table.dart';
import '../types/transaction_rollback.dart';
import 'query_builder.dart';

/// Public Database API exposed by [DartonicDb] and transactions.
abstract class Database {
  /// Starts a SELECT.
  ///
  /// - `db.select()` → `SELECT *` (chain `.from(table)` after).
  /// - `db.select([col1, col2])` → explicit columns.
  /// - `db.select({'alias': col1, 'total': sum(col2)})` → aliased projection
  ///   (Drizzle-style).
  QueryBuilder select([Object? projection]);

  /// Starts an INSERT into [table].
  QueryBuilder insert(Table table);

  /// Starts an UPDATE on [table].
  QueryBuilder update(Table table);

  /// Starts a DELETE on [table].
  QueryBuilder delete(Table table);

  /// Runs [callback] inside a transaction. Throw [TransactionRollback] from
  /// the callback to roll back without bubbling the error.
  Future<void> transaction(Future<void> Function(Database tx) callback);

  /// Forces a rollback. Only valid inside a [transaction].
  void rollback();

  /// Begins a CTE definition.
  CteBuilder withCte(String name);

  /// Starts a query against an existing CTE.
  QueryBuilder fromCte(CommonTableExpression cte);
}

class DatabaseFacade implements Database {
  final DatabaseDriver _driver;
  final Dialect _dialect;

  DatabaseFacade(this._driver, {Dialect dialect = Dialect.sqlite})
      : _dialect = dialect;

  QueryBuilder _builder({CommonTableExpression? cte}) =>
      QueryBuilder(_driver, cte, dialect: _dialect);

  @override
  QueryBuilder select([Object? projection]) =>
      _builder()..select(projection);

  @override
  QueryBuilder insert(Table table) => _builder()..insert(table);

  @override
  QueryBuilder update(Table table) => _builder()..update(table);

  @override
  QueryBuilder delete(Table table) => _builder()..delete(table);

  @override
  Future<void> transaction(Future<void> Function(Database tx) callback) async {
    await _driver.beginTransaction();
    try {
      await callback(DatabaseFacade(_driver, dialect: _dialect));
      await _driver.commitTransaction();
    } on TransactionRollback {
      await _driver.rollbackTransaction();
    } catch (e) {
      await _driver.rollbackTransaction();
      rethrow;
    }
  }

  @override
  void rollback() => throw TransactionRollback();

  @override
  CteBuilder withCte(String name) => CteBuilder(name);

  @override
  QueryBuilder fromCte(CommonTableExpression cte) =>
      _builder(cte: cte)..select()..fromRaw(cte.name);

  /// Convenience for running raw SQL that doesn't fit the builder.
  Future<List<Map<String, Object?>>> rawQuery(String sql,
          [List<Object?>? params]) =>
      _driver.execute(sql, params);
}
