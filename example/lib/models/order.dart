import 'package:dartonic/dartonic.dart';

final ordersTable = sqliteTable('orders', {
  'id': integer().primaryKey(autoIncrement: true),
  'user_id': integer(columnName: 'user_id').references(() => 'users.id'),
  'total': integer(),
});
