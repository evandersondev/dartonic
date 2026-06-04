import 'column.dart';
import 'column_ref.dart';
import 'database_error.dart';
import 'index.dart';

/// SQL dialect identifier. Used by the connector functions
/// ([connectSqlite], [connectPostgres], [connectMysql]) to validate that
/// every column type a schema uses is supported by the target database.
enum Dialect { sqlite, postgres, mysql }

/// Table-level foreign-key constraint. Use [Column.references] for the
/// common single-column case; [ForeignKey] handles composite keys or
/// table-level declarations.
///
/// ```dart
/// @override
/// List<ForeignKey> defineForeignKeys() => [
///   ForeignKey.single(
///     from: userId,
///     to: () => users.id,
///     onDelete: ReferentialAction.cascade,
///   ),
/// ];
/// ```
class ForeignKey {
  /// Local column(s) that participate in the FK.
  final List<ColumnRef<Object?>> from;

  /// Thunk returning the target column(s). Lazy to allow forward references.
  final List<ColumnRef<Object?>> Function() to;

  final ReferentialAction? onDelete;
  final ReferentialAction? onUpdate;

  const ForeignKey({
    required this.from,
    required this.to,
    this.onDelete,
    this.onUpdate,
  });

  /// Convenience for single-column foreign keys.
  factory ForeignKey.single({
    required ColumnRef<Object?> from,
    required ColumnRef<Object?> Function() to,
    ReferentialAction? onDelete,
    ReferentialAction? onUpdate,
  }) =>
      ForeignKey(
        from: [from],
        to: () => [to()],
        onDelete: onDelete,
        onUpdate: onUpdate,
      );

  String toSql() {
    final targets = to();
    if (from.length != targets.length) {
      throw StateError(
        'ForeignKey from/to column counts mismatch: '
        '${from.length} vs ${targets.length}',
      );
    }
    final fromCols = from.map((c) => '"${c.column}"').join(', ');
    final targetTable = targets.first.table;
    final targetCols = targets.map((c) => '"${c.column}"').join(', ');
    final parts = [
      'FOREIGN KEY ($fromCols)',
      'REFERENCES "$targetTable"($targetCols)',
    ];
    if (onDelete != null) parts.add('ON DELETE ${onDelete!.sql}');
    if (onUpdate != null) parts.add('ON UPDATE ${onUpdate!.sql}');
    return parts.join(' ');
  }
}

/// Base class for typed schema tables.
///
/// Subclass and declare each column as a `final` field. The framework
/// collects columns automatically and derives [tableName] from the class
/// name:
///
/// ```dart
/// class UsersTable extends Table {
///   final id    = integer('id').primaryKey(autoIncrement: true);
///   final email = text('email').notNull();
/// }
/// // UsersTable  → "users"     (suffix "Table" stripped + snake_case)
/// // BlogPosts   → "blog_posts"
/// // OrderItem   → "order_item"
/// ```
///
/// Override [tableName] only when you need a name that doesn't match the
/// convention.
///
/// Dialect validation happens later at connection time
/// (`connectSqlite`, `connectPostgres`, `connectMysql`) — the table itself is
/// dialect-agnostic.
abstract class Table {
  late final List<Column<Object?>> _columns;
  late final Map<String, Column<Object?>> _columnIndex;
  late final List<ForeignKey> _foreignKeys;
  late final List<Index> _indexes;

  Table() {
    // Subclass field initializers ran just before this body — every column
    // factory ([integer], [text], …) pushed its column onto the global
    // pending list. Take ownership of that list.
    _columns = List.unmodifiable(Column.takePending());
    final colIndex = <String, Column<Object?>>{};
    for (final c in _columns) {
      c.bindToTable(tableName);
      colIndex[c.column] = c;
    }
    _columnIndex = Map.unmodifiable(colIndex);
    _foreignKeys = List.unmodifiable(defineForeignKeys());
    _indexes = List.unmodifiable(defineIndexes());
  }

  /// SQL table name. By default derived from the runtime class name:
  /// strips the suffixes `Table`, `Tbl` or `Schema`, then converts
  /// CamelCase to snake_case. Override for custom names.
  String get tableName => _deriveTableNameFromRuntime(runtimeType.toString());

  /// Override to declare foreign-key constraints emitted at the table level.
  List<ForeignKey> defineForeignKeys() => const [];

  /// Override to declare indexes for this table. Each index is materialized
  /// during `db.sync()` via `CREATE INDEX IF NOT EXISTS`.
  ///
  /// ```dart
  /// @override
  /// List<Index> defineIndexes() => [
  ///   index('idx_users_email').on([email]),
  ///   uniqueIndex('idx_users_username').on([username]),
  /// ];
  /// ```
  List<Index> defineIndexes() => const [];

  /// All columns declared on the table, in declaration order.
  List<Column<Object?>> get columns => _columns;

  /// Lookup a column by SQL name. Returns null if not declared.
  Column<Object?>? columnByName(String name) => _columnIndex[name];

  /// Foreign keys declared on the table.
  List<ForeignKey> get foreignKeys => _foreignKeys;

  /// Indexes declared on the table.
  List<Index> get indexes => _indexes;
}

/// Derives a snake_case SQL table name from a Dart class name. Strips one
/// of the conventional suffixes (`Table`, `Tbl`, `Schema`) and inserts an
/// underscore before each capital letter.
///
/// ```
/// UsersTable        → users
/// BlogPostsTable    → blog_posts
/// OrderItemSchema   → order_item
/// User              → user
/// HTTPRequestTable  → h_t_t_p_request   (not ideal — override for these)
/// ```
String _deriveTableNameFromRuntime(String classN) {
  var name = classN;
  for (final suffix in const ['Table', 'Tbl', 'Schema']) {
    if (name.length > suffix.length && name.endsWith(suffix)) {
      name = name.substring(0, name.length - suffix.length);
      break;
    }
  }
  final buf = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final c = name[i];
    final lower = c.toLowerCase();
    if (i > 0 && c != lower) {
      buf.write('_');
    }
    buf.write(lower);
  }
  return buf.toString();
}

/// Validates that every column in [tables] uses a SQL type supported by the
/// given [dialect]. Called by the connector functions
/// ([connectSqlite] etc.) — you don't normally invoke this directly.
void validateTablesForDialect(List<Table> tables, Dialect dialect) {
  final supported = switch (dialect) {
    Dialect.sqlite => _supportedSqliteTypes,
    Dialect.mysql => _supportedMysqlTypes,
    Dialect.postgres => _supportedPostgresTypes,
  };
  for (final table in tables) {
    for (final col in table.columns) {
      final m = RegExp(r'^([A-Z\s]+)').firstMatch(col.sqlType);
      final base = m != null ? m.group(1)!.trim() : col.sqlType;
      if (base.isEmpty) continue;
      if (col is PgEnumColumn) continue;
      if (!supported.contains(base)) {
        throw TypeValidationError(
          'Column "${table.tableName}.${col.column}" uses SQL type "$base" '
          'which is not supported by ${dialect.name}.',
        );
      }
    }
  }
}

/// Untyped dynamic-shape table for ad-hoc raw SQL paths. Strongly prefer
/// subclassing [Table] for application schemas.
class RawTable extends Table {
  @override
  final String tableName;

  RawTable(this.tableName);
}

RawTable rawTable(String name) => RawTable(name);

// ── Legacy / convenience names ────────────────────────────────────────────

/// Convenience for migration helpers that want a [RawTable]. Equivalent to
/// [rawTable] — the dialect comes from the connector you pass the schema to.
RawTable sqliteTable(String name) => RawTable(name);
RawTable pgTable(String name) => RawTable(name);
RawTable mysqlTable(String name) => RawTable(name);

// ── Supported types per dialect ───────────────────────────────────────────

const List<String> _supportedSqliteTypes = [
  'INTEGER',
  'TEXT',
  'REAL',
  'BLOB',
  'DATETIME',
  'NUMERIC',
];

const List<String> _supportedMysqlTypes = [
  'SERIAL',
  'VARCHAR',
  'INTEGER',
  'TEXT',
  'UUID',
  'REAL',
  'BLOB',
  'TINYINT',
  'SMALLINT',
  'BIGINT',
  'MEDIUMINT',
  'DECIMAL',
  'DOUBLE',
  'FLOAT',
  'BINARY',
  'VARBINARY',
  'CHAR',
  'BOOLEAN',
  'DATE',
  'DATETIME',
  'TIME',
  'YEAR',
  'ENUM',
];

const List<String> _supportedPostgresTypes = [
  'SMALLINT',
  'INTEGER',
  'BIGINT',
  'DECIMAL',
  'NUMERIC',
  'REAL',
  'DOUBLE PRECISION',
  'DOUBLE',
  'SERIAL',
  'SMALLSERIAL',
  'BIGSERIAL',
  'MONEY',
  'VARCHAR',
  'CHAR',
  'TEXT',
  'UUID',
  'BOOLEAN',
  'DATE',
  'TIME',
  'TIMESTAMP',
  'TIMESTAMPTZ',
  'INTERVAL',
  'BYTEA',
  'JSON',
  'JSONB',
  'INET',
  'CIDR',
  'MACADDR',
  'BIT',
  'VARBIT',
  'TSVECTOR',
  'TSQUERY',
  'XML',
  'ENUM',
  'POINT',
];
