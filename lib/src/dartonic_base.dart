import 'package:darto/darto.dart';

import 'drivers/driver.dart';
import 'query_builder/database_facade.dart';
import 'types/types.dart';

class Dartonic {
  static Dartonic? _instance;
  final String uri;
  final Map<String, TableSchema> _schemas;
  late final DatabaseDriver _driver;
  final List<PgEnumDefinition> _enums;
  final bool enableStudio;

  Dartonic._internal(
    this.uri,
    List<TableSchema> schemas,
    this._enums, {
    this.enableStudio = false,
  }) : _schemas = {for (var schema in schemas) schema.name: schema};

  factory Dartonic(
    String uri, {
    required List<TableSchema> schemas,
    List<PgEnumDefinition> enums = const [],
    bool enableStudio = false,
  }) {
    _instance ??= Dartonic._internal(
      uri,
      schemas,
      enums,
      enableStudio: enableStudio,
    );
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

    if (enableStudio) {
      _startStudio();
    }

    return DatabaseFacade(_driver, _schemas);
  }

  void _startStudio() {
    final app = Darto();

    app.static('lib/src/studio');

    // Rota /studio para exibir as tabelas
    app.get('/studio', (Request req, Response res) async {
      // final tables = _schemas.keys.toList();
      // res.json({'tables': tables});
      return res.sendFile('lib/src/studio/index.html');
    });

    // Rota para visualizar os campos de uma tabela específica
    app.get('/studio/:table', (Request req, Response res) async {
      final tableName = req.params['table'];
      final schema = _schemas[tableName];
      if (schema == null) {
        res.status(404).send('Table not found');
        return;
      }

      final columns =
          schema.columns.map((name, col) => MapEntry(name, col.toString()));
      res.json(columns);
    });

    app.listen(
        8080,
        () => print(
            'Dartonic Studio is running at http://localhost:3000/studio'));
  }
}
