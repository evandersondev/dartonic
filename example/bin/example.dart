import 'package:darto/darto.dart';

import 'package:dartonic/dartonic.dart';

void main() async {
  final app = Darto();

  final usersTable = sqliteTable('users', {
    'id': integer().primaryKey(autoIncrement: true),
    'name': text().notNull(),
    'email': text().notNull().unique(),
  });

  final rolesTable = sqliteTable('roles', {
    'id': integer().primaryKey(autoIncrement: true),
    'name': text().notNull(),
    'created_at': datetime().defaultNow(),
  });

  final userRolesTable = sqliteTable(
    'user_roles',
    {
      'user_id': integer().notNull(),
      'role_id': integer().notNull(),
      'created_at': datetime().defaultNow(),
    },
    foreignKeys: [
      ForeignKey(
        column: 'user_id',
        references: 'users',
        referencesColumn: 'id',
        onDelete: ReferentialAction.cascade,
      ),
      ForeignKey(
        column: 'role_id',
        references: 'roles',
        referencesColumn: 'id',
        onDelete: ReferentialAction.cascade,
      ),
    ],
  );

  final dartonic = Dartonic("sqlite::memory:", [
    usersTable,
    rolesTable,
    userRolesTable,
  ]);
  final db = await dartonic.sync();

  // Inserir mais dados de teste
  final user =
      await db.insert('users').values({
        'name': 'Jane Doe',
        'email': 'janedoe@mail.com',
      }).returning();
  await db.insert('users').values({
    'name': 'John Doe',
    'email': 'johndoe@mail.com',
  });
  print('Insert with returning: $user');

  await db.insert('roles').values({'name': 'user'});
  await db.insert('roles').values({'name': 'admin'});

  // Criar mais relacionamentos
  await db.insert('user_roles').values({
    'user_id': 2, // John Doe
    'role_id': 2, // role user
  });

  await db.insert('user_roles').values({
    'user_id': 2, // Jane Doe
    'role_id': 1, // role admin
  });

  // Primeiro vamos garantir que o count está funcionando corretamente
  // Primeiro, confirmamos que temos 2 roles no sistema
  final userNameLikeJohn = await db
      .select()
      .from('users')
      .where(like('users.name', '%john%'));
  // print('Total de Roles: $totalRoles');
  // final user = await db.select().from('users');
  print('Select with where like: $userNameLikeJohn');

  // Query para buscar usuários e suas roles
  final usersWithRoles = await db
      .select({
        'name': 'users.name',
        'total_roles': count(
          'user_roles.role_id',
          distinct: true,
        ), // sql('COUNT(DISTINCT user_roles.role_id)'),
      })
      .from('users')
      .innerJoin('user_roles', eq('users.id', 'user_roles.user_id'))
      .groupBy(['users.id', 'users.name']);
  print('Usuários e suas roles: $usersWithRoles');

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

  final userUpdate =
      await db
          .update('users')
          .set({'name': 'John Doe Updated'})
          .where(eq('id', 1))
          .returning();
  print(userUpdate);

  final usersCount = await db.select().from('users').count();
  print('Total de usuários: $usersCount');

  // await db.delete('users').where(eq('users.id', 1));

  app.listen(3000, () => print('Server is running on port 3000'));
}
