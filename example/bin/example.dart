import 'package:darto/darto.dart';
import 'package:dartonic/dartonic.dart';

void main() async {
  // await dartonic.sync();
  final app = Darto();

  // app.use('/api/v1', appRouter());
  // app.use('/api/v1', todoRouter());

  //

  final usersTable = mysqlTable('users', {
    'id': integer().primaryKey(autoIncrement: true),
    'username': varchar().notNull(),
    'email': varchar().unique(),
  });

  final taskTable = mysqlTable('tasks', {
    'id': integer().primaryKey(autoIncrement: true),
    'title': varchar().notNull(),
    'is_completed': boolean().notNull().defaultVal(false),
    'user_id': integer().references(() => 'users.id'),
  });

  final usersRelations = relations(
    usersTable,
    (builder) => {
      'tasks': builder.many(
        'tasks',
        fields: ['users.id'],
        references: ['tasks.user_id'],
      ),
    },
  );

  final dartonic = Dartonic("mysql://user:userpassword@localhost:3307/mydb", [
    usersTable,
    taskTable,
    usersRelations,
  ]);
  final db = await dartonic.sync();

  // await db.insert('users').values({
  //   'username': 'John Doe',
  //   'email': 'john@example.com',
  // });

  // await db.insert('tasks').values({
  //   'title': 'Buy groceries',
  //   'is_completed': true,
  //   'user_id': 1,
  // });

  final users = await db
      .select({
        'name': 'users.username',
        'task_title': 'tasks.title',
        'is_completed': 'tasks.is_completed',
      })
      .from('users')
      .innerJoin('tasks', eq('users.id', 'tasks.user_id'));
  print(users);

  app.listen(3000, () => print('Server is running on port 3000'));
}
