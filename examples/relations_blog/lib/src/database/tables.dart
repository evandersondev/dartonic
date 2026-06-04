import 'package:dartonic_core/dartonic_core.dart';

// ════════════════════════════════════════════════════════════════════════
//  SCHEMA — tables and their foreign keys.
//
//  Relations live here: each `.references()` is what creates a relation at the
//  database level. Tables are kept in one file because they're tightly coupled
//  by those foreign keys. The class name maps to the SQL table name by
//  convention (UsersTable -> "users", UserGroupsTable -> "user_groups").
// ════════════════════════════════════════════════════════════════════════

class UsersTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final name = text('name').notNull();
  final email = text('email').notNull().unique();
}

class GroupsTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final name = text('name').notNull().unique();
}

/// ONE-TO-ONE: a `UNIQUE` foreign key — a user can have at most one profile.
class ProfilesTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final userId = integer('user_id')
      .notNull()
      .unique()
      .references(() => users.id, onDelete: ReferentialAction.cascade);
  final bio = text('bio').notNull();
}

/// ONE-TO-MANY (user -> posts) and MANY-TO-ONE (post -> author): one FK.
class PostsTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final userId = integer('user_id')
      .notNull()
      .references(() => users.id, onDelete: ReferentialAction.cascade);
  final title = text('title').notNull();
}

/// MANY-TO-MANY (users <-> groups): a junction table with one FK to each side.
class UserGroupsTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final userId = integer('user_id')
      .notNull()
      .references(() => users.id, onDelete: ReferentialAction.cascade);
  final groupId = integer('group_id')
      .notNull()
      .references(() => groups.id, onDelete: ReferentialAction.cascade);
}

// Module-level singletons. Declared after the classes so the `.references`
// thunks resolve lazily.
final users = UsersTable();
final groups = GroupsTable();
final profiles = ProfilesTable();
final posts = PostsTable();
final userGroups = UserGroupsTable();

/// Registration order matters on Postgres/MySQL — a referenced table must
/// exist before the table referencing it. Parents first, then children.
final allSchemas = [users, groups, profiles, posts, userGroups];
