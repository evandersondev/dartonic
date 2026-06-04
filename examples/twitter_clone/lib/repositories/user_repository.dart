import 'package:dartonic_core/dartonic_core.dart';

import '../db/schema.dart';
import '../models/post.dart';
import '../models/user.dart';

class UserRepository {
  final DartonicDb db;

  const UserRepository(this.db);

  /// Loads every user together with their posts in **two** SQL queries
  /// (no N+1 loop, no joins to flatten manually).
  Future<List<WithChildren<User, Post>>> findAllWithPosts() =>
      db.findManyWith<User, Post, int>(
        parent: users,
        parentDecoder: User.fromRow,
        parentKey: (u) => u.id,
        childTable: posts,
        childForeignKey: posts.userId,
        childDecoder: Post.fromRow,
      );

  /// Creates a new user. Throws if [username] already exists.
  Future<void> create({
    required String username,
    required String displayName,
    String? bio,
  }) =>
      db.insert(users).values([
        users.username.value(username),
        users.displayName.value(displayName),
        if (bio != null) users.bio.value(bio),
      ]);

  /// Returns all users ordered by creation date.
  Future<List<User>> findAll() =>
      db.select().from(users).orderBy(users.createdAt).rows(User.fromRow);

  /// Finds a single user by [username], or null.
  Future<User?> findByUsername(String username) async {
    final row = await db
        .select()
        .from(users)
        .where(eq(users.username, username))
        .limit(1)
        .first();
    return row == null ? null : User.fromRow(row);
  }

  /// Updates a user's profile fields.
  Future<void> update(
    int id, {
    String? displayName,
    String? bio,
  }) {
    final values = <ColumnValue<Object?>>[
      if (displayName != null) users.displayName.value(displayName),
      if (bio != null) users.bio.value(bio),
    ];
    if (values.isEmpty) return Future.value();
    return db.update(users).set(values).where(eq(users.id, id));
  }

  /// Deletes a user by [id].
  Future<void> delete(int id) =>
      db.delete(users).where(eq(users.id, id));
}
