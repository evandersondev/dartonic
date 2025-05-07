import 'package:darto/darto.dart';
import 'package:example/config/database.dart';

void main() async {
  final app = Darto();

  final db = await dartonic.sync();

  await db.insert('users').values({'name': 'John Doe'});
  await db.insert('users').values({'name': 'Jane Doe'});
  await db.insert('users').values({'name': 'Neo Doe'});
  await db.insert('users').values({'name': 'Morpheus Doe'});
  await db.insert('users').values({'name': 'Cyfer Doe'});
  // await db.update('users').set({'is_active': true});

  final result = await db.query.users.findFirst();
  print(result);

  // final users2 = await db
  //     .select({'name': 'users.name'})
  //     .from('users')
  //     .orderBy('name', 'desc');

  // print(users2);

  // await user.updateById(1, {'is_active': true});

  // final evanUser = await user.findOne(eq('users.name', 'Evan Doe'));
  // print(evanUser);

  // final users = await db.select().from('users');
  // print(users);

  app.listen(3000, () => print('Server is running on port 3000'));
}
