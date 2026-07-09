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
final posts = pgTable('posts', {
  'id': uuid().primaryKey(autoGenerate: true),
  'title': text(),
  'user_id': uuid().references(() => 'users.id'),
});

// Criando a instância do Dartonic
final database = Dartonic(
  "postgres://postgres:postgres@localhost:5432/postgres",
  schemas: [users, posts],
);

Database db = database.instance;
