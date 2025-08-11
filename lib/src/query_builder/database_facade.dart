import '../drivers/driver.dart';
import '../types/table.dart';
import '../types/transaction_rollback.dart';
import 'query_builder.dart';

class DatabaseFacade {
  final DatabaseDriver _driver;
  final Map<String, TableSchema> _schemas;

  DatabaseFacade(this._driver, this._schemas);

  QueryBuilder select([Map<String, String>? columns]) {
    return QueryBuilder(_driver, _schemas)..select(columns);
  }

  QueryBuilder insert(String table) {
    return QueryBuilder(_driver, _schemas)..insert(table);
  }

  QueryBuilder update(String table) {
    return QueryBuilder(_driver, _schemas)..update(table);
  }

  QueryBuilder delete(String table) {
    return QueryBuilder(_driver, _schemas)..delete(table);
  }

  Query get query => Query();

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

  void rollback() {
    throw TransactionRollback();
  }
}

class Query {}
