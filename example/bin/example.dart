import 'package:darto/darto.dart';
import 'package:dartonic/dartonic.dart';
import 'package:example/config/database.dart';

void main() async {
  final app = Darto();

  final db = await database.sync();

  // await db.insert(users.name).values({'name': 'Alice'});
  // await db.insert(users.name).values({'name': 'Bob'});
  // await db.insert(users.name).values({'name': 'Charlie'});

  await db.insert(posts.name).values({
    'title': 'Post 1',
    'user_id': '89673577-2639-4216-b24a-583ea3c6ae1c',
  });
  await db.insert(posts.name).values({
    'title': 'Post 2',
    'user_id': '89673577-2639-4216-b24a-583ea3c6ae1c',
  });
  await db.insert(posts.name).values({
    'title': 'Post 3',
    'user_id': '1b04a0e6-6559-4e0c-8ca1-f46358329aa3',
  });
  await db.insert(posts.name).values({
    'title': 'Post 4',
    'user_id': '6db477fc-94d2-4516-8d30-f2a939a8b329',
  });

  // final userPosts = db
  //     .$with('user_posts')
  //     .as(
  //       db
  //           .select({
  //             'user_id': 'posts.user_id',
  //             'post_count': count('posts.id', distinct: true),
  //           })
  //           .from('posts')
  //           .groupBy(['posts.user_id']),
  //     );

  // final result = await db
  //     .with$(userPosts)
  //     .select({'name': 'users.name', 'post_count': 'user_posts.post_count'})
  //     .from('users')
  //     .innerJoin('user_posts', eq('users.id', 'user_posts.user_id'))
  //     .where(gt('user_posts.post_count', 1));

  // print('Usuários com mais de 1 post:');
  // print(result);

  // await db.insert('users').values({'name': 'John Doe'});
  // await db.insert('users').values({'name': 'Jane Doe'});
  // await db.insert('users').values({'name': 'Neo Doe'});
  // final morpheus =
  //     await db.insert('users').values({'name': 'Morpheus Doe'}).returning();
  // print(morpheus);
  // await db.insert('users').values({'name': 'Cyfer Doe'});
  // final userUpdated =
  //     await db
  //         .update('users')
  //         .set({'name': 'Jane Doe'})
  //         .where(eq('users.id', 'c89471e6-08f0-4fc5-a668-9771fb334b92'))
  //         .returning();
  // print(userUpdated);

  final result = await db
      .select({'post_title': 'posts.title', 'user_name': 'users.name'})
      .from('posts')
      .innerJoin('users', eq('users.id', 'posts.user_id'));
  print(result);
  // final result = await db.select().from(posts.name);
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

  // final [john] = await db.select().from('user_john');
  // print(john);

  //   final driver = dartonic.driver;
  //   final users = await driver.raw('SELECT * FROM users');
  //   print(users);

  app.listen(3000, () => print('Server is running on port 3000'));
}

// Future<void> changeNamesWithRollback() async {
//   final db = dartonic.instance;

//   await db.transaction((tx) async {
//     final [account] = await db
//         .select()
//         .from('account')
//         .where(eq('users.name', 'Dan'));

//     if (account['balance'] < 100) {
//       tx.rollback();
//     }

//     await tx
//         .update('accounts')
//         .set({'balance': account['balance'] - 100.00})
//         .where(eq('users.name', 'Dan'));

//     await tx
//         .update('accounts')
//         .set({'balance': account['balance'] + 100.00})
//         .where(eq('users.name', 'Andrew'));
//   });
// }
