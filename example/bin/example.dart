import 'package:darto/darto.dart';
import 'package:dartonic/dartonic.dart';

void main() async {
  final app = Darto();

  final usersTable = sqliteTable('users', {
    'id': integer().primaryKey(autoIncrement: true),
    'name': text().notNull(),
    'created_at': datetime().defaultNow(),
  });

  final dartonic = Dartonic("mysql://user:userpassword@localhost:3307/mydb", [
    usersTable,
  ]);
  final db = await dartonic.sync();

  // Create a new user
  await db.insert("users").values({'name': 'John Doe'});

  // Get all users
  final users = await db.select().from("users");
  print(users);

  // Update and get a user by ID
  final userUpdate =
      await db
          .update('users')
          .set({'name': 'John Doe Updated'})
          .where(eq('id', 1))
          .returning();
  print(userUpdate);

  // Delete a user by ID
  await db.delete('users').where(eq('users.id', 1));

  app.listen(3000, () => print('Server is running on port 3000'));
}
