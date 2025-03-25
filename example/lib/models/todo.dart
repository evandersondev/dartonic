import 'package:dartonic/dartonic.dart';

final todoSchema = sqliteTable('todos', {
  'id': integer().primaryKey(autoIncrement: true),
  'title': text().notNull(),
  'description': text().notNull(),
  'completed': integer(mode: 'boolean').defaultVal(0),
  'created_at': timestamp().defaultNow(),
  'updated_at': timestamp().defaultNow(),
});
