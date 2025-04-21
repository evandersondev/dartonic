import 'package:darto/darto.dart';
import 'package:dartonic/dartonic.dart';

void main() async {
  final app = Darto();

  // final usersTable = sqliteTable('users', {
  //   'id': integer().primaryKey(autoIncrement: true),
  //   'name': text().notNull(),
  //   'email': text().notNull().unique(),
  // });
  final statusEnum = pgEnum('mood', ['active', 'inactive', 'banned']);

  final userTableSchema = pgTable('users', {
    'id': uuid().primaryKey(),
    'name': text().notNull(),
    'status': statusEnum(),
    'timestamp': timestamp(),
  });

  // final rolesTableSchema = pgTable('roles', {
  //   'id': uuid().primaryKey(),
  //   'name': text().notNull(),
  //   'created_at': timestamp().defaultNow(),
  // });

  // final userRolesTableSchema = pgTable(
  //   'user_roles',
  //   {
  //     'user_id': uuid().notNull(),
  //     'role_id': uuid().notNull(),
  //     'created_at': timestamp().defaultNow(),
  //   },
  //   foreignKeys: [
  //     ForeignKey(
  //       column: 'user_id',
  //       references: 'users',
  //       referencesColumn: 'id',
  //       onDelete: ReferentialAction.cascade,
  //     ),
  //     ForeignKey(
  //       column: 'role_id',
  //       references: 'roles',
  //       referencesColumn: 'id',
  //       onDelete: ReferentialAction.cascade,
  //     ),
  //   ],
  // );

  final dartonic = Dartonic(
    "postgres://user:password@localhost:5432/mydb",
    schemas: [userTableSchema],
    enums: [statusEnum],
  );
  await dartonic.sync();

  // Inserir mais dados de teste
  // final user =
  //     await db.insert('users').values({
  //       'id': Uuid().v4(),
  //       'name': 'Jane Doe',
  //       'email': 'janedoe@mail.com',
  //     }).returning();
  // await db.insert('users').values({
  //   'id': Uuid().v4(),
  //   'name': 'John Doe',
  //   'email': 'johndoe@mail.com',
  // });

  // await db.insert('roles').values({'id': Uuid().v4(), 'name': 'user'});
  // final role =
  //     await db.insert('roles').values({
  //       'id': Uuid().v4(),
  //       'name': 'admin',
  //     }).returning();

  // // Criar mais relacionamentos
  // await db.insert('user_roles').values({
  //   'user_id': user[0]['id'], // Jane Doe
  //   'role_id': role[0]['id'], // role user
  // });

  // await db.insert('user_roles').values({
  //   'user_id': 2, // Jane Doe
  //   'role_id': 1, // role admin
  // });

  // Primeiro vamos garantir que o count está funcionando corretamente
  // Primeiro, confirmamos que temos 2 roles no sistema
  // final userNameLikeJohn = await db
  //     .select()
  //     .from('users')
  //     .where(like('users.name', '%john%'));
  // print('Total de Roles: $totalRoles');
  // final user = await db.select().from('users');
  // print('Select with where like: $userNameLikeJohn');

  // Query para buscar usuários e suas roles
  // final usersWithRoles = await db
  //     .select({
  //       'name': 'users.name',
  //       'total_roles': count(
  //         'user_roles.role_id',
  //         distinct: true,
  //       ), // sql('COUNT(DISTINCT user_roles.role_id)'),
  //     })
  //     .from('users')
  //     .innerJoin('user_roles', eq('users.id', 'user_roles.user_id'))
  //     .groupBy(['users.id', 'users.name']);
  // print('Usuários e suas roles: $usersWithRoles');

  // final usersInnerRole = await db
  //     .select()
  //     .from('users')
  //     .innerJoin('user_roles', eq('users.id', 'user_roles.user_id'));
  // print('Usuários com roles: $usersInnerRole');

  // // Query para buscar apenas usuários que têm TODAS as roles
  // final usersWithAllRoles = await db
  //     .select({
  //       'name': 'users.name',
  //       'total_roles': 'COUNT(DISTINCT user_roles.role_id)',
  //     })
  //     .from('users')
  //     .innerJoin('user_roles', eq('users.id', 'user_roles.user_id'))
  //     .groupBy(['users.id', 'users.name'])
  //     .having(eq('COUNT(DISTINCT user_roles.role_id)', totalRoles[0]['total']));
  // print('Usuários com todas as roles: $usersWithAllRoles');

  // final userUpdate =
  //     await db
  //         .update('users')
  //         .set({'name': 'John Doe Updated'})
  //         .where(eq('id', 1))
  //         .returning();
  // print(userUpdate);

  // final usersCount = await db.select().from('users').count();
  // print('Total de usuários: $usersCount');

  // await db.delete('users').where(eq('users.id', 1));

  app.listen(3000, () => print('Server is running on port 3000'));
}
