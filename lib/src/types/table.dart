import 'column.dart';

/// This class represents the schema of a table.
class TableSchema {
  final String name;
  final Map<String, ColumnType> columns;
  TableSchema(this.name, this.columns);
}

/// The Table class extends TableSchema so it can be used in place of a TableSchema.
class Table extends TableSchema {
  Table(super.name, super.columns);
}

/// Supported column types for SQLite.
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

/// Functions to create tables for different databases.
/// They now return a Table instance, which is also a TableSchema.
Table mysqlTable(String name, Map<String, ColumnType> columns) {
  // final cols = columns.map((key, value) {
  //   final colName = value.columnName ?? key;
  //   // Extract the base type name (e.g., from "VARCHAR(255)" extract "VARCHAR")
  //   final typeMatch = RegExp(r'^([A-Z]+)').firstMatch(value.baseType);
  //   final baseTypeName =
  //       typeMatch != null ? typeMatch.group(1)! : value.baseType;
  //   if (!supportedMySQLTypes.contains(baseTypeName)) {
  //     throw Exception(
  //         "The column type '$baseTypeName' is not supported by MySQL.");
  //   }
  //   return MapEntry(colName, value);
  // });
  // return Table(name, Map.from(cols));

  final cols = columns.map((key, value) {
    final colName = value.columnName ?? key;
    return MapEntry(colName, value);
  });
  return Table(name, Map.from(cols));
}

Table sqliteTable(String name, Map<String, ColumnType> columns) {
  final cols = columns.map((key, value) {
    final colName = value.columnName ?? key;

    if (!supportedSqliteTypes.contains(value.baseType)) {
      throw Exception(
          "The column type '${value.baseType}' is not supported by SQLite.");
    }

    return MapEntry(colName, value);
  });

  return Table(name, Map.from(cols));
}

Table pgTable(String name, Map<String, ColumnType> columns) {
  final cols = columns.map((key, value) {
    final colName = value.columnName ?? key;
    return MapEntry(colName, value);
  });
  return Table(name, Map.from(cols));
}
