import 'package:dartonic/src/drivers/raw_driver.dart';

import 'drivers/driver.dart';
import 'orm/orm_table.dart';
import 'query_builder/database_facade.dart';
import 'types/database_error.dart';
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
    try {
      _driver = await SqlDriverFactory.getDriver(uri, _schemas);

      for (final e in _enums) {
        try {
          await _driver.execute(e.dropSql());
          await _driver.execute(e.toSql());
        } catch (e) {
          throw ExecutionError('Failed to create enum $e', e);
        }
      }

      for (final schema in _schemas.values) {
        try {
          await _driver.createTable(
            schema.name,
            schema.columns.map(
              (field, col) => MapEntry(col.columnName ?? field, col.toString()),
            ),
          );
        } catch (e) {
          throw ExecutionError('Failed to create table ${schema.name}', e);
        }
      }

      for (final relation in _relations) {
        try {
          await _driver.createTable(
            relation.name,
            relation.columns.map(
              (field, col) => MapEntry(col.columnName ?? field, col.toString()),
            ),
          );
        } catch (e) {
          throw ExecutionError(
              'Failed to create relation table ${relation.name}', e);
        }
      }

      final dbFacade = DatabaseFacade(_driver, _schemas);

      for (final view in _views) {
        try {
          final qb = dbFacade.select();
          final query = view.queryCallback(qb);
          final sql =
              'CREATE VIEW "${view.name}" AS ${query.toSql().trim().replaceAll(';', '')}';
          await _driver.raw(sql, query.getParameters());
        } catch (e) {
          throw ExecutionError('Failed to create view ${view.name}', e);
        }
      }

      return dbFacade;
    } catch (e) {
      if (e is DatabaseError) rethrow;
      throw ConnectionError('Failed to initialize database', e);
    }
  }
}
