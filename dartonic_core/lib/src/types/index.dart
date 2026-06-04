import '../query_builder/condition.dart';
import 'column_ref.dart';

/// A SQL index declared on a [Table].
///
/// ```dart
/// @override
/// List<Index> defineIndexes() => [
///   index('idx_users_email').on([email]),
///   uniqueIndex('idx_users_username').on([username]),
///   index('idx_active_users').on([email]).where(isNotNull(activeAt)),
/// ];
/// ```
class Index {
  final String name;
  final List<ColumnRef<Object?>> columns;
  final bool unique;

  /// Optional partial-index predicate. SQLite + Postgres only — MySQL
  /// doesn't support partial indexes and will fail at index creation time.
  ///
  /// Bound values from the [Condition] are **inlined** as SQL literals
  /// (partial-index predicates can't use bind parameters).
  final Condition? where;

  const Index({
    required this.name,
    required this.columns,
    this.unique = false,
    this.where,
  });

  /// Emits `CREATE [UNIQUE] INDEX IF NOT EXISTS "name" ON "table" (cols)
  /// [WHERE …]`.
  String toSql() {
    if (columns.isEmpty) {
      throw ArgumentError('Index "$name" needs at least one column');
    }
    final tableName = columns.first.table;
    if (tableName.isEmpty) {
      throw StateError(
        'Index "$name" references a column not bound to a table — '
        'declare the column on a [Table] subclass first.',
      );
    }
    final cols = columns.map((c) => '"${c.column}"').join(', ');
    final keyword = unique ? 'CREATE UNIQUE INDEX' : 'CREATE INDEX';
    var sql = '$keyword IF NOT EXISTS "$name" ON "$tableName" ($cols)';
    if (where != null) {
      sql += ' WHERE ${inlineLiterals(where!.clause, where!.values)}';
    }
    return '$sql;';
  }
}

/// Fluent builder returned by [index] / [uniqueIndex].
class IndexBuilder {
  final String _name;
  final bool _unique;

  const IndexBuilder._(this._name, {bool unique = false}) : _unique = unique;

  /// Finalizes the index over the given column(s). Pass [where] for a
  /// partial index (SQLite / Postgres only).
  Index on(List<ColumnRef<Object?>> columns, {Condition? where}) =>
      Index(name: _name, columns: columns, unique: _unique, where: where);
}

/// Starts a regular (non-unique) index named [name]. Chain `.on([col1, col2])`.
IndexBuilder index(String name) => IndexBuilder._(name);

/// Starts a unique index named [name]. Chain `.on([col1, col2])`.
IndexBuilder uniqueIndex(String name) => IndexBuilder._(name, unique: true);
