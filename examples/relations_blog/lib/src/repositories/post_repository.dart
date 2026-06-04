import 'package:dartonic_core/dartonic_core.dart';

import '../database/tables.dart';
import '../models/post.dart';
import '../models/user.dart';

class PostRepository {
  final DartonicDb _db;
  PostRepository(this._db);

  /// MANY-TO-ONE: a post and its single author, via a JOIN. Projecting columns
  /// from both tables lets one query decode into both models.
  Future<({Post post, User author})?> withAuthor(int postId) async {
    final rows = await _db
        .select([posts.id, posts.title, users.id, users.name, users.email])
        .from(posts)
        .innerJoin(users, eqCol(posts.userId, users.id))
        .where(eq(posts.id, postId));

    if (rows.isEmpty) return null;
    final r = rows.first;
    final post = Post(
      id: r.readNotNull(posts.id),
      userId: r.readNotNull(users.id),
      title: r.readNotNull(posts.title),
    );
    return (post: post, author: User.fromRow(r));
  }
}
