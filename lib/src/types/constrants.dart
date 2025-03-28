import 'types.dart';

abstract class TableConstraint {
  String toSql();
}

// Classe para índices
class IndexConstraint extends TableConstraint {
  final String name;
  final List<String> columns;
  final bool unique;

  IndexConstraint(this.name, this.columns, {this.unique = false});

  @override
  String toSql() {
    final type = unique ? 'UNIQUE INDEX' : 'INDEX';
    return 'CREATE $type IF NOT EXISTS $name ON ($columns)';
  }

  static IndexConstraint on(List<String> columns) {
    return IndexConstraint('idx_${columns.join('_')}', columns);
  }
}

// Classe para unique constraints
class UniqueConstraint extends TableConstraint {
  final String? name;
  final List<String> columns;

  UniqueConstraint({this.name, required this.columns});

  @override
  String toSql() {
    final constraintName = name != null ? 'CONSTRAINT $name ' : '';
    return '${constraintName}UNIQUE (${columns.join(', ')})';
  }

  static UniqueConstraint on(List<String> columns) {
    return UniqueConstraint(columns: columns);
  }
}

// Classe para primary key constraints
class PrimaryKeyConstraint extends TableConstraint {
  final String? name;
  final List<String> columns;

  PrimaryKeyConstraint({this.name, required this.columns});

  @override
  String toSql() {
    final constraintName = name != null ? 'CONSTRAINT $name ' : '';
    return '${constraintName}PRIMARY KEY (${columns.join(', ')})';
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
PrimaryKeyConstraint primaryKey(
        {String? name, required List<String> columns}) =>
    PrimaryKeyConstraint(name: name, columns: columns);
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
