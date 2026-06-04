import 'package:dartonic_core/dartonic_core.dart';

import '../database/tables.dart';

class Group {
  final int id;
  final String name;
  Group({required this.id, required this.name});

  factory Group.fromRow(RowMap r) => Group(
        id: r.readNotNull(groups.id),
        name: r.readNotNull(groups.name),
      );

  Map<String, Object?> toJson() => {'id': id, 'name': name};
}
