import '../query_builder/condition.dart';
import '../query_builder/database_facade.dart';
import '../query_builder/query_builder.dart';
import '../types/column_ref.dart';
import '../types/row.dart';
import '../types/table.dart';

/// High-level convenience helpers around a typed [Table]. Each method maps to
/// the [QueryBuilder] underneath but yields decoded [RowMap]s.
///
/// ```dart
/// final users = db.orm(usersTable);
/// final alice = await users.findFirst(where: eq(usersTable.username, 'alice'));
/// final everyone = await users.findMany(orderBy: usersTable.createdAt);
/// ```
class OrmTable<T extends Table> {
  final T table;
  final Database _db;

  OrmTable(this.table, this._db);

  /// Returns multiple rows matching [where], optionally ordered/paginated.
  Future<List<RowMap>> findMany({
    Condition? where,
    int? offset,
    int? limit,
    ColumnRef<Object?>? orderBy,
    Order order = Order.asc,
  }) {
    var q = _db.select().from(table);
    if (where != null) q = q.where(where);
    if (orderBy != null) q = q.orderBy(orderBy, order);
    if (offset != null) q = q.offset(offset);
    if (limit != null) q = q.limit(limit);
    return q;
  }

  /// Alias for [findMany].
  Future<List<RowMap>> findAll({
    Condition? where,
    int? offset,
    int? limit,
    ColumnRef<Object?>? orderBy,
    Order order = Order.asc,
  }) =>
      findMany(
          where: where,
          offset: offset,
          limit: limit,
          orderBy: orderBy,
          order: order);

  /// Returns the first matching row, or null.
  Future<RowMap?> findFirst({Condition? where}) {
    var q = _db.select().from(table);
    if (where != null) q = q.where(where);
    return q.first();
  }

  /// Finds a single record by an ID column. Defaults to the column named
  /// `id` on the table — pass [idColumn] to use a different one.
  Future<RowMap?> findById<I>(I id, {ColumnRef<I>? idColumn}) {
    final col = idColumn ?? _idColumnFor<I>();
    return _db.select().from(table).where(eq(col, id)).first();
  }

  /// Convenience: maps every row through [decoder].
  Future<List<R>> mapMany<R>(
    R Function(RowMap row) decoder, {
    Condition? where,
    int? offset,
    int? limit,
    ColumnRef<Object?>? orderBy,
    Order order = Order.asc,
  }) async {
    final rows = await findMany(
        where: where,
        offset: offset,
        limit: limit,
        orderBy: orderBy,
        order: order);
    return rows.map(decoder).toList();
  }

  ColumnRef<I> _idColumnFor<I>() {
    final col = table.columnByName('id');
    if (col == null) {
      throw StateError(
          'Table "${table.tableName}" has no column named "id" — pass idColumn:');
    }
    return col as ColumnRef<I>;
  }
}
