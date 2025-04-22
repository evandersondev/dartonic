import 'package:darto/darto.dart';
import 'package:dartonic/dartonic.dart';

void main() async {
  final app = Darto();

  final usersSchemas = pgTable('users', {
    'id': uuid().primaryKey(),
    'name': text().notNull(),
    'timestamp': timestamp(),
  });

  final dartonic = Dartonic(
    "postgres://user:password@localhost:5432/mydb",
    schemas: [usersSchemas],
  );
  final db = await dartonic.sync();

  final users = await db.select().from('users');
  print(users);

  app.listen(3000, () => print('Server is running on port 3000'));
}
