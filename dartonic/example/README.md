```dart
// final users = await db
// .select({'name': 'users.fullname', 'age': 'users.birthday'})
// .from('users');

// final usersTable = sqliteTable('users', {
// 'id': integer().primaryKey(autoIncrement: true),
// 'name': text(columnName: 'fullname'),
// 'age': integer(columnName: 'birthday'),
// 'created_at': timestamp().notNull().defaultNow(),
// 'updated_at': timestamp().notNull().defaultNow(),
// });

// final ordersTable = sqliteTable('orders', {
// 'id': integer().primaryKey(autoIncrement: true),
// 'user_id': integer(columnName: 'user_id').references(() => 'users.id'),
// 'total': integer(),
// });

// final inserted =
// await db.insert('users').values({
// 'name': "Test User",
// 'age': 99,
// }).returning();
// print("Inserido: $inserted");

// final id = inserted.first['id'];

// final deleted = await db
// .delete('users')
// .where(eq("users.id", id))
// .returning(deletedId: 'users.id');
// print("Deletado: $deleted");

// final insertedUser =
// await db.insert('users').values({'name': "Dan", 'age': 28}).returning();
// print("Insert com RETURNING completo:");
// print(insertedUser);

// // Exemplo de INSERT com RETURNING retornando somente o id inserido.
// final insertedPartial = await db
// .insert('users')
// .values({'name': "Partial Dan", 'age': 30})
// .returning(insertedId: 'users.id');
// print("Insert com RETURNING parcial (somente id):");
// print(insertedPartial);

// // Exemplo de UPDATE com RETURNING retornando todos os campos atualizados.
// final updatedUser =
// await db
// .update('users')
// .set({'name': "Daniel", 'age': 29})
// .where(eq("users.id", 1))
// .returning();
// print("Update com RETURNING completo:");
// print(updatedUser);

// // Exemplo de UPDATE com RETURNING retornando somente o id atualizado.
// final updatedPartial = await db
// .update('users')
// .set({'age': 35})
// .where(eq("users.id", 2))
// .returning(updatedId: 'users.id');
// print("Update com RETURNING parcial (somente id):");
// print(updatedPartial);

// // Exemplo de DELETE com RETURNING retornando todos os campos do registro deletado.
// final deletedUser =
// await db.delete('users').where(eq("users.id", 3)).returning();
// print("Delete com RETURNING completo:");
// print(deletedUser);

// // Exemplo de DELETE com RETURNING retornando somente o id deletado.
// final deletedPartial = await db
// .delete('users')
// .where(eq("users.id", 4))
// .returning(deletedId: 'users.id');
// print("Delete com RETURNING parcial (somente id):");
// print(deletedPartial);

// Inserindo alguns usuários
// await db.insert("users").values({'name': 'Alice', 'age': 30});
// await db.insert("users").values({'name': 'Bob', 'age': 25});
// await db.insert("users").values({'name': 'Charlie', 'age': 35});

// // Inserindo alguns pedidos
// await db.insert("orders").values({'user_id': 1, 'total': 100});
// await db.insert("orders").values({'user_id': 1, 'total': 150});
// await db.insert("orders").values({'user_id': 2, 'total': 200});

// // Exemplos de filtros

// // eq: Seleciona usuários com age igual a 30
// final eqQuery = db.select().from("users").where(eq("users.age", 30));
// print("SQL eq:");
// print(eqQuery.toSql());
// print(await eqQuery);

// // ne: Seleciona usuários com age diferente de 30
// final neQuery = db.select().from("users").where(ne("users.age", 30));
// print("SQL ne:");
// print(neQuery.toSql());
// print(await neQuery);

// // gt: Seleciona usuários com age maior que 25
// final gtQuery = db.select().from("users").where(gt("users.age", 25));
// print("SQL gt:");
// print(gtQuery.toSql());
// print(await gtQuery);

// // gte: Seleciona usuários com age maior ou igual que 30
// final gteQuery = db.select().from("users").where(gte("users.age", 30));
// print("SQL gte:");
// print(gteQuery.toSql());
// print(await gteQuery);

// // lt: Seleciona usuários com age menor que 35
// final ltQuery = db.select().from("users").where(lt("users.age", 35));
// print("SQL lt:");
// print(ltQuery.toSql());
// print(await ltQuery);

// // lte: Seleciona usuários com age menor ou igual que 30
// final lteQuery = db.select().from("users").where(lte("users.age", 30));
// print("SQL lte:");
// print(lteQuery.toSql());
// print(await lteQuery);

// // exists: Seleciona usuários que possuem pedidos
// final subquery = db
// .select()
// .from("orders")
// .where(eq("orders.user_id", "users.id"));
// final existsQuery = db.select().from("users").where(exists(subquery));
// print("SQL exists:");
// print(existsQuery.toSql());
// print(await existsQuery);

// // notExists: Seleciona usuários que não possuem pedidos
// final notExistsQuery = db.select().from("users").where(notExists(subquery));
// print("SQL notExists:");
// print(notExistsQuery.toSql());
// print(await notExistsQuery);

// // isNull: Suponha que exista uma coluna opcional 'nickname'
// final isNullQuery = db.select().from("users").where(isNull("users.name"));
// print("SQL isNull:");
// print(isNullQuery.toSql());
// print(await isNullQuery);

// // isNotNull: Suponha que exista uma coluna opcional 'nickname'
// final isNotNullQuery = db
// .select()
// .from("users")
// .where(isNotNull("users.name"));
// print("SQL isNotNull:");
// print(isNotNullQuery.toSql());
// print(await isNotNullQuery);

// // inArray: Seleciona usuários com age em [25, 35]
// final inArrayQuery = db
// .select()
// .from("users")
// .where(inArray("users.age", [25, 35]));
// print("SQL inArray:");
// print(inArrayQuery.toSql());
// print(await inArrayQuery);

// // notInArray: Seleciona usuários com age que não estejam em [30]
// final notInArrayQuery = db
// .select()
// .from("users")
// .where(notInArray("users.age", [30]));
// print("SQL notInArray:");
// print(notInArrayQuery.toSql());
// print(await notInArrayQuery);

// // between: Seleciona usuários com age entre 26 e 34
// final betweenQuery = db
// .select()
// .from("users")
// .where(between("users.age", 26, 34));
// print("SQL between:");
// print(betweenQuery.toSql());
// print(await betweenQuery);

// // notBetween: Seleciona usuários com age fora do intervalo 26 e 34
// final notBetweenQuery = db
// .select()
// .from("users")
// .where(notBetween("users.age", 26, 34));
// print("SQL notBetween:");
// print(notBetweenQuery.toSql());
// print(await notBetweenQuery);

// // like: Seleciona usuários com nome contendo 'li'
// final likeQuery = db.select().from("users").where(like("users.name", "%li%"));
// print("SQL like:");
// print(likeQuery.toSql());
// print(await likeQuery);

// ilike: (em bancos que suportam ILIKE) similar ao like, Postgres
// final ilikeQuery = db
// .select()
// .from("users")
// .where(ilike("users.name", "%AL%"));
// print("SQL ilike:");
// print(ilikeQuery.toSql());
// print(await ilikeQuery);

// notIlike: Seleciona usuários com nome que não contenham 'bo' not supported in sqlite
// final notIlikeQuery = db
// .select()
// .from("users")
// .where(notIlike("users.name", "%bo%"));
// print("SQL notIlike:");
// print(notIlikeQuery.toSql());
// print(await notIlikeQuery);

// not: Seleciona usuários que NÃO tenham age igual a 30
// final notQuery = db.select().from("users").where(not(eq("users.age", 30)));
// print("SQL not:");
// print(notQuery.toSql());
// print(await notQuery);

// // and: Seleciona usuários com age > 25 e < 35
// final andQuery = db
// .select()
// .from("users")
// .where(and([gt("users.age", 25), lt("users.age", 35)]));
// print("SQL and:");
// print(andQuery.toSql());
// print(await andQuery);

// // or: Seleciona usuários com age < 25 ou age > 35
// final orQuery = db
// .select()
// .from("users")
// .where(or([lt("users.age", 25), gt("users.age", 35)]));
// print("SQL or:");
// print(orQuery.toSql());
// print(await orQuery);

// // JOINs com filtros: Exemplo de INNER JOIN entre users e orders onde total > 100
// final joinQuery = db
// .select()
// .from("users")
// .innerJoin("orders", eq("users.id", "orders.user_id"))
// .where(gt("orders.total", 100));
// print("SQL INNER JOIN com filtro:");
// print(joinQuery.toSql());
// print(await joinQuery);

final usersTable = sqliteTable('users', {
    'id': integer().primaryKey(autoIncrement: true),
    'name': text(),
});

// Definindo a tabela de perfil (relação 1:1 com usuários)
final profileInfo = sqliteTable('profile_info', {
    'id': integer().primaryKey(),
    'user_id': integer(columnName: 'user_id').references(() => 'users.id'),
    'bio': text(),
});

// Definindo a tabela de pets (para exemplificar os diferentes JOINs)
final petsTable = sqliteTable('pets', {
    'id': integer().primaryKey(autoIncrement: true),
    'owner_id': integer(columnName: 'owner_id').references(() => 'users.id'),
    'name': text(),
});

// Definindo a tabela de posts (relação muitos:1 - muitos posts por usuário)
final postsTable = sqliteTable('posts', {
    'id': integer().primaryKey(autoIncrement: true),
    'user_id': integer(columnName: 'user_id').references(() => 'users.id'),
    'content': text(),
});

// // Definindo relacionamentos para a tabela de usuários:
// // Relação one: cada usuário possui um profileInfo
// // Relação many: cada usuário possui vários posts
final usersRelations = relations(usersTable, (builder) => {
    'profileInfo': builder.one(
        'profile_info',
        fields: ['users.id'],
        references: ['profile_info.user_id'],
    ),
    'posts': builder.many(
        'posts',
        fields: ['users.id'],
        references: ['posts.user_id'],
    ),
  },
);

// // Instanciando Dartlize e incluindo apenas as tabelas com definições de coluna
// final dartlize = Dartlize("sqlite://database.db", [
// usersTable,
// profileInfo,
// petsTable,
// postsTable,
// usersRelations, // tabelas de relacionamento são meta-informação e não serão criadas no banco.
// ]);
// final db = await dartlize.sync();

// // Exemplos de INSERT:

// // Inserindo um usuário
// await db.insert("users").values({'name': 'Alice'});
// // Inserindo dados para profile_info (assumindo que o novo usuário tem id = 1)
// await db.insert("profile_info").values({
// 'user_id': 1,
// 'bio': 'Desenvolvedora apaixonada por Dart e Flutter!',
// });
// // Inserindo um pet para o usuário
// await db.insert("pets").values({'owner_id': 1, 'name': 'Bob, o Cachorro'});
// // Inserindo posts para o usuário
// await db.insert("posts").values({
// 'user_id': 1,
// 'content': 'Meu primeiro post!',
// });
// await db.insert("posts").values({
// 'user_id': 1,
// 'content': 'Explorando JOINs com Dartlize.',
// });

// // Exemplos de SELECT com JOINs:

// // Inner Join: usuários e posts (apenas onde houver correspondência)
// final innerJoinQuery = db
// .select()
// .from("users")
// .innerJoin("posts", eq("users.id", "posts.user_id"));
// print("SQL INNER JOIN (users + posts):");
// print(innerJoinQuery.toSql());
// final innerResult = await innerJoinQuery;
// print("Resultado INNER JOIN:");
// print(innerResult);

// // Left Join: usuários com pets (mostra todos os usuários mesmo sem pets)
// final leftJoinQuery = db
// .select()
// .from("users")
// .leftJoin("pets", eq("users.id", "pets.owner_id"));
// print("SQL LEFT JOIN (users + pets):");
// print(leftJoinQuery.toSql());
// final leftResult = await leftJoinQuery;
// print("Resultado LEFT JOIN:");
// print(leftResult);

// // Right Join: Usuários com pets (note: SQLite não suporta RIGHT JOIN nativamente,
// // mas o SQL é gerado conforme solicitado)
// final rightJoinQuery = db
// .select()
// .from("users")
// .rightJoin("pets", eq("users.id", "pets.owner_id"));
// print("SQL RIGHT JOIN (users + pets):");
// print(rightJoinQuery.toSql());
// final rightResult = await rightJoinQuery;
// print("Resultado RIGHT JOIN:");
// print(rightResult);

// // Full Join: Usuários com pets (SQLite não suporta FULL JOIN nativamente,
// // mas vamos gerar a query conforme solicitado para fins de demonstração)
// final fullJoinQuery = db
// .select()
// .from("users")
// .fullJoin("pets", eq("users.id", "pets.owner_id"));
// print("SQL FULL JOIN (users + pets):");
// print(fullJoinQuery.toSql());
// final fullResult = await fullJoinQuery;
// print("Resultado FULL JOIN:");
// print(fullResult);

// final usersTable = sqliteTable('users', {
// 'id': integer().primaryKey(autoIncrement: true),
// 'name': text(),
// });

// // Definição dos relacionamentos para a tabela de usuários.
// // Corrigido: Agora usamos o parâmetro "builder" e chamamos builder.one(...)
// final usersRelations = relations(
// usersTable,
// (builder) => {'profileInfo': builder.one('profile_info')},
// );

// // Definição da tabela de profile_info.
// final profileInfo = sqliteTable('profile_info', {
// 'id': integer().primaryKey(),
// 'userId': integer(columnName: 'user_id').references(() => 'users.id'),
// 'bio': text(),
// });

// // Exemplo de relacionamento para posts.
// final postsRelations = relations(
// 'posts',
// (builder) => {
// 'author': builder.one(
// 'users',
// fields: ['posts.authorId'],
// references: ['users.id'],
// ),
// },
// );

// // Instancia e sincroniza as tabelas usando Dartlize.
// // Note que as relações (do tipo RelationsTable) não serão criadas no banco,
// // garantindo que apenas as tabelas base sejam criadas.
// final dartlize = Dartlize("sqlite://database.db", [
// usersTable,
// profileInfo,
// usersRelations,
// postsRelations,
// ]);
// final db = await dartlize.sync();

// final users = await db.select().from("users");
// print(users);

// Exemplo: Inserção de um usuário.
// await db.insert("users").values({'name': 'Alice'});

// final selectQuery = db.select().from("users").where(eq('name', 'Alice'));
// print(selectQuery);

// final usersTable = sqliteTable("users", {
// 'id': integer().primaryKey(autoIncrement: true),
// 'name': text().notNull(),
// 'age': integer(),
// 'email': text().notNull().unique(),
// });

// final dartlize = Dartlize("sqlite://database.db", [usersTable]);
// final db = await dartlize.sync();

// await db.insert('users').values({
// 'name': 'John Doe',
// 'age': 30,
// 'email': 'john@mail.com',
// });

// var selectQuery = await db.select().from('users');

// await db
// .update('users')
// .set({'age': 31})
// .where(eq('users.email', 'john@mail.com'));

// selectQuery = await db.select().from('users');
// print(selectQuery);

// await db.insert('users').values({
// 'name': 'Evanderson',
// 'age': 32,
// 'email': 'evan@mail.com',
// });

// // Exemplo: Exclusão.
// final deleteQuery = db
// .delete('users')
// // Note: O método set() em delete não gera uma cláusula SET no SQL padrão;
// // ele pode ser utilizado para lógica customizada (ex: soft delete).
// .set({'age': 31})
// .where(eq('users.email', 'john@mail.com'));
// print("SQL gerado (DELETE): ${deleteQuery.toSql()}");
// await deleteQuery.execute();

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

  // final usersTable = sqliteTable('users', {
  //   'id': integer().primaryKey(autoIncrement: true),
  //   'name': text().notNull(),
  //   'email': text().notNull().unique(),
  // });
```
