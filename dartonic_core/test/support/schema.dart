import 'package:dartonic_core/dartonic_core.dart';

class UsersTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final email = text('email').notNull().unique();
  final name = text('name').notNull();
  final active = boolean('active');
  final createdAt = datetime('created_at');
}

class PostsTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final userId = integer('user_id').notNull();
  final title = text('title').notNull();
}

// Name-derivation fixtures.

class BlogPostsTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
}

class OrderItemSchema extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
}

class LegacyAccount extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  @override
  String get tableName => 'tb_legacy';
}
