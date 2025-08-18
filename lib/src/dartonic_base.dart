import 'package:dartonic/src/drivers/raw_driver.dart';

import 'drivers/driver.dart';
import 'orm/orm_table.dart';
import 'query_builder/database_facade.dart';
import 'types/types.dart';
import 'types/view.dart';

class Dartonic {
  static Dartonic? _instance;
  final String uri;
  final Map<String, TableSchema> _schemas;
  late final DatabaseDriver _driver;
  final List<PgEnumDefinition> _enums;
  final List<ViewSchema> _views;
  final List<RelationsTable> _relations;

  Dartonic._internal(this.uri, List<TableSchema> schemas, this._enums,
      this._views, this._relations)
      : _schemas = {for (var schema in schemas) schema.name: schema};

  factory Dartonic(
    String uri, {
    required List<TableSchema> schemas,
    List<PgEnumDefinition> enums = const [],
    List<ViewSchema> views = const [],
    List<RelationsTable> relations = const [],
  }) {
    _instance ??= Dartonic._internal(uri, schemas, enums, views, relations);
    return _instance!;
  }

  RawDriver get driver => RawDriverWrapper(_driver);
  Database get instance => DatabaseFacade(_driver, _schemas);
  Database get I => DatabaseFacade(_driver, _schemas);

  OrmTable table(String tableName) {
    return OrmTable(tableName, DatabaseFacade(_driver, _schemas));
  }

  Future<Database> sync() async {
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

    for (final relation in _relations) {
      await _driver.createTable(
        relation.name,
        relation.columns.map(
          (field, col) => MapEntry(col.columnName ?? field, col.toString()),
        ),
      );
    }

    final dbFacade = DatabaseFacade(_driver, _schemas);
    for (final view in _views) {
      final qb = dbFacade.select();
      final query = view.queryCallback(qb);
      final sql =
          'CREATE VIEW "${view.name}" AS ${query.toSql().trim().replaceAll(';', '')}';
      await _driver.raw(sql, query.getParameters());
    }

    return dbFacade;
  }
}
