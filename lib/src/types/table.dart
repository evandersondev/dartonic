import 'column.dart';
import 'constrants.dart';

enum ReferentialAction {
  cascade,
  restrict,
  noAction,
  setNull,
  setDefault,
}

class ForeignKey {
  final String column;
  final String references;
  final String referencesColumn;
  final ReferentialAction? onDelete;
  final ReferentialAction? onUpdate;

  ForeignKey({
    required this.column,
    required this.references,
    required this.referencesColumn,
    this.onDelete,
    this.onUpdate,
  });

  String toSql() {
    final constraints = [
      'FOREIGN KEY ($column)',
      'REFERENCES $references($referencesColumn)',
    ];

    if (onDelete != null) {
      constraints.add('ON DELETE ${_actionToSql(onDelete!)}');
    }

    if (onUpdate != null) {
      constraints.add('ON UPDATE ${_actionToSql(onUpdate!)}');
    }

    return constraints.join(' ');
  }

  String _actionToSql(ReferentialAction action) {
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
}

/// Representa o schema de uma tabela
class TableSchema {
  final String name;
  final Map<String, ColumnType> columns;
  final List<ForeignKey> foreignKeys;

  TableSchema(
    this.name,
    this.columns, {
    this.foreignKeys = const [],
  });
}

class Table extends TableSchema {
  final List<TableConstraint> constraints;

  Table(
    super.name,
    super.columns, {
    super.foreignKeys,
    this.constraints = const [],
  });
}

typedef TableConstraintsCallback = List<TableConstraint> Function();

const List<String> supportedSqliteTypes = [
  "INTEGER",
  "TEXT",
  "REAL",
  "BLOB",
  "DATETIME"
];

const List<String> supportedMySQLTypes = [
  "SERIAL",
  "VARCHAR",
  "INTEGER",
  "TEXT",
  "UUID",
  "REAL",
  "BLOB",
  "TINYINT",
  "SMALLINT",
  "BIGINT",
  "MEDIUMINT",
  "DECIMAL",
  "DOUBLE",
  "FLOAT",
  "BINARY",
  "VARBINARY",
  "CHAR",
  "BOOLEAN",
  "DATE",
  "DATETIME",
  "YEAR",
  "ENUM"
];

Table sqliteTable(String name, Map<String, ColumnType> columns,
    [TableConstraintsCallback? constraints]) {
  final cols = columns.map((key, value) {
    final colName = value.columnName ?? key;

    if (!supportedSqliteTypes.contains(value.baseType)) {
      throw Exception(
        "O tipo de coluna '${value.baseType}' não é suportado pelo SQLite.",
      );
    }

    return MapEntry(colName, value);
  });

  return Table(
    name,
    Map.from(cols),
    constraints: constraints != null ? constraints() : [],
  );
}

Table mysqlTable(
  String name,
  Map<String, ColumnType> columns, {
  List<ForeignKey> foreignKeys = const [],
  TableConstraintsCallback? constraints,
}) {
  final cols = columns.map((key, value) {
    final colName = value.columnName ?? key;
    final typeMatch = RegExp(r'^([A-Z]+)').firstMatch(value.baseType);
    final baseTypeName =
        typeMatch != null ? typeMatch.group(1)! : value.baseType;

    if (!supportedMySQLTypes.contains(baseTypeName)) {
      throw Exception(
        "O tipo de coluna '$baseTypeName' não é suportado pelo MySQL.",
      );
    }
    return MapEntry(colName, value);
  });

  return Table(
    name,
    Map.from(cols),
    constraints: constraints != null ? constraints() : [],
    foreignKeys: foreignKeys,
  );
}

Table pgTable(
  String name,
  Map<String, ColumnType> columns, {
  List<ForeignKey> foreignKeys = const [],
}) {
  final cols = columns.map((key, value) {
    final colName = value.columnName ?? key;
    return MapEntry(colName, value);
  });
  return Table(name, Map.from(cols), foreignKeys: foreignKeys);
}
