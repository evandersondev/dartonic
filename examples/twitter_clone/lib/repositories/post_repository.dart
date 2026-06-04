import 'package:dartonic_core/dartonic_core.dart';

import '../db/schema.dart';
import '../models/post.dart';

class PostRepository {
  final DartonicDb db;

  const PostRepository(this.db);

  /// Creates a new post by [userId].
  Future<void> create({required int userId, required String content}) =>
      db.insert(posts).values([
        posts.userId.value(userId),
        posts.content.value(content),
      ]);

  /// Returns all posts, newest first.
  Future<List<Post>> findAll() => db
      .select()
      .from(posts)
      .orderBy(posts.createdAt, Order.desc)
      .rows(Post.fromRow);

  /// Returns all posts with their author info — a JOIN query.
  Future<List<PostWithAuthor>> timeline() => db
      .select([
        posts.id,
        posts.content,
        posts.createdAt,
        users.username,
        users.displayName,
      ])
      .from(posts)
      .innerJoin(users, eqCol(posts.userId, users.id))
      .orderBy(posts.createdAt, Order.desc)
      .rows(PostWithAuthor.fromRow);

  /// Returns posts by a specific user, newest first.
  Future<List<PostWithAuthor>> findByUsername(String username) => db
      .select([
        posts.id,
        posts.content,
        posts.createdAt,
        users.username,
        users.displayName,
      ])
      .from(posts)
      .innerJoin(users, eqCol(posts.userId, users.id))
      .where(eq(users.username, username))
      .orderBy(posts.createdAt, Order.desc)
      .rows(PostWithAuthor.fromRow);

  /// Deletes a post by [id].
  Future<void> delete(int id) => db.delete(posts).where(eq(posts.id, id));
}
