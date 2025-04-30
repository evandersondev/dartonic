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
  await dartonic.sync();

  final user = dartonic.table('users');

  await user.create({'name': 'John Doe'});
  await user.create({'name': 'Jane Doe'});

  await user.updateById(1, {'name': 'Evan Doe'});
  final users = await user.findAll();
  print(users);

  await user.updateById(1, {'is_active': true});

  final evanUser = await user.findOne(eq('users.name', 'Evan Doe'));
  print(evanUser);

  // await db.insert('users').values({'name': 'John Doe'});
  // await db.update('users').set({'is_active': true});

  // final users = await db.select().from('users');
  // print(users);

  app.listen(3000, () => print('Server is running on port 3000'));
}
