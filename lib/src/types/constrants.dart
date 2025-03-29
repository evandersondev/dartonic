import 'table.dart';

// Classe base para constraints
abstract class TableConstraint {
  String toSql();
}

// Classe para índices
class IndexConstraint extends TableConstraint {
  final String name;
  List<String> columns;
  final bool unique;

  IndexConstraint(this.name, this.columns, {this.unique = false});

  @override
  String toSql() {
    final type = unique ? 'UNIQUE INDEX' : 'INDEX';
    return 'CREATE $type IF NOT EXISTS $name ON (${columns.join(', ')})';
  }

  IndexConstraint on(List<String> columns) {
    this.columns = columns;
    return this;
  }
}

// Classe para unique constraints
class UniqueConstraint extends TableConstraint {
  final String? name;
  List<String> columns;

  UniqueConstraint({this.name, required this.columns});

  @override
  String toSql() {
    final constraintName = name != null ? 'CONSTRAINT $name ' : '';
    return '${constraintName}UNIQUE (${columns.join(', ')})';
  }

  UniqueConstraint on(List<String> columns) {
    this.columns = columns;
    return this;
  }
}

// Classe para primary key constraints
class PrimaryKeyConstraint extends TableConstraint {
  final String? name;
  final List<String> columns;
  final bool autoIncrement;

  PrimaryKeyConstraint(
      {this.name, required this.columns, this.autoIncrement = false});

  @override
  String toSql() {
    final constraintName = name != null ? 'CONSTRAINT $name ' : '';
    final autoIncrementClause = autoIncrement ? 'AUTOINCREMENT' : '';
    return '${constraintName}PRIMARY KEY $autoIncrementClause (${columns.join(', ')})';
  }

  PrimaryKeyConstraint on(List<String> columns) {
    return PrimaryKeyConstraint(name: name, columns: columns);
  }
}

// Classe para foreign key constraints
class ForeignKeyConstraint extends TableConstraint {
  final String? name;
  final List<String> columns;
  final String foreignTable;
  final List<String> foreignColumns;
  final ReferentialAction? onDelete;
  final ReferentialAction? onUpdate;

  ForeignKeyConstraint({
    this.name,
    required this.columns,
    required this.foreignTable,
    required this.foreignColumns,
    this.onDelete,
    this.onUpdate,
  });

  @override
  String toSql() {
    final constraintName = name != null ? 'CONSTRAINT $name ' : '';
    var sql = '${constraintName}FOREIGN KEY (${columns.join(', ')}) '
        'REFERENCES $foreignTable (${foreignColumns.join(', ')})';

    if (onDelete != null) {
      sql += ' ON DELETE ${_getAction(onDelete!)}';
    }
    if (onUpdate != null) {
      sql += ' ON UPDATE ${_getAction(onUpdate!)}';
    }

    return sql;
  }

  String _getAction(ReferentialAction action) {
    switch (action) {
      case ReferentialAction.cascade:
        return 'CASCADE';
      case ReferentialAction.restrict:
        return 'RESTRICT';
      case ReferentialAction.setNull:
        return 'SET NULL';
      case ReferentialAction.setDefault:
        return 'SET DEFAULT';
      case ReferentialAction.noAction:
        return 'NO ACTION';
    }
  }

  ForeignKeyConstraint on(List<String> columns) {
    return ForeignKeyConstraint(
      name: name,
      columns: columns,
      foreignTable: foreignTable,
      foreignColumns: foreignColumns,
      onDelete: onDelete,
      onUpdate: onUpdate,
    );
  }
}

// Classe para check constraints
class CheckConstraint extends TableConstraint {
  final String name;
  final String expression;

  CheckConstraint(this.name, this.expression);

  @override
  String toSql() {
    return 'CONSTRAINT $name CHECK ($expression)';
  }
}

// Funções helper para criar constraints
IndexConstraint index(String name) => IndexConstraint(name, []);
UniqueConstraint unique([String? name]) =>
    UniqueConstraint(name: name, columns: []);
UniqueConstraint uniqueIndex(String name) =>
    UniqueConstraint(name: name, columns: []);
PrimaryKeyConstraint primaryKey(
        {String? name, required List<String> columns, autoIncrement = false}) =>
    PrimaryKeyConstraint(
        name: name, columns: columns, autoIncrement: autoIncrement);
ForeignKeyConstraint foreignKey({
  String? name,
  required List<String> columns,
  required String foreignTable,
  required List<String> foreignColumns,
  ReferentialAction? onDelete,
  ReferentialAction? onUpdate,
}) =>
    ForeignKeyConstraint(
      name: name,
      columns: columns,
      foreignTable: foreignTable,
      foreignColumns: foreignColumns,
      onDelete: onDelete,
      onUpdate: onUpdate,
    );
CheckConstraint check(String name, String expression) =>
    CheckConstraint(name, expression);
