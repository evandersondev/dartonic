import 'package:dartonic_core/dartonic_core.dart';

/// `users` — one row per account.
class UsersTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final username = text('username').notNull().unique();
  final displayName = text('display_name').notNull();
  final bio = text('bio');
  final createdAt = datetime('created_at').defaultNow();
}

/// `posts` — each post belongs to a user.
class PostsTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final userId = integer('user_id')
      .notNull()
      .references(() => users.id, onDelete: ReferentialAction.cascade);
  final content = text('content').notNull();
  final createdAt = datetime('created_at').defaultNow();

  @override
  List<Index> defineIndexes() => [
        index('idx_posts_user_id').on([userId]),
        index('idx_posts_created_at').on([createdAt]),
      ];
}

/// Singletons. Construct once and share across repositories.
final users = UsersTable();
final posts = PostsTable();
