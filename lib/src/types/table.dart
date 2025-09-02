import 'column.dart';
import 'database_error.dart';

/// Tipos de ações para foreign keys
enum ReferentialAction {
  cascade,
  restrict,
  noAction,
  setNull,
  setDefault,
}

/// Definição de uma foreign key
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
    try {
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
    } catch (e) {
      throw ForeignKeyError('Failed to generate foreign key SQL', e);
    }
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

/// A classe Table estende TableSchema para poder ser usada no lugar de um TableSchema
class Table extends TableSchema {
  Table(
    super.name,
    super.columns, {
    super.foreignKeys = const [],
  });
}

/// Tipos suportados para SQLite
const List<String> supportedSqliteTypes = [
  "INTEGER",
  "TEXT",
  "REAL",
  "BLOB",
  "DATETIME"
];

/// Tipos suportados para MySQL
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

/// Funções para criar tabelas para diferentes bancos de dados
Table mysqlTable(
  String name,
  Map<String, ColumnType> columns, {
  List<ForeignKey> foreignKeys = const [],
}) {
  final cols = columns.map((key, value) {
    final colName = value.columnName ?? key;
    final typeMatch = RegExp(r'^([A-Z]+)').firstMatch(value.baseType);
    final baseTypeName =
        typeMatch != null ? typeMatch.group(1)! : value.baseType;

    if (!supportedMySQLTypes.contains(baseTypeName)) {
      throw TypeValidationError(
        "The column type '$baseTypeName' is not supported by MySQL.",
      );
    }
    return MapEntry(colName, value);
  });

  return Table(name, Map.from(cols), foreignKeys: foreignKeys);
}

Table sqliteTable(
  String name,
  Map<String, ColumnType> columns, {
  List<ForeignKey> foreignKeys = const [],
}) {
  final cols = columns.map((key, value) {
    final colName = value.columnName ?? key;

    if (!supportedSqliteTypes.contains(value.baseType)) {
      throw TypeValidationError(
        "The column type '${value.baseType}' is not supported by SQLite.",
      );
    }

    return MapEntry(colName, value);
  });

  return Table(name, Map.from(cols), foreignKeys: foreignKeys);
}

/// PostgreSQL types support
const List<String> supportedPostgresTypes = [
  "SMALLINT",
  "INTEGER",
  "BIGINT",
  "DECIMAL",
  "NUMERIC",
  "REAL",
  "DOUBLE PRECISION",
  "SERIAL",
  "SMALLSERIAL",
  "BIGSERIAL",
  "MONEY",
  "VARCHAR",
  "CHAR",
  "TEXT",
  "UUID",
  "BOOLEAN",
  "DATE",
  "TIME",
  "TIMESTAMP",
  "TIMESTAMPTZ",
  "INTERVAL",
  "BYTEA",
  "JSON",
  "JSONB",
  "INET",
  "CIDR",
  "MACADDR",
  "BIT",
  "VARBIT",
  "TSVECTOR",
  "TSQUERY",
  "XML",
  "ENUM",
  "POINT"
];

Table pgTable(
  String name,
  Map<String, ColumnType> columns, {
  List<ForeignKey> foreignKeys = const [],
}) {
  final cols = columns.map((key, value) {
    final colName = value.columnName ?? key;
    final typeMatch = RegExp(r'^([A-Z\s]+)').firstMatch(value.baseType);
    final baseTypeName =
        typeMatch != null ? typeMatch.group(1)!.trim() : value.baseType;

    if (!value.isEnum && !supportedPostgresTypes.contains(baseTypeName)) {
      throw TypeValidationError(
        "The column type '$baseTypeName' is not supported by PostgreSQL.",
      );
    }

    return MapEntry(colName, value);
  });

  return Table(name, Map.from(cols), foreignKeys: foreignKeys);
}
