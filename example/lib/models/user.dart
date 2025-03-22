import 'package:dartonic/dartonic.dart';

final usersTable = sqliteTable('users', {
  'id': integer().primaryKey(autoIncrement: true),
  'name': text(columnName: 'fullname'),
  'age': integer(columnName: 'birthday'),
  'created_at': timestamp().notNull().defaultNow(),
  'updated_at': timestamp().notNull().defaultNow(),
});
