import '../drivers/driver.dart';
import 'query_builder.dart';

class DatabaseFacade {
  final DatabaseDriver _driver;
  DatabaseFacade(this._driver);

  QueryBuilder select([Map<String, String>? columns]) {
    return QueryBuilder(_driver)..select(columns);
  }

  QueryBuilder insert(String table) {
    return QueryBuilder(_driver)..insert(table);
  }

  QueryBuilder update(String table) {
    return QueryBuilder(_driver)..update(table);
  }

  QueryBuilder delete(String table) {
    return QueryBuilder(_driver)..delete(table);
  }
}
