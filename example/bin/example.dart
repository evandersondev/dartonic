import 'package:darto/darto.dart';
import 'package:dartonic/dartonic.dart';

void main() async {
  final app = Darto();

  final usersSchemas = sqliteTable('users', {
    'id': integer().primaryKey(autoIncrement: true),
    'name': text().notNull(),
  });

  final dartonic = Dartonic(
    "sqlite::memory:",
    schemas: [usersSchemas],
    enableStudio: true,
  );
  final db = await dartonic.sync();

  final users = await db.select().from('users');
  print(users);

  app.listen(3000, () => print('Server is running on port 3000'));
}
