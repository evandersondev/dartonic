import 'package:dartonic_core/dartonic_core.dart';

import '../database/tables.dart';

class User {
  final int id;
  final String name;
  final String email;
  User({required this.id, required this.name, required this.email});

  factory User.fromRow(RowMap r) => User(
        id: r.readNotNull(users.id),
        name: r.readNotNull(users.name),
        email: r.readNotNull(users.email),
      );

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'email': email};
}
