import 'package:dartonic/dartonic.dart';

final users = sqliteTable('users', {
  'id': integer().primaryKey(autoIncrement: true),
  'name': text().notNull(),
  'is_active': integer(mode: 'boolean').$default(0),
});
