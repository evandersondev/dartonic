import 'package:dartonic_core/dartonic_core.dart';
import 'package:dartonic_sqlite/dartonic_sqlite.dart';

class UsersTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final name = text('name').notNull();
}

final users = UsersTable();

Future<DartonicDb> openDatebase() =>
    connectSqlite(':memory:', schemas: [users]);
