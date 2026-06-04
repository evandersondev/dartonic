import 'package:dartonic_core/dartonic_core.dart';

import '../database/tables.dart';
import '../models/group.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../models/user.dart';

/// Data access for users and the relations that hang off them. All query
/// details — joins, relation loaders — are encapsulated here so controllers
/// only deal with models.
class UserRepository {
  final DartonicDb _db;
  UserRepository(this._db);

  Future<User> create(String name, String email) async {
    final rows = await _db.insert(users).values([
      users.name.value(name),
      users.email.value(email),
    ]).returning();
    return User.fromRow(rows.first);
  }

  /// ONE-TO-MANY: a user and all of their posts (two batched queries).
  Future<({User user, List<Post> posts})?> postsOf(int userId) async {
    final result = await _db.findManyWith<User, Post, int>(
      parent: users,
      parentDecoder: User.fromRow,
      parentKey: (u) => u.id,
      childTable: posts,
      childForeignKey: posts.userId,
      childDecoder: Post.fromRow,
      where: eq(users.id, userId),
    );
    if (result.isEmpty) return null;
    final entry = result.first;
    return (user: entry.parent, posts: entry.children);
  }

  /// ONE-TO-ONE: a user and their (optional) profile.
  Future<({User user, Profile? profile})?> profileOf(int userId) async {
    final result = await _db.findManyWithOne<User, Profile, int>(
      parent: users,
      parentDecoder: User.fromRow,
      parentKey: (u) => u.id,
      childTable: profiles,
      childForeignKey: profiles.userId,
      childDecoder: Profile.fromRow,
      where: eq(users.id, userId),
    );
    if (result.isEmpty) return null;
    final entry = result.first;
    return (user: entry.parent, profile: entry.child);
  }

  /// MANY-TO-MANY: a user and their groups (through the junction table).
  Future<({User user, List<Group> groups})?> groupsOf(int userId) async {
    final result = await _db.findManyThrough<User, Group, int, int>(
      parent: users,
      parentDecoder: User.fromRow,
      parentKey: (u) => u.id,
      junction: userGroups,
      junctionParentKey: userGroups.userId,
      junctionChildKey: userGroups.groupId,
      child: groups,
      childKey: groups.id,
      childDecoder: Group.fromRow,
      where: eq(users.id, userId),
    );
    if (result.isEmpty) return null;
    final entry = result.first;
    return (user: entry.parent, groups: entry.children);
  }
}
