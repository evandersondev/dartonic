import 'drivers/driver.dart';
import 'query_builder/database_facade.dart';
import 'types/types.dart';

class Dartonic {
  static Dartonic? _instance;
  final String uri;
  final Map<String, TableSchema> _schemas;
  late final DatabaseDriver _driver;
  final List<PgEnumDefinition> _enums;

  Dartonic._internal(this.uri, List<TableSchema> schemas, this._enums)
      : _schemas = {for (var schema in schemas) schema.name: schema};

  factory Dartonic(
    String uri, {
    required List<TableSchema> schemas,
    List<PgEnumDefinition> enums = const [],
  }) {
    _instance ??= Dartonic._internal(uri, schemas, enums);
    return _instance!;
  }

  DatabaseFacade get instance => DatabaseFacade(_driver, _schemas);
  DatabaseFacade get I => DatabaseFacade(_driver, _schemas);

  Future<DatabaseFacade> sync() async {
    _driver = await SqlDriverFactory.getDriver(uri, _schemas);

    for (final e in _enums) {
      await _driver.execute(e.dropSql());
      await _driver.execute(e.toSql());
    }

    for (final schema in _schemas.values) {
      await _driver.createTable(
        schema.name,
        schema.columns.map(
          (field, col) => MapEntry(col.columnName ?? field, col.toString()),
        ),
      );
    }

    return DatabaseFacade(_driver, _schemas);
  }
}
