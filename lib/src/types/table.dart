import 'package:dartonic/src/types/column.dart';

class Table {
  final String name;
  final Map<String, String> columns;
  Table(this.name, this.columns);
}

// Funções para criar tabelas para diferentes bancos de dados.
// Se o ColumnType possuir um columnName, esse nome será utilizado,
// caso contrário, a chave do mapa será utilizada.
Table mysqlTable(String name, Map<String, ColumnType> columns) {
  final cols = columns.entries.map((e) {
    final colName = e.value.columnName ?? e.key;
    return MapEntry(colName, e.value.toString());
  });
  return Table(name, Map.fromEntries(cols));
}

Table sqliteTable(String name, Map<String, ColumnType> columns) {
  final cols = columns.entries.map((e) {
    final colName = e.value.columnName ?? e.key;
    return MapEntry(colName, e.value.toString());
  });
  return Table(name, Map.fromEntries(cols));
}

Table pgTable(String name, Map<String, ColumnType> columns) {
  final cols = columns.entries.map((e) {
    final colName = e.value.columnName ?? e.key;
    return MapEntry(colName, e.value.toString());
  });
  return Table(name, Map.fromEntries(cols));
}

Table createTable(String name, Map<String, ColumnType> columns) {
  final cols = columns.entries.map((e) {
    final colName = e.value.columnName ?? e.key;
    return MapEntry(colName, e.value.toString());
  });
  return Table(name, Map.fromEntries(cols));
}
