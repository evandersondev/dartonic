import 'package:dartonic_core/dartonic_core.dart';

import '../db/schema.dart';

class Post {
  final int id;
  final int userId;
  final String content;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory Post.fromRow(RowMap row) => Post(
        id: row.readNotNull(posts.id),
        userId: row.readNotNull(posts.userId),
        content: row.readNotNull(posts.content),
        createdAt: row.readNotNull(posts.createdAt),
      );

  @override
  String toString() => 'Post(#$id by user $userId): "$content"';
}

/// A post row joined with its author — result of the timeline query.
class PostWithAuthor {
  final int id;
  final String content;
  final DateTime createdAt;
  final String username;
  final String displayName;

  const PostWithAuthor({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.username,
    required this.displayName,
  });

  factory PostWithAuthor.fromRow(RowMap row) => PostWithAuthor(
        id: row.readNotNull(posts.id),
        content: row.readNotNull(posts.content),
        createdAt: row.readNotNull(posts.createdAt),
        username: row.readNotNull(users.username),
        displayName: row.readNotNull(users.displayName),
      );

  @override
  String toString() => '@$username: "$content"';
}
