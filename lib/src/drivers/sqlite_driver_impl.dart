import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../types/table.dart';
import 'driver.dart';

class SqliteDriverImpl extends DatabaseDriver {
  final String uri;
  final Map<String, TableSchema> schemas;
  late Database _connection;

  SqliteDriverImpl(this.uri, this.schemas);

  @override
  Future<void> connect() async {
    if (uri == 'sqlite::memory:') {
      _connection = sqlite3.openInMemory();
    } else if (uri.startsWith("sqlite:")) {
      final filePath = uri.replaceFirst("sqlite:", "");
      final file = File(filePath);
      final directory = file.parent;

      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      _connection = sqlite3.open(filePath);
    } else {
      throw Exception("Unsupported URI scheme");
    }

    _connection.execute('PRAGMA foreign_keys = ON;');
  }

  @override
  Future<dynamic> raw(String query, [List<dynamic>? parameters]) async {
    final stmt = _connection.prepare(query);

    try {
      if (parameters == null) {
        return stmt.execute();
      } else {
        return stmt.execute(parameters);
      }
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    final schema = schemas[table];
    final columnDefinitions =
        columns.entries.map((e) => "${e.key} ${e.value}").toList();

    if (schema?.foreignKeys != null && schema!.foreignKeys.isNotEmpty) {
      for (final fk in schema.foreignKeys) {
        final foreignKeyDef = _buildForeignKeyConstraint(fk);
        columnDefinitions.add(foreignKeyDef);
      }
    }

    final sql = """
      CREATE TABLE IF NOT EXISTS $table (
        ${columnDefinitions.join(',\n        ')}
      );
    """;

    try {
      _connection.execute(sql);
    } catch (e) {
      rethrow;
    }
  }

  String _buildForeignKeyConstraint(ForeignKey fk) {
    final constraints = [
      'FOREIGN KEY (${fk.column})',
      'REFERENCES ${fk.references}(${fk.referencesColumn})',
    ];

    if (fk.onDelete != null) {
      constraints.add('ON DELETE ${_getSqliteAction(fk.onDelete!)}');
    }

    if (fk.onUpdate != null) {
      constraints.add('ON UPDATE ${_getSqliteAction(fk.onUpdate!)}');
    }

    return constraints.join(' ');
  }

  String _getSqliteAction(ReferentialAction action) {
    switch (action) {
      case ReferentialAction.cascade:
        return 'CASCADE';
      case ReferentialAction.restrict:
        return 'RESTRICT';
      case ReferentialAction.noAction:
        return 'NO ACTION';
      case ReferentialAction.setNull:
        return 'SET NULL';
      case ReferentialAction.setDefault:
        return 'SET DEFAULT';
    }
  }

  @override
  Future<List<Map<String, dynamic>>> execute(String query,
      [List? parameters]) async {
    try {
      final result = parameters == null
          ? _connection.select(query)
          : _connection.select(query, parameters);

      final rows = result.map((row) {
        final nestedMap = row.toTableColumnMap();
        if (nestedMap == null) {
          return Map<String, dynamic>.from(row);
        }
        final flattened = <String, dynamic>{};
        nestedMap.forEach((_, colMap) {
          flattened.addAll(colMap);
        });
        return flattened;
      }).toList();

      return Future.value(rows);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> beginTransaction() async {
    await raw('BEGIN', []);
  }

  @override
  Future<void> commitTransaction() async {
    await raw('COMMIT', []);
  }

  @override
  Future<void> rollbackTransaction() async {
    await raw('ROLLBACK', []);
  }
}
