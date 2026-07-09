import '../query_builder/condition.dart';
import '../query_builder/database_facade.dart';
import '../query_builder/query_builder.dart';
import '../types/column_ref.dart';
import '../types/relation.dart';
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

  /// Declared relations for every registered table, keyed by table name.
  /// Supplied by [DartonicDb.orm]. Empty when the db was built without
  /// `relations: [...]`, in which case `findMany(with: ...)` throws.
  final Map<String, Map<String, RelationDefinition>> _relations;

  /// Resolver from a table name to its [Table] instance. Supplied by
  /// [DartonicDb.orm].
  final Table? Function(String name)? _tableResolver;

  OrmTable(
    this.table,
    this._db, {
    Map<String, Map<String, RelationDefinition>> relations = const {},
    Table? Function(String name)? tableResolver,
  })  : _relations = relations,
        _tableResolver = tableResolver;

  /// Returns multiple rows matching [where], optionally ordered/paginated.
  ///
  /// Pass [with_] to eager-load declared relations in a batched, N+1-free way.
  /// Each key is a relation name from this table's `relations(...)` metadata;
  /// the value `true` loads it. Because the loaded shape mixes the parent row
  /// with nested child lists/objects, the eager-loading path returns
  /// `List<Map<String, Object?>>` rather than typed [RowMap]s — see
  /// [findManyWithRelations].
  ///
  /// ```dart
  /// // Typed rows (no relations):
  /// final rows = await db.orm(users).findMany();
  ///
  /// // Eager-loaded (untyped maps with nested children):
  /// final withPosts = await db.orm(users).findManyWithRelations(
  ///   with_: {'posts': true},
  /// );
  /// // → [{'id': 1, 'name': 'Alice', 'posts': [ {...}, {...} ]}, ...]
  /// ```
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

  /// Eager-loads declared relations for the matched parent rows and returns
  /// each parent as a plain map with nested children keyed by relation name.
  ///
  /// This is the declarative equivalent of the imperative [findManyWith] /
  /// [findManyThrough] helpers on [Database], resolved through the table's
  /// `relations(...)` metadata. It is batched: one query for parents plus one
  /// query per requested relation (no N+1).
  ///
  /// **Type trade-off**: eager loading produces a heterogeneous, nested shape
  /// (parent scalar columns + `List<Map>` / `Map?` children), which does not
  /// fit the flat, typed [RowMap]. We therefore return `List<Map>`. Callers
  /// wanting fully-typed results should keep using the imperative
  /// [findManyWith] helpers, which preserve `WithChildren<P, C>`.
  ///
  /// Only relations that declare both `fields` (local columns) and
  /// `references` (target columns) are supported here; the loader needs those
  /// to know which columns to join on. Composite keys are not supported yet
  /// (only the first field/reference pair is used).
  Future<List<Map<String, Object?>>> findManyWithRelations({
    required Map<String, bool> with_,
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
      order: order,
    );
    final parents = rows.map((r) => Map<String, Object?>.from(r.raw)).toList();
    if (parents.isEmpty) return const [];

    final requested = with_.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (requested.isEmpty) return parents;

    final tableRelations = _relations[table.tableName];
    if (tableRelations == null) {
      throw StateError(
        'Table "${table.tableName}" has no declared relations. Register a '
        'relations(...) table via connect(relations: [...]) to use with_.',
      );
    }

    for (final relName in requested) {
      final def = tableRelations[relName];
      if (def == null) {
        throw ArgumentError(
          'Unknown relation "$relName" on table "${table.tableName}". '
          'Declared relations: ${tableRelations.keys.join(', ')}.',
        );
      }
      await _loadRelation(parents, relName, def);
    }
    return parents;
  }

  /// Loads one relation into [parents] in-place under key [relName].
  Future<void> _loadRelation(
    List<Map<String, Object?>> parents,
    String relName,
    RelationDefinition def,
  ) async {
    final fields = def.fields;
    final references = def.references;
    if (fields == null ||
        references == null ||
        fields.isEmpty ||
        references.isEmpty) {
      throw StateError(
        'Relation "$relName" on "${table.tableName}" must declare both '
        '`fields` and `references` to be eager-loaded declaratively.',
      );
    }
    final localCol = fields.first;
    final targetCol = references.first;

    final targetTable = _tableResolver?.call(def.target);
    if (targetTable == null) {
      throw StateError(
        'Relation "$relName" targets unknown table "${def.target}". '
        'Ensure it is registered in schemas/relations.',
      );
    }
    final targetColRef = targetTable.columnByName(targetCol);
    if (targetColRef == null) {
      throw StateError(
        'Relation "$relName" references column "$targetCol" which does not '
        'exist on "${def.target}".',
      );
    }

    // Gather the distinct local key values from the parents.
    final keys = <Object?>{};
    for (final p in parents) {
      final k = p[localCol];
      if (k != null) keys.add(k);
    }
    if (keys.isEmpty) {
      for (final p in parents) {
        p[relName] = def.type == RelationType.many ? const [] : null;
      }
      return;
    }

    // One batched IN(...) query for all children.
    final childRows = await _db
        .select()
        .from(targetTable)
        .where(inArray<Object?>(
            targetColRef as ColumnRef<Object?>, keys.toList()));

    final byKey = <Object?, List<Map<String, Object?>>>{};
    for (final row in childRows) {
      final k = row.raw[targetCol];
      byKey.putIfAbsent(k, () => []).add(Map<String, Object?>.from(row.raw));
    }

    for (final p in parents) {
      final children = byKey[p[localCol]] ?? const [];
      if (def.type == RelationType.many) {
        p[relName] = children;
      } else {
        p[relName] = children.isEmpty ? null : children.first;
      }
    }
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
