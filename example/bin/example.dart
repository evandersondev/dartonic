import 'package:darto/darto.dart';
import 'package:example/config/database.dart';

class DB {
  final user = dartonic.table('users');
}

void main() async {
  final app = Darto();

  final db = await dartonic.sync();
  final user = dartonic.table('users');

  await user.create({'name': 'John Doe'});
  await user.create({'name': 'Jane Doe'});
  await user.create({'name': 'Morpheus Doe'});
  await user.create({'name': 'Neo Doe'});

  await user.updateById(1, {'name': 'Evan Doe'});
  final users = await user.findAll(
    attributes: ['name'],
    order: [
      ['name', 'desc'],
    ],
  );
  print(users);

  final users2 = await db
      .select({'name': 'users.name'})
      .from('users')
      .orderBy('name', 'desc');

  print(users2);

  // await user.updateById(1, {'is_active': true});

  // final evanUser = await user.findOne(eq('users.name', 'Evan Doe'));
  // print(evanUser);

  // await db.insert('users').values({'name': 'John Doe'});
  // await db.update('users').set({'is_active': true});

  // final users = await db.select().from('users');
  // print(users);

  app.listen(3000, () => print('Server is running on port 3000'));
}
