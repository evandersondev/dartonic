import '../drivers/driver.dart';
import '../types/table.dart';
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
}
