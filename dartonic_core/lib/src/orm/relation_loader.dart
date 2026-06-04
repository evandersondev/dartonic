import '../query_builder/condition.dart';
import '../query_builder/database_facade.dart';
import '../types/column_ref.dart';
import '../types/row.dart';
import '../types/table.dart';

/// A parent record paired with its preloaded children.
///
/// Returned by [Database.findManyWith] and friends.
class WithChildren<P, C> {
  final P parent;
  final List<C> children;
  const WithChildren(this.parent, this.children);
}

/// A parent record paired with an optional preloaded one-to-one child.
class WithOne<P, C> {
  final P parent;
  final C? child;
  const WithOne(this.parent, this.child);
}

/// Loader helpers for one-to-many and one-to-one relations. Each helper
/// issues **two** SQL queries total — one for parents, one for children —
/// then groups in Dart. This is faster and clearer than N+1 hand-written
/// loops and works without code generation.
extension RelationLoader on Database {
  /// Loads parents and their children via a single batched `IN (…)` query.
  ///
  /// ```dart
  /// final usersWithPosts = await db.findManyWith<User, Post, int>(
  ///   parent: usersTable,
  ///   parentDecoder: User.fromRow,
  ///   parentKey: (u) => u.id,
  ///   childTable: postsTable,
  ///   childForeignKey: postsTable.userId,    // ColumnRef<int>
  ///   childDecoder: Post.fromRow,
  /// );
  /// // Type: List<WithChildren<User, Post>>
  /// ```
  Future<List<WithChildren<P, C>>> findManyWith<P, C, K>({
    required Table parent,
    required P Function(RowMap row) parentDecoder,
    required K Function(P parent) parentKey,
    required Table childTable,
    required ColumnRef<K> childForeignKey,
    required C Function(RowMap row) childDecoder,
    Condition? where,
  }) async {
    final parentQ = select().from(parent);
    if (where != null) parentQ.where(where);
    final parentRows = await parentQ;
    final parents = parentRows.map(parentDecoder).toList();
    if (parents.isEmpty) return const [];

    final keys = parents.map(parentKey).toList();
    final childRows = await select()
        .from(childTable)
        .where(inArray<K>(childForeignKey, keys));

    final byKey = <K, List<C>>{};
    for (final row in childRows) {
      final k = row.read(childForeignKey);
      if (k == null) continue;
      final child = childDecoder(row);
      byKey.putIfAbsent(k, () => []).add(child);
    }

    return [
      for (final p in parents)
        WithChildren<P, C>(p, byKey[parentKey(p)] ?? const []),
    ];
  }

  /// Loads parents and their many-to-many children through a junction
  /// table. Issues **three** SQL queries total — one for parents, one for
  /// the junction rows, one for the children — then groups in Dart.
  ///
  /// ```dart
  /// // users ──< user_groups >── groups
  /// final usersWithGroups = await db.findManyThrough<User, Group, int, int>(
  ///   parent:             usersTable,
  ///   parentDecoder:      User.fromRow,
  ///   parentKey:          (u) => u.id,
  ///   junction:           userGroupsTable,
  ///   junctionParentKey:  userGroupsTable.userId,    // ColumnRef<int>
  ///   junctionChildKey:   userGroupsTable.groupId,   // ColumnRef<int>
  ///   child:              groupsTable,
  ///   childKey:           groupsTable.id,            // ColumnRef<int>
  ///   childDecoder:       Group.fromRow,
  /// );
  /// // → List<WithChildren<User, Group>>
  /// ```
  Future<List<WithChildren<P, C>>> findManyThrough<P, C, PK, CK>({
    required Table parent,
    required P Function(RowMap row) parentDecoder,
    required PK Function(P parent) parentKey,
    required Table junction,
    required ColumnRef<PK> junctionParentKey,
    required ColumnRef<CK> junctionChildKey,
    required Table child,
    required ColumnRef<CK> childKey,
    required C Function(RowMap row) childDecoder,
    Condition? where,
  }) async {
    final parentQ = select().from(parent);
    if (where != null) parentQ.where(where);
    final parentRows = await parentQ;
    final parents = parentRows.map(parentDecoder).toList();
    if (parents.isEmpty) return const [];

    final pks = parents.map(parentKey).toList();
    final junctionRows = await select()
        .from(junction)
        .where(inArray<PK>(junctionParentKey, pks));
    if (junctionRows.isEmpty) {
      return [for (final p in parents) WithChildren<P, C>(p, const [])];
    }

    final childKeys = <CK>{};
    final parentToChildKeys = <PK, List<CK>>{};
    for (final row in junctionRows) {
      final pk = row.read(junctionParentKey);
      final ck = row.read(junctionChildKey);
      if (pk == null || ck == null) continue;
      childKeys.add(ck);
      parentToChildKeys.putIfAbsent(pk, () => []).add(ck);
    }

    final childRows = await select()
        .from(child)
        .where(inArray<CK>(childKey, childKeys.toList()));
    final childrenByKey = <CK, C>{};
    for (final row in childRows) {
      final ck = row.read(childKey);
      if (ck == null) continue;
      childrenByKey[ck] = childDecoder(row);
    }

    return [
      for (final p in parents)
        WithChildren<P, C>(
          p,
          (parentToChildKeys[parentKey(p)] ?? const <Never>[])
              .map((ck) => childrenByKey[ck])
              .whereType<C>()
              .toList(),
        ),
    ];
  }

  /// Loads parents and an optional single child via a batched `IN (…)`.
  /// Use for one-to-one relations.
  ///
  /// ```dart
  /// final usersWithProfile = await db.findManyWithOne<User, Profile, int>(
  ///   parent: usersTable,
  ///   parentDecoder: User.fromRow,
  ///   parentKey: (u) => u.id,
  ///   childTable: profilesTable,
  ///   childForeignKey: profilesTable.userId,
  ///   childDecoder: Profile.fromRow,
  /// );
  /// ```
  Future<List<WithOne<P, C>>> findManyWithOne<P, C, K>({
    required Table parent,
    required P Function(RowMap row) parentDecoder,
    required K Function(P parent) parentKey,
    required Table childTable,
    required ColumnRef<K> childForeignKey,
    required C Function(RowMap row) childDecoder,
    Condition? where,
  }) async {
    final list = await findManyWith<P, C, K>(
      parent: parent,
      parentDecoder: parentDecoder,
      parentKey: parentKey,
      childTable: childTable,
      childForeignKey: childForeignKey,
      childDecoder: childDecoder,
      where: where,
    );
    return [
      for (final w in list)
        WithOne<P, C>(w.parent, w.children.isEmpty ? null : w.children.first),
    ];
  }
}
