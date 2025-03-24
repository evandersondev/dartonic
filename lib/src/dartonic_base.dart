import '../dartonic.dart';
import 'drivers/driver.dart';
import 'query_builder/database_facade.dart';

class Dartonic {
  static Dartonic? _instance;
  final String uri;
  final Map<String, TableSchema> _schemas;
  late final DatabaseDriver _driver;

  Dartonic._internal(this.uri, List<TableSchema> schemas)
      : _schemas = {for (var schema in schemas) schema.name: schema};

  factory Dartonic(String uri, List<TableSchema> schemas) {
    _instance ??= Dartonic._internal(uri, schemas);
    return _instance!;
  }

  DatabaseFacade get instance => DatabaseFacade(_driver, _schemas);
  DatabaseFacade get I => DatabaseFacade(_driver, _schemas);

  Future<DatabaseFacade> sync() async {
    _driver = await SqlDriverFactory.getDriver(uri);
    for (final schema in _schemas.values) {
      await _driver.createTable(
          schema.name,
          schema.columns.map((field, col) =>
              MapEntry(col.columnName ?? field, col.toString())));
    }
    return DatabaseFacade(_driver, _schemas);
  }
}
