import '../drivers/driver.dart';
import '../types/cte.dart';
import '../types/table.dart';
import '../types/transaction_rollback.dart';

import 'query_builder.dart';

abstract class Database {
  QueryBuilder select([Map<String, String>? columns]);
  QueryBuilder insert(String table);
  QueryBuilder update(String table);
  QueryBuilder delete(String table);
  Query get query;
  Future<void> transaction(Future<void> Function(Database tx) callback);
  void rollback();
  CteBuilder $with(String name);
  QueryBuilder with$(CommonTableExpression cte);
}

class DatabaseFacade implements Database {
  final DatabaseDriver _driver;
  final Map<String, TableSchema> _schemas;

  DatabaseFacade(this._driver, this._schemas);

  @override
  QueryBuilder select([Map<String, String>? columns]) {
    return QueryBuilder(_driver, _schemas, null)..select(columns);
  }

  @override
  QueryBuilder insert(String table) {
    return QueryBuilder(_driver, _schemas, null)..insert(table);
  }

  @override
  QueryBuilder update(String table) {
    return QueryBuilder(_driver, _schemas, null)..update(table);
  }

  @override
  QueryBuilder delete(String table) {
    return QueryBuilder(_driver, _schemas, null)..delete(table);
  }

  @override
  Query get query => Query();

  @override
  Future<void> transaction(
      Future<void> Function(DatabaseFacade tx) callback) async {
    await _driver.beginTransaction();
    try {
      final tx = DatabaseFacade(_driver, _schemas);
      await callback(tx);
      await _driver.commitTransaction();
    } on TransactionRollback {
      await _driver.rollbackTransaction();
    } catch (e) {
      await _driver.rollbackTransaction();
      rethrow;
    }
  }

  @override
  void rollback() {
    throw TransactionRollback();
  }

  @override
  CteBuilder $with(String name) {
    return CteBuilder(name);
  }

  @override
  QueryBuilder with$(CommonTableExpression cte) {
    return QueryBuilder(_driver, _schemas, cte);
  }
}

class Query {}
