import 'package:darto/darto.dart';
import 'package:dartonic/dartonic.dart';

void main() async {
  // await dartonic.sync();
  final app = Darto();

  // app.use('/api/v1', appRouter());
  // app.use('/api/v1', todoRouter());

  //

  // Define the table schema for "users" using mysqlTable
  final usersTable = mysqlTable('users', {
    'username': varchar().notNull(),
    'email': varchar().unique(),
  });

  final dartonic = Dartonic("mysql://user:userpassword@localhost:3306/mydb", [
    usersTable,
  ]);
  final db = await dartonic.sync();

  await db.insert('users').values({
    'username': "john doe",
    'email': "john@example.com",
  });

  final users = await db.select().from('users');
  print(users);

  app.listen(3000, () => print('Server is running on port 3000'));
}
