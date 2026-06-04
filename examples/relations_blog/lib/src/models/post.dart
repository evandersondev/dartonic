import 'package:dartonic_core/dartonic_core.dart';

import '../database/tables.dart';

class Post {
  final int id;
  final int userId;
  final String title;
  Post({required this.id, required this.userId, required this.title});

  factory Post.fromRow(RowMap r) => Post(
        id: r.readNotNull(posts.id),
        userId: r.readNotNull(posts.userId),
        title: r.readNotNull(posts.title),
      );

  Map<String, Object?> toJson() =>
      {'id': id, 'userId': userId, 'title': title};
}
