import 'package:darto/darto.dart';
import 'package:dartonic/dartonic.dart';

void main() async {
  final app = Darto();

  final usersSchemas = sqliteTable('users', {
    'id': integer().primaryKey(autoIncrement: true),
    'name': text().notNull(),
    'is_active': integer(mode: 'boolean').$default(0),
  });

  final dartonic = Dartonic("sqlite::memory:", schemas: [usersSchemas]);
  final db = await dartonic.sync();

  await db.insert('users').values({'name': 'John Doe'});
  await db.update('users').set({'is_active': true});

  // final users = await db.select().from('users');
  // print(users);

  final driver = dartonic.driver;
  final users = await driver.raw('SELECT * FROM users');
  print(users);

  app.listen(3000, () => print('Server is running on port 3000'));
}
