import 'package:dartonic_core/dartonic_core.dart';

import '../database/tables.dart';

class Profile {
  final int id;
  final int userId;
  final String bio;
  Profile({required this.id, required this.userId, required this.bio});

  factory Profile.fromRow(RowMap r) => Profile(
        id: r.readNotNull(profiles.id),
        userId: r.readNotNull(profiles.userId),
        bio: r.readNotNull(profiles.bio),
      );

  Map<String, Object?> toJson() => {'id': id, 'userId': userId, 'bio': bio};
}
