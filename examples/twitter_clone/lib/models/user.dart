import 'package:dartonic_core/dartonic_core.dart';

import '../db/schema.dart';

class User {
  final int id;
  final String username;
  final String displayName;
  final String? bio;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    required this.createdAt,
  });

  /// Decodes a row of the `users` table.
  factory User.fromRow(RowMap row) => User(
        id: row.readNotNull(users.id),
        username: row.readNotNull(users.username),
        displayName: row.readNotNull(users.displayName),
        bio: row.read(users.bio),
        createdAt: row.readNotNull(users.createdAt),
      );

  @override
  String toString() {
    final bioLine = bio != null ? ' — $bio' : '';
    return '@$username ($displayName)$bioLine';
  }
}
