import 'query_builder.dart';

class Condition {
  final String clause;
  final List<dynamic> values;
  Condition(this.clause, [List<dynamic>? values]) : values = values ?? [];
}

Condition eq(String left, dynamic right) {
  final isRightColumn =
      right is String && RegExp(r'^\w+\.\w+$').hasMatch(right);

  final leftExpr = _escapeIdentifier(left);
  final rightExpr =
      isRightColumn ? _escapeIdentifier(right) : _escapeValue(right);

  return Condition('$leftExpr = $rightExpr');
}

String _escapeIdentifier(String input) {
  return input.split('.').map((part) => '"$part"').join('.');
}

String _escapeValue(dynamic value) {
  if (value is String) {
    return "'${value.replaceAll("'", "''")}'";
  }
  return value.toString();
}

Condition ne(String column, dynamic value) {
  if (value is String && value.contains('.')) {
    return Condition("$column <> $value");
  }
  return Condition("$column <> ?", [value]);
}

Condition gt(String column, dynamic value) {
  return Condition("$column > ?", [value]);
}

Condition gte(String column, dynamic value) {
  return Condition("$column >= ?", [value]);
}

Condition lt(String column, dynamic value) {
  return Condition("$column < ?", [value]);
}

Condition lte(String column, dynamic value) {
  return Condition("$column <= ?", [value]);
}

Condition exists(QueryBuilder subquery) {
  String sql = subquery.toSql().trim();
  if (sql.endsWith(';')) sql = sql.substring(0, sql.length - 1);
  return Condition("EXISTS ($sql)");
}

Condition notExists(QueryBuilder subquery) {
  String sql = subquery.toSql().trim();
  if (sql.endsWith(';')) sql = sql.substring(0, sql.length - 1);
  return Condition("NOT EXISTS ($sql)");
}

Condition isNull(String column) => Condition("$column IS NULL");

Condition isNotNull(String column) => Condition("$column IS NOT NULL");

Condition inArray(String column, List<dynamic> values) {
  final placeholders = List.filled(values.length, '?').join(', ');
  return Condition("$column IN ($placeholders)", values);
}

String count(String columnName, {bool distinct = false}) {
  if (!distinct) {
    return "COUNT($columnName)";
  } else {
    return "COUNT(DISTINCT $columnName)";
  }
}

Condition notInArray(String column, List<dynamic> values) {
  final placeholders = List.filled(values.length, '?').join(', ');
  return Condition("$column NOT IN ($placeholders)", values);
}

Condition between(String column, dynamic start, dynamic end) {
  return Condition("$column BETWEEN ? AND ?", [start, end]);
}

Condition notBetween(String column, dynamic start, dynamic end) {
  return Condition("$column NOT BETWEEN ? AND ?", [start, end]);
}

Condition like(String column, String pattern) {
  return Condition("$column LIKE ?", [pattern]);
}

Condition ilike(String column, String pattern) {
  return Condition("$column ILIKE ?", [pattern]);
}

Condition notIlike(String column, String pattern) {
  return Condition("$column NOT ILIKE ?", [pattern]);
}

Condition not(Condition condition) {
  return Condition("NOT (${condition.clause})", condition.values);
}

Condition and(List<Condition> conditions) {
  final clauses = conditions.map((c) => c.clause).join(" AND ");
  final values = conditions.expand((c) => c.values).toList();
  return Condition("($clauses)", values);
}

Condition or(List<Condition> conditions) {
  final clauses = conditions.map((c) => c.clause).join(" OR ");
  final values = conditions.expand((c) => c.values).toList();
  return Condition("($clauses)", values);
}

class ReturningOptions {
  final bool insertedId;
  final bool updatedId;
  final bool deletedId;
  final List<String>? columns;

  ReturningOptions({
    this.insertedId = false,
    this.updatedId = false,
    this.deletedId = false,
    this.columns,
  });

  String build() {
    if (columns != null) {
      if (columns!.length == 1 && columns![0] == '*') return 'RETURNING *';
      return 'RETURNING ${columns!.map(_escapeIdentifier).join(', ')}';
    }

    final parts = <String>[];
    if (insertedId) parts.add('id AS inserted_id');
    if (updatedId) parts.add('id AS updated_id');
    if (deletedId) parts.add('id AS deleted_id');

    return parts.isNotEmpty ? 'RETURNING ${parts.join(', ')}' : '';
  }
}
