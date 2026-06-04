import 'column_ref.dart';

/// Typed wrapper over a driver result row. Each cell is decoded on demand
/// through the column's codec, so callers don't have to deal with raw
/// `Object?` values.
///
/// ```dart
/// final rows = await db.select().from(users);
/// for (final row in rows) {
///   final id    = row.read(users.id);    // int?
///   final email = row.read(users.email); // String?
/// }
/// ```
class RowMap {
  /// Raw driver row keyed by either the column name or `table.column`
  /// (filled by the query builder when projections include multiple tables).
  final Map<String, Object?> raw;

  /// Optional alias used when columns were aliased explicitly in the SELECT.
  /// When set, `read(col)` looks up the alias first before falling back to
  /// the column name and `table.column` key.
  final Map<ColumnRef<Object?>, String> aliases;

  const RowMap(this.raw, [this.aliases = const {}]);

  /// Decoded value for [col]. Returns null if the column is absent or NULL.
  T? read<T>(ColumnRef<T> col) {
    final keys = <String>[
      if (aliases[col as ColumnRef<Object?>] != null) aliases[col]!,
      if (col.table.isNotEmpty) '${col.table}.${col.column}',
      '${col.table}__${col.column}',
      col.column,
    ];
    for (final k in keys) {
      if (raw.containsKey(k)) return col.decode(raw[k]);
    }
    return null;
  }

  /// Same as [read] but throws if the value is null.
  T readNotNull<T>(ColumnRef<T> col) {
    final v = read(col);
    if (v == null) {
      throw StateError(
        'Column "${col.column}" on table "${col.table}" was null or missing',
      );
    }
    return v;
  }

  @override
  String toString() => 'RowMap($raw)';
}
