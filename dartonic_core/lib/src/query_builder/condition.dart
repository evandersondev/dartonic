import '../types/column_ref.dart';
import 'query_builder.dart';

/// A boolean SQL fragment with positional parameters. Built via the helpers
/// in this file ([eq], [gt], [and], etc.) and consumed by [QueryBuilder].
class Condition {
  final String clause;
  final List<Object?> values;
  const Condition(this.clause, [this.values = const []]);
}

// ── Equality / inequality ─────────────────────────────────────────────────

/// `col = ?` with the value typed by the column.
Condition eq<T>(ColumnRef<T> col, T value) =>
    Condition('${col.toSqlIdentifier()} = ?', [col.encode(value)]);

/// `a = b` for two columns of the same type.
Condition eqCol<T>(ColumnRef<T> a, ColumnRef<T> b) =>
    Condition('${a.toSqlIdentifier()} = ${b.toSqlIdentifier()}');

Condition ne<T>(ColumnRef<T> col, T value) =>
    Condition('${col.toSqlIdentifier()} <> ?', [col.encode(value)]);

Condition neCol<T>(ColumnRef<T> a, ColumnRef<T> b) =>
    Condition('${a.toSqlIdentifier()} <> ${b.toSqlIdentifier()}');

// ── Ordering ──────────────────────────────────────────────────────────────

Condition gt<T extends Comparable<Object?>>(ColumnRef<T> col, T value) =>
    Condition('${col.toSqlIdentifier()} > ?', [col.encode(value)]);

Condition gte<T extends Comparable<Object?>>(ColumnRef<T> col, T value) =>
    Condition('${col.toSqlIdentifier()} >= ?', [col.encode(value)]);

Condition lt<T extends Comparable<Object?>>(ColumnRef<T> col, T value) =>
    Condition('${col.toSqlIdentifier()} < ?', [col.encode(value)]);

Condition lte<T extends Comparable<Object?>>(ColumnRef<T> col, T value) =>
    Condition('${col.toSqlIdentifier()} <= ?', [col.encode(value)]);

// ── Null checks ───────────────────────────────────────────────────────────

Condition isNull<T>(ColumnRef<T> col) =>
    Condition('${col.toSqlIdentifier()} IS NULL');

Condition isNotNull<T>(ColumnRef<T> col) =>
    Condition('${col.toSqlIdentifier()} IS NOT NULL');

// ── Membership / range ────────────────────────────────────────────────────

Condition inArray<T>(ColumnRef<T> col, List<T> values) {
  if (values.isEmpty) {
    // SQL `IN ()` is invalid; emit an always-false clause instead.
    return const Condition('1 = 0');
  }
  final placeholders = List.filled(values.length, '?').join(', ');
  return Condition('${col.toSqlIdentifier()} IN ($placeholders)',
      values.map(col.encode).toList());
}

Condition notInArray<T>(ColumnRef<T> col, List<T> values) {
  if (values.isEmpty) return const Condition('1 = 1');
  final placeholders = List.filled(values.length, '?').join(', ');
  return Condition('${col.toSqlIdentifier()} NOT IN ($placeholders)',
      values.map(col.encode).toList());
}

Condition between<T extends Comparable<Object?>>(
        ColumnRef<T> col, T start, T end) =>
    Condition('${col.toSqlIdentifier()} BETWEEN ? AND ?',
        [col.encode(start), col.encode(end)]);

Condition notBetween<T extends Comparable<Object?>>(
        ColumnRef<T> col, T start, T end) =>
    Condition('${col.toSqlIdentifier()} NOT BETWEEN ? AND ?',
        [col.encode(start), col.encode(end)]);

// ── Pattern matching (text only) ──────────────────────────────────────────

Condition like(ColumnRef<String> col, String pattern) =>
    Condition('${col.toSqlIdentifier()} LIKE ?', [pattern]);

Condition ilike(ColumnRef<String> col, String pattern) =>
    Condition('${col.toSqlIdentifier()} ILIKE ?', [pattern]);

Condition notIlike(ColumnRef<String> col, String pattern) =>
    Condition('${col.toSqlIdentifier()} NOT ILIKE ?', [pattern]);

// ── Subqueries ────────────────────────────────────────────────────────────

Condition exists(QueryBuilder subquery) {
  var sql = subquery.toSql().trim();
  if (sql.endsWith(';')) sql = sql.substring(0, sql.length - 1);
  return Condition('EXISTS ($sql)', subquery.getParameters());
}

Condition notExists(QueryBuilder subquery) {
  var sql = subquery.toSql().trim();
  if (sql.endsWith(';')) sql = sql.substring(0, sql.length - 1);
  return Condition('NOT EXISTS ($sql)', subquery.getParameters());
}

// ── Boolean composition ───────────────────────────────────────────────────

Condition not(Condition c) => Condition('NOT (${c.clause})', c.values);

Condition and(List<Condition> conditions) {
  if (conditions.isEmpty) return const Condition('1 = 1');
  final clauses = conditions.map((c) => c.clause).join(' AND ');
  final values = conditions.expand((c) => c.values).toList();
  return Condition('($clauses)', values);
}

Condition or(List<Condition> conditions) {
  if (conditions.isEmpty) return const Condition('1 = 0');
  final clauses = conditions.map((c) => c.clause).join(' OR ');
  final values = conditions.expand((c) => c.values).toList();
  return Condition('($clauses)', values);
}

// ── SQL literal inlining ──────────────────────────────────────────────────
//
// Some SQL contexts (partial-index WHERE, CREATE VIEW, CTE bodies executed
// as raw text) don't accept bind parameters. [inlineLiterals] takes a SQL
// fragment with `?` placeholders and a parallel value list, and returns
// the same fragment with each `?` replaced by a SQL literal rendering of
// the corresponding value.
//
// Supported value types: null, bool, num, DateTime (rendered as ISO-8601
// UTC string), and anything else via `toString()`. Single quotes in
// strings are escaped by doubling.

String inlineLiterals(String sqlWithPlaceholders, List<Object?> values) {
  if (values.isEmpty) return sqlWithPlaceholders;
  var i = 0;
  return sqlWithPlaceholders.replaceAllMapped(RegExp(r'\?'), (_) {
    if (i >= values.length) {
      throw StateError('Placeholder count exceeds values length');
    }
    return _sqlLiteral(values[i++]);
  });
}

String _sqlLiteral(Object? v) {
  if (v == null) return 'NULL';
  if (v is bool) return v ? '1' : '0';
  if (v is num) return '$v';
  if (v is DateTime) return "'${v.toUtc().toIso8601String()}'";
  final s = v.toString().replaceAll("'", "''");
  return "'$s'";
}

// ── Aggregate expressions ─────────────────────────────────────────────────
//
// These return [SqlExpression] objects rather than [ColumnRef] so they can be
// used in projections.

class SqlExpression {
  final String sql;
  const SqlExpression(this.sql);
  @override
  String toString() => sql;
}

SqlExpression countAll() => const SqlExpression('COUNT(*)');

SqlExpression count<T>(ColumnRef<T> col, {bool distinct = false}) =>
    SqlExpression(distinct
        ? 'COUNT(DISTINCT ${col.toSqlIdentifier()})'
        : 'COUNT(${col.toSqlIdentifier()})');

SqlExpression sum<T extends num>(ColumnRef<T> col) =>
    SqlExpression('SUM(${col.toSqlIdentifier()})');

SqlExpression avg<T extends num>(ColumnRef<T> col) =>
    SqlExpression('AVG(${col.toSqlIdentifier()})');

SqlExpression max<T extends Comparable<Object?>>(ColumnRef<T> col) =>
    SqlExpression('MAX(${col.toSqlIdentifier()})');

SqlExpression min<T extends Comparable<Object?>>(ColumnRef<T> col) =>
    SqlExpression('MIN(${col.toSqlIdentifier()})');

// ── HAVING with aggregate expressions ─────────────────────────────────────
//
// `gt`/`lt`/… take a [ColumnRef]; for HAVING you usually compare an
// aggregate (`sum`, `avg`, etc.). These `*Expr` variants accept a
// [SqlExpression] on the left-hand side.

Condition eqExpr(SqlExpression expr, Object? value) =>
    Condition('${expr.sql} = ?', [value]);
Condition neExpr(SqlExpression expr, Object? value) =>
    Condition('${expr.sql} <> ?', [value]);
Condition gtExpr(SqlExpression expr, Object? value) =>
    Condition('${expr.sql} > ?', [value]);
Condition gteExpr(SqlExpression expr, Object? value) =>
    Condition('${expr.sql} >= ?', [value]);
Condition ltExpr(SqlExpression expr, Object? value) =>
    Condition('${expr.sql} < ?', [value]);
Condition lteExpr(SqlExpression expr, Object? value) =>
    Condition('${expr.sql} <= ?', [value]);

// ── Subquery comparisons ──────────────────────────────────────────────────
//
// Each takes a [ColumnRef<T>] on the left and a [QueryBuilder] returning a
// single column of the same [T] on the right.

String _subquerySql(QueryBuilder subquery) {
  var sql = subquery.toSql().trim();
  if (sql.endsWith(';')) sql = sql.substring(0, sql.length - 1);
  return sql;
}

Condition eqSubquery<T>(ColumnRef<T> col, QueryBuilder subquery) =>
    Condition(
        '${col.toSqlIdentifier()} = (${_subquerySql(subquery)})',
        subquery.getParameters());

Condition neSubquery<T>(ColumnRef<T> col, QueryBuilder subquery) =>
    Condition(
        '${col.toSqlIdentifier()} <> (${_subquerySql(subquery)})',
        subquery.getParameters());

Condition gtSubquery<T extends Comparable<Object?>>(
        ColumnRef<T> col, QueryBuilder subquery) =>
    Condition(
        '${col.toSqlIdentifier()} > (${_subquerySql(subquery)})',
        subquery.getParameters());

Condition gteSubquery<T extends Comparable<Object?>>(
        ColumnRef<T> col, QueryBuilder subquery) =>
    Condition(
        '${col.toSqlIdentifier()} >= (${_subquerySql(subquery)})',
        subquery.getParameters());

Condition ltSubquery<T extends Comparable<Object?>>(
        ColumnRef<T> col, QueryBuilder subquery) =>
    Condition(
        '${col.toSqlIdentifier()} < (${_subquerySql(subquery)})',
        subquery.getParameters());

Condition lteSubquery<T extends Comparable<Object?>>(
        ColumnRef<T> col, QueryBuilder subquery) =>
    Condition(
        '${col.toSqlIdentifier()} <= (${_subquerySql(subquery)})',
        subquery.getParameters());

Condition inSubquery<T>(ColumnRef<T> col, QueryBuilder subquery) =>
    Condition(
        '${col.toSqlIdentifier()} IN (${_subquerySql(subquery)})',
        subquery.getParameters());

Condition notInSubquery<T>(ColumnRef<T> col, QueryBuilder subquery) =>
    Condition(
        '${col.toSqlIdentifier()} NOT IN (${_subquerySql(subquery)})',
        subquery.getParameters());
