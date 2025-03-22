import 'drivers/driver.dart';
import 'query_builder/database_facade.dart';
import 'types/relation.dart';
import 'types/table.dart';

class Dartonic {
  static Dartonic? _instance;

  final String uri;
  final List<Table> _tables;
  late final DatabaseDriver _driver;

  Dartonic._internal(this.uri, this._tables);

  factory Dartonic(String uri, List<Table> tables) {
    _instance ??= Dartonic._internal(uri, tables);
    return _instance!;
  }

  DatabaseFacade get instance => DatabaseFacade(_driver);
  DatabaseFacade get I => DatabaseFacade(_driver);

  Future<DatabaseFacade> sync() async {
    _driver = await SqlDriverFactory.getDriver(uri);
    for (final table in _tables) {
      if (table.columns.isNotEmpty && table is! RelationsTable) {
        await _driver.createTable(table.name, table.columns);
      }
    }
    return DatabaseFacade(_driver);
  }
}
