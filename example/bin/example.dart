import 'package:darto/darto.dart';
import 'package:dartonic/dartonic.dart';
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

  // final result = await db.query.users.findFirst();
  // print(result);

  // await changeNamesWithRollback();

  // final users2 = await db
  //     .select({'name': 'users.name'})
  //     .from('users')
  //     .orderBy('name', 'desc');

  // print(users2);

  // await user.updateById(1, {'is_active': true});

  // final evanUser = await user.findOne(eq('users.name', 'Evan Doe'));
  // print(evanUser);

  final users = await db.select().from('users');
  print(users);

  //   final driver = dartonic.driver;
  //   final users = await driver.raw('SELECT * FROM users');
  //   print(users);

  app.listen(3000, () => print('Server is running on port 3000'));
}

Future<void> changeNamesWithRollback() async {
  final db = dartonic.instance;

  await db.transaction((tx) async {
    final [account] = await db
        .select()
        .from('account')
        .where(eq('users.name', 'Dan'));

    if (account['balance'] < 100) {
      tx.rollback();
    }

    await tx
        .update('accounts')
        .set({'balance': account['balance'] - 100.00})
        .where(eq('users.name', 'Dan'));

    await tx
        .update('accounts')
        .set({'balance': account['balance'] + 100.00})
        .where(eq('users.name', 'Andrew'));
  });
}
