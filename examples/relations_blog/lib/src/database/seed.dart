import 'package:dartonic_core/dartonic_core.dart';

import 'tables.dart';

/// Inserts a small, connected dataset so every relation endpoint returns data.
Future<void> seedDatabase(DartonicDb db) async {
  final alice = await _insertUser(db, 'Alice', 'alice@acme.dev');
  final bob = await _insertUser(db, 'Bob', 'bob@acme.dev');

  // one-to-one: a profile per user
  await db.insert(profiles).values([
    profiles.userId.value(alice),
    profiles.bio.value('Loves databases.'),
  ]);

  // one-to-many: Alice writes two posts, Bob writes one
  await db.insert(posts).valuesMany([
    [posts.userId.value(alice), posts.title.value('Hello world')],
    [posts.userId.value(alice), posts.title.value('Relations 101')],
    [posts.userId.value(bob), posts.title.value('Bob says hi')],
  ]);

  // many-to-many: groups + memberships
  final admins = await _insertGroup(db, 'admins');
  final authors = await _insertGroup(db, 'authors');
  await db.insert(userGroups).valuesMany([
    [userGroups.userId.value(alice), userGroups.groupId.value(admins)],
    [userGroups.userId.value(alice), userGroups.groupId.value(authors)],
    [userGroups.userId.value(bob), userGroups.groupId.value(authors)],
  ]);
}

Future<int> _insertUser(DartonicDb db, String name, String email) async {
  final rows = await db.insert(users).values([
    users.name.value(name),
    users.email.value(email),
  ]).returning();
  return rows.first.readNotNull(users.id);
}

Future<int> _insertGroup(DartonicDb db, String name) async {
  final rows = await db
      .insert(groups)
      .values([groups.name.value(name)]).returning();
  return rows.first.readNotNull(groups.id);
}
