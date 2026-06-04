import 'dart:async';

import 'package:uuid/uuid.dart';

import '../drivers/driver.dart';
import '../types/column.dart';
import '../types/column_ref.dart';
import '../types/cte.dart';
import '../types/database_error.dart';
import '../types/row.dart';
import '../types/table.dart';
import 'condition.dart';

/// Ordering direction. Use with [QueryBuilder.orderBy].
enum Order { asc, desc }

extension OrderSql on Order {
  String get sql => this == Order.asc ? 'ASC' : 'DESC';
}

/// Internal query type discriminator.
enum _QueryType { select, insert, update, delete, createTable, dropTable, alter }

/// Fluent query builder. Returned by `db.select`, `db.insert`, `db.update`
/// and `db.delete`. Implements [Future<List<RowMap>>] so you can `await` it
/// directly to get decoded rows — but for non-SELECT statements you usually
/// want [execute] for an affected-row count.
///
/// ```dart
/// final users = await db.select(usersTable).where(eq(usersTable.id, 1));
///
/// await db.insert(usersTable).values([
///   usersTable.email.value('a@b.com'),
///   usersTable.username.value('alice'),
/// ]);
/// ```
class QueryBuilder implements Future<List<RowMap>> {
  final DatabaseDriver _driver;
  final CommonTableExpression? _cte;
  final Dialect _dialect;
  _QueryType? _type;

  Table? _table;
  String? _rawTableName; // used only for legacy raw string paths
  List<_ProjectionEntry> _projection = const [];
  final List<String> _whereClauses = [];
  final List<String> _havingClauses = [];
  final List<String> _orderByClauses = [];
  final List<String> _joinClauses = [];
  final List<String> _groupByClauses = [];
  final List<String> _unionQueries = [];
  final List<Object?> _parameters = [];

  int? _limit;
  int? _offset;

  // INSERT / UPDATE state
  Map<String, Object?> _insertData = {};
  List<Map<String, Object?>> _insertRows = const [];
  List<String> _insertColumnOrder = const [];
  Map<String, Object?> _updateData = {};

  // RETURNING
  String? _returningClause;

  // DDL state
  String? _createTableSql;
  final List<String> _alterCommands = [];

  QueryBuilder(this._driver, this._cte, {Dialect dialect = Dialect.sqlite})
      : _dialect = dialect;

  // ── Identifier helpers ──────────────────────────────────────────────────

  String _escapeIdentifier(String identifier) {
    if (identifier.contains('(')) return identifier;
    if (identifier.contains('.')) {
      return identifier.split('.').map((p) => '"$p"').join('.');
    }
    return '"$identifier"';
  }

  String _tableSql(Table t) => '"${t.tableName}"';

  // ── SELECT ──────────────────────────────────────────────────────────────

  /// Begins a SELECT.
  ///
  /// - `db.select()` emits `SELECT *` — chain `.from(table)` afterwards.
  /// - `db.select([col1, col2])` emits explicit columns.
  /// - `db.select({'alias': col1, 'total': sum(col2)})` emits aliased
  ///   columns / expressions (Drizzle-style).
  QueryBuilder select([Object? projection]) {
    _type = _QueryType.select;
    if (projection == null) {
      _projection = const [];
      return this;
    }
    if (projection is List) {
      _projection = projection.map(_projectionFromValue).toList();
      return this;
    }
    if (projection is Map) {
      _projection = projection.entries
          .map((e) => _projectionFromValue(e.value, alias: e.key.toString()))
          .toList();
      return this;
    }
    throw QueryBuildError(
      'select() expects null, a List of columns/expressions, or a '
      'Map<String, ColumnRef | SqlExpression>; got ${projection.runtimeType}',
    );
  }

  /// Sets the FROM table.
  QueryBuilder from(Table table) {
    _table = table;
    return this;
  }

  /// Sets the FROM target by raw table name. Reserved for migrations and ad
  /// hoc queries that don't have a typed [Table].
  QueryBuilder fromRaw(String tableName) {
    _rawTableName = tableName;
    return this;
  }

  _ProjectionEntry _projectionFromValue(Object? value, {String? alias}) {
    if (value is ColumnRef) {
      final fallbackAlias = value.table.isEmpty
          ? value.column
          : '${value.table}__${value.column}';
      return _ProjectionEntry(
        value.toSqlIdentifier(),
        alias ?? fallbackAlias,
        value as ColumnRef<Object?>,
      );
    }
    if (value is SqlExpression) {
      return _ProjectionEntry(value.sql, alias);
    }
    if (value == null) {
      throw QueryBuildError('null is not a valid projection entry');
    }
    return _ProjectionEntry(_escapeIdentifier(value.toString()), alias);
  }

  // ── WHERE / HAVING ──────────────────────────────────────────────────────

  QueryBuilder where(Condition condition) {
    _whereClauses.add(condition.clause);
    _parameters.addAll(condition.values);
    return this;
  }

  QueryBuilder having(Condition condition) {
    _havingClauses.add(condition.clause);
    _parameters.addAll(condition.values);
    return this;
  }

  // ── ORDER / GROUP / LIMIT ───────────────────────────────────────────────

  QueryBuilder orderBy<T>(ColumnRef<T> col, [Order order = Order.asc]) {
    _orderByClauses.add('${col.toSqlIdentifier()} ${order.sql}');
    return this;
  }

  QueryBuilder orderByExpression(SqlExpression expr,
      [Order order = Order.asc]) {
    _orderByClauses.add('${expr.sql} ${order.sql}');
    return this;
  }

  QueryBuilder groupBy(List<ColumnRef<Object?>> cols) {
    _groupByClauses
        .addAll(cols.map((c) => c.toSqlIdentifier()).toList());
    return this;
  }

  QueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  QueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  // ── JOINs ───────────────────────────────────────────────────────────────

  QueryBuilder innerJoin(Table table, Condition on) =>
      _addJoin('INNER JOIN', table, on);

  QueryBuilder leftJoin(Table table, Condition on) =>
      _addJoin('LEFT JOIN', table, on);

  QueryBuilder rightJoin(Table table, Condition on) =>
      _addJoin('RIGHT JOIN', table, on);

  QueryBuilder fullJoin(Table table, Condition on) =>
      _addJoin('FULL JOIN', table, on);

  QueryBuilder _addJoin(String keyword, Table table, Condition on) {
    _joinClauses.add('$keyword ${_tableSql(table)} ON ${on.clause}');
    _parameters.addAll(on.values);
    return this;
  }

  // ── UNION ───────────────────────────────────────────────────────────────

  QueryBuilder union(QueryBuilder other) {
    _unionQueries.add(other.toSql());
    return this;
  }

  // ── INSERT ──────────────────────────────────────────────────────────────

  QueryBuilder insert(Table table) {
    _type = _QueryType.insert;
    _table = table;
    return this;
  }

  /// Typed values for INSERT. Pairs columns with statically-checked values.
  QueryBuilder values(List<ColumnValue<Object?>> values) {
    if (_type != _QueryType.insert) {
      throw QueryBuildError('values() can only be used with insert()');
    }
    if (values.isEmpty) throw ValidationError('values cannot be empty');
    _parameters.clear();
    _insertData = {};
    final data = <String, Object?>{};
    for (final cv in values) {
      data[cv.column.column] = cv.encoded;
    }

    // Fill in UUID auto-generate columns
    if (_table != null) {
      for (final col in _table!.columns) {
        if (col.isAutoGenerate && !data.containsKey(col.column)) {
          data[col.column] = const Uuid().v4();
        }
      }
    }

    _insertData = data;
    _parameters.addAll(data.values);
    return this;
  }

  /// Inserts multiple rows in one statement. Every row must have the same
  /// column set; otherwise an error is thrown at build time.
  ///
  /// ```dart
  /// await db.insert(users).valuesMany([
  ///   [users.email.value('a@b.com'), users.name.value('alice')],
  ///   [users.email.value('c@d.com'), users.name.value('bob')],
  ///   [users.email.value('e@f.com'), users.name.value('carol')],
  /// ]);
  /// ```
  QueryBuilder valuesMany(List<List<ColumnValue<Object?>>> rows) {
    if (_type != _QueryType.insert) {
      throw QueryBuildError('valuesMany() can only be used with insert()');
    }
    if (rows.isEmpty) throw ValidationError('rows cannot be empty');
    if (rows.first.isEmpty) throw ValidationError('rows cannot contain empty rows');

    _parameters.clear();

    final columnOrder = rows.first.map((cv) => cv.column.column).toList();
    final columnSet = columnOrder.toSet();

    // Add UUID auto-generate columns to the schema if not already present.
    final uuidCols = <String>[];
    if (_table != null) {
      for (final col in _table!.columns) {
        if (col.isAutoGenerate && !columnSet.contains(col.column)) {
          columnOrder.add(col.column);
          columnSet.add(col.column);
          uuidCols.add(col.column);
        }
      }
    }

    final encodedRows = <Map<String, Object?>>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final encoded = <String, Object?>{};
      for (final cv in row) {
        encoded[cv.column.column] = cv.encoded;
      }
      for (final uuidCol in uuidCols) {
        encoded[uuidCol] ??= const Uuid().v4();
      }
      final rowSet = encoded.keys.toSet();
      if (rowSet.length != columnSet.length ||
          !rowSet.containsAll(columnSet)) {
        throw ValidationError(
          'valuesMany() row #$i has columns {${rowSet.join(', ')}}, '
          'expected {${columnSet.join(', ')}}',
        );
      }
      encodedRows.add(encoded);
    }

    _insertRows = encodedRows;
    _insertColumnOrder = columnOrder;
    // Flatten parameters in (column-order × row-order) order:
    for (final row in encodedRows) {
      for (final col in columnOrder) {
        _parameters.add(row[col]);
      }
    }
    // Build _insertData just so single-row toSql() still has correct column
    // names if it inspects this state for any reason.
    _insertData = {for (final c in columnOrder) c: null};
    return this;
  }

  /// Raw map-based insert. Useful for migrations and dynamic forms.
  /// Strongly prefer [values] in application code.
  QueryBuilder valuesRaw(Map<String, Object?> data) {
    if (_type != _QueryType.insert) {
      throw QueryBuildError('valuesRaw() can only be used with insert()');
    }
    if (data.isEmpty) throw ValidationError('data cannot be empty');
    _parameters.clear();
    final encoded = <String, Object?>{};
    for (final entry in data.entries) {
      final col = _table?.columnByName(entry.key);
      encoded[entry.key] = col?.encode(entry.value) ?? entry.value;
    }
    if (_table != null) {
      for (final col in _table!.columns) {
        if (col.isAutoGenerate && !encoded.containsKey(col.column)) {
          encoded[col.column] = const Uuid().v4();
        }
      }
    }
    _insertData = encoded;
    _parameters.addAll(encoded.values);
    return this;
  }

  // ── ON CONFLICT (upsert) ────────────────────────────────────────────────

  String? _conflictClause;
  final List<Object?> _conflictParams = [];

  /// `INSERT … ON CONFLICT DO NOTHING`. On MySQL it becomes
  /// `INSERT IGNORE` semantics via `ON DUPLICATE KEY UPDATE id = id`
  /// (no-op).
  QueryBuilder onConflictDoNothing(
      {List<ColumnRef<Object?>> target = const []}) {
    if (_type != _QueryType.insert) {
      throw QueryBuildError(
          'onConflictDoNothing() only valid after insert()');
    }
    if (_dialect == Dialect.mysql) {
      // MySQL has no DO NOTHING — emulate by assigning a column to itself.
      final keyCol = target.isNotEmpty
          ? target.first.column
          : (_insertData.keys.isNotEmpty
              ? _insertData.keys.first
              : _insertColumnOrder.first);
      _conflictClause = 'ON DUPLICATE KEY UPDATE "$keyCol" = "$keyCol"';
      return this;
    }
    final targetSql = target.isEmpty
        ? ''
        : ' (${target.map((c) => '"${c.column}"').join(', ')})';
    _conflictClause = 'ON CONFLICT$targetSql DO NOTHING';
    return this;
  }

  /// `INSERT … ON CONFLICT (target) DO UPDATE SET …` (Postgres / SQLite)
  /// or `… ON DUPLICATE KEY UPDATE …` (MySQL).
  ///
  /// ```dart
  /// await db.insert(users).values([
  ///   users.email.value('a@b.com'),
  ///   users.name.value('alice'),
  /// ]).onConflictDoUpdate(
  ///   target: [users.email],
  ///   set:    [users.name.value('alice_updated')],
  /// );
  /// ```
  QueryBuilder onConflictDoUpdate({
    required List<ColumnRef<Object?>> target,
    required List<ColumnValue<Object?>> set,
  }) {
    if (_type != _QueryType.insert) {
      throw QueryBuildError(
          'onConflictDoUpdate() only valid after insert()');
    }
    if (target.isEmpty) {
      throw ValidationError('onConflictDoUpdate(target: ...) cannot be empty');
    }
    if (set.isEmpty) {
      throw ValidationError('onConflictDoUpdate(set: ...) cannot be empty');
    }
    _conflictParams.clear();
    if (_dialect == Dialect.mysql) {
      // MySQL ignores `target` — uses any unique/primary key automatically.
      final setSql =
          set.map((cv) => '"${cv.column.column}" = ?').join(', ');
      _conflictClause = 'ON DUPLICATE KEY UPDATE $setSql';
      _conflictParams.addAll(set.map((cv) => cv.encoded));
      return this;
    }
    final targetSql = target.map((c) => '"${c.column}"').join(', ');
    final setSql =
        set.map((cv) => '"${cv.column.column}" = ?').join(', ');
    _conflictClause = 'ON CONFLICT ($targetSql) DO UPDATE SET $setSql';
    _conflictParams.addAll(set.map((cv) => cv.encoded));
    return this;
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────

  QueryBuilder update(Table table) {
    _type = _QueryType.update;
    _table = table;
    return this;
  }

  /// Typed `SET` clause for UPDATE.
  QueryBuilder set(List<ColumnValue<Object?>> values) {
    if (_type != _QueryType.update) {
      throw QueryBuildError('set() can only be used with update()');
    }
    if (values.isEmpty) throw ValidationError('set values cannot be empty');
    _updateData = {};
    for (final cv in values) {
      _updateData[cv.column.column] = cv.encoded;
    }
    _parameters.addAll(_updateData.values);
    return this;
  }

  /// Raw map-based set. Prefer [set] for type-checked updates.
  QueryBuilder setRaw(Map<String, Object?> data) {
    if (_type != _QueryType.update) {
      throw QueryBuildError('setRaw() can only be used with update()');
    }
    _updateData = {};
    for (final entry in data.entries) {
      final col = _table?.columnByName(entry.key);
      _updateData[entry.key] = col?.encode(entry.value) ?? entry.value;
    }
    _parameters.addAll(_updateData.values);
    return this;
  }

  // ── DELETE ──────────────────────────────────────────────────────────────

  QueryBuilder delete(Table table) {
    _type = _QueryType.delete;
    _table = table;
    return this;
  }

  // ── RETURNING ───────────────────────────────────────────────────────────

  QueryBuilder returning([List<ColumnRef<Object?>>? cols]) {
    if (cols == null || cols.isEmpty) {
      _returningClause = 'RETURNING *';
    } else {
      _returningClause =
          'RETURNING ${cols.map((c) => c.toSqlIdentifier()).join(', ')}';
    }
    return this;
  }

  QueryBuilder returningId() {
    _returningClause = 'RETURNING id';
    return this;
  }

  // ── DDL ─────────────────────────────────────────────────────────────────

  QueryBuilder createTable(String table, Map<String, String> columns) {
    _type = _QueryType.createTable;
    _createTableSql =
        'CREATE TABLE IF NOT EXISTS ${_escapeIdentifier(table)} '
        '(${columns.entries.map((e) => '${e.key} ${e.value}').join(', ')})';
    return this;
  }

  QueryBuilder dropTable(String table) {
    _type = _QueryType.dropTable;
    _rawTableName = table;
    return this;
  }

  QueryBuilder addColumn(String columnName, String columnType) {
    _type = _QueryType.alter;
    _alterCommands
        .add('ADD COLUMN ${_escapeIdentifier(columnName)} $columnType');
    return this;
  }

  QueryBuilder dropColumn(String columnName) {
    _type = _QueryType.alter;
    _alterCommands.add('DROP COLUMN ${_escapeIdentifier(columnName)}');
    return this;
  }

  // ── SQL emission ────────────────────────────────────────────────────────

  String toSql() {
    final tableName = _table?.tableName ?? _rawTableName ?? '';
    final tableEscaped = _escapeIdentifier(tableName);

    var sql = '';

    final cte = _cte;
    if (cte != null) {
      final cteSql = cte.query.toSql().trim().replaceAll(';', '');
      sql += 'WITH "${cte.name}" AS ($cteSql) ';
    }

    switch (_type) {
      case _QueryType.select:
        if (tableName.isEmpty) {
          throw QueryBuildError(
              'SELECT requires a FROM table — call .from(table) before awaiting.');
        }
        final cols = _projection.isEmpty
            ? '*'
            : _projection.map((p) => p.toSql()).join(', ');
        sql += 'SELECT $cols FROM $tableEscaped';
        if (_joinClauses.isNotEmpty) sql += ' ${_joinClauses.join(' ')}';
        if (_whereClauses.isNotEmpty) {
          sql += ' WHERE ${_whereClauses.join(' AND ')}';
        }
        if (_groupByClauses.isNotEmpty) {
          sql += ' GROUP BY ${_groupByClauses.join(', ')}';
        }
        if (_havingClauses.isNotEmpty) {
          sql += ' HAVING ${_havingClauses.join(' AND ')}';
        }
        if (_orderByClauses.isNotEmpty) {
          sql += ' ORDER BY ${_orderByClauses.join(', ')}';
        }
        if (_limit != null) sql += ' LIMIT $_limit';
        if (_offset != null) sql += ' OFFSET $_offset';
        if (_unionQueries.isNotEmpty) {
          sql += ' UNION ${_unionQueries.join(' UNION ')}';
        }
        return '$sql;';
      case _QueryType.insert:
        if (_insertRows.isNotEmpty) {
          // Batch insert: column order is fixed by _insertColumnOrder.
          final cols = _insertColumnOrder.map(_escapeIdentifier).join(', ');
          final rowPh = List.filled(_insertColumnOrder.length, '?').join(', ');
          final groups =
              List.filled(_insertRows.length, '($rowPh)').join(', ');
          var s = 'INSERT INTO $tableEscaped ($cols) VALUES $groups';
          if (_conflictClause != null) s += ' $_conflictClause';
          if (_returningClause != null) s += ' $_returningClause';
          return '$s;';
        }
        final cols = _insertData.keys.map(_escapeIdentifier).join(', ');
        final placeholders = List.filled(_insertData.length, '?').join(', ');
        var s = 'INSERT INTO $tableEscaped ($cols) VALUES ($placeholders)';
        if (_conflictClause != null) s += ' $_conflictClause';
        if (_returningClause != null) s += ' $_returningClause';
        return '$s;';
      case _QueryType.update:
        final setClause = _updateData.keys
            .map((k) => '${_escapeIdentifier(k)} = ?')
            .join(', ');
        var s = 'UPDATE $tableEscaped SET $setClause';
        if (_whereClauses.isNotEmpty) {
          s += ' WHERE ${_whereClauses.join(' AND ')}';
        }
        if (_returningClause != null) s += ' $_returningClause';
        return '$s;';
      case _QueryType.delete:
        var s = 'DELETE FROM $tableEscaped';
        if (_whereClauses.isNotEmpty) {
          s += ' WHERE ${_whereClauses.join(' AND ')}';
        }
        if (_returningClause != null) s += ' $_returningClause';
        return '$s;';
      case _QueryType.createTable:
        return '${_createTableSql!};';
      case _QueryType.dropTable:
        return 'DROP TABLE IF EXISTS $tableEscaped;';
      case _QueryType.alter:
        return 'ALTER TABLE $tableEscaped ${_alterCommands.join(', ')};';
      case null:
        throw QueryBuildError('No operation was defined');
    }
  }

  /// Returns the positional parameters bound by [toSql], including any CTE
  /// parameters (placed first, matching their position in the emitted SQL)
  /// and ON CONFLICT DO UPDATE binders (placed last).
  List<Object?> getParameters() => List.unmodifiable([
        ...?_cte?.query.getParameters(),
        ..._parameters,
        ..._conflictParams,
      ]);

  // ── Execution ───────────────────────────────────────────────────────────

  Future<List<RowMap>> _runSelect() async {
    final sql = toSql();
    final result = await _driver.execute(sql, getParameters());

    // Map each projected ColumnRef to the SQL alias it was emitted under, so
    // `row.read(col)` resolves the right cell even for aliased projections
    // (e.g. `select({'author': users.name})`).
    final columnAliases = <ColumnRef<Object?>, String>{};
    for (final p in _projection) {
      final ref = p.sourceColumn;
      if (ref != null && p.alias != null) {
        columnAliases[ref] = p.alias!;
      }
    }

    return result.map((raw) => RowMap(raw, columnAliases)).toList();
  }

  /// Returns the first row from a SELECT, or null when empty. Adds
  /// `LIMIT 1` if no limit was set.
  Future<RowMap?> first() async {
    if (_type != _QueryType.select) {
      throw QueryBuildError('first() can only be used after select()');
    }
    _limit ??= 1;
    final rows = await _runSelect();
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns SELECT rows decoded into [R] via [decoder].
  ///
  /// ```dart
  /// final users = await db.select().from(usersTable).rows<User>(
  ///   (r) => User(id: r.readNotNull(usersTable.id),
  ///                email: r.readNotNull(usersTable.email)),
  /// );
  /// ```
  Future<List<R>> rows<R>(R Function(RowMap row) decoder) async {
    if (_type != _QueryType.select) {
      throw QueryBuildError('rows() can only be used after select()');
    }
    final result = await _runSelect();
    return result.map(decoder).toList();
  }

  // ── Future implementation ───────────────────────────────────────────────
  //
  // The builder *is* a Future — `await db.insert(...).values([...])` just
  // works. For SELECT, the awaited result is the decoded rows. For
  // INSERT/UPDATE/DELETE with `.returning(...)`, it's the returned rows. For
  // plain non-SELECT statements, the awaited result is an empty list.
  //
  // For typed select-result decoding use [rows]. For a single row use
  // [first]. Otherwise just `await` the builder — no `.all()` or
  // `.execute()` needed; the Future implementation handles dispatch
  // internally.

  Future<List<RowMap>> _internalFuture() async {
    try {
      if (_type == _QueryType.select) return _runSelect();
      final sql = toSql();
      final params = getParameters();
      if (_returningClause != null) {
        final res = await _driver.execute(sql, params);
        return res.map((raw) => RowMap(raw)).toList();
      }
      await _driver.raw(sql, params);
      return const [];
    } catch (e) {
      if (e is DatabaseError) rethrow;
      throw QueryBuildError('Unexpected error during query execution', e);
    }
  }

  @override
  Future<S> then<S>(FutureOr<S> Function(List<RowMap> value) onValue,
          {Function? onError}) =>
      _internalFuture().then(onValue, onError: onError);

  @override
  Future<List<RowMap>> catchError(Function onError,
          {bool Function(Object error)? test}) =>
      _internalFuture().catchError(onError, test: test);

  @override
  Future<List<RowMap>> whenComplete(FutureOr<void> Function() action) =>
      _internalFuture().whenComplete(action);

  @override
  Stream<List<RowMap>> asStream() => Stream.fromFuture(_internalFuture());

  @override
  Future<List<RowMap>> timeout(Duration timeLimit,
          {FutureOr<List<RowMap>> Function()? onTimeout}) =>
      _internalFuture().timeout(timeLimit, onTimeout: onTimeout);
}

/// One projected column or expression in a SELECT.
class _ProjectionEntry {
  /// The SQL fragment (e.g. `"users"."id"`, `COUNT(*)`, `SUM("amount")`).
  final String sqlFragment;

  /// Optional alias.
  final String? alias;

  /// The source column ref, when projection came from a [ColumnRef]. Lets
  /// the runtime build an alias → column index for fast decoding.
  final ColumnRef<Object?>? sourceColumn;

  _ProjectionEntry(this.sqlFragment, this.alias, [this.sourceColumn]);

  String toSql() {
    if (alias == null || alias!.isEmpty) return sqlFragment;
    return '$sqlFragment AS "$alias"';
  }
}
