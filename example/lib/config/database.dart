import 'package:dartonic/dartonic.dart';

// final dartonic = Dartonic(
//   "sqlite::memory:",
//   schemas: [users],
//   views: [usersView],
// );

// extension QueryExtension on Query {
//   OrmTable get users => dartonic.table('users');
// }

final users = pgTable('users', {
  'id': uuid().primaryKey(autoGenerate: true),
  'name': text(),
});

// Tabela de posts
// final posts = pgTable('posts', {
//   'id': serial().primaryKey(),
//   'title': text(),
//   'user_id': integer().references(() => 'users.id'),
// });

// Criando a instância do Dartonic
final database = Dartonic(
  "postgres://postgres:postgres@localhost:5432/postgres",
  schemas: [users],
);

Database db = database.instance;
