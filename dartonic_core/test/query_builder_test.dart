import 'package:dartonic_core/dartonic_core.dart';
import 'package:test/test.dart';

import 'support/fake_driver.dart';
import 'support/schema.dart';

void main() {
  final users = UsersTable();
  final posts = PostsTable();
  late DatabaseFacade db;

  setUp(() => db = DatabaseFacade(FakeDriver(), dialect: Dialect.sqlite));

  group('SELECT', () {
    test('select() emits SELECT *', () {
      expect(db.select().from(users).toSql(), 'SELECT * FROM "users";');
    });

    test('explicit columns are aliased as table__column', () {
      expect(
        db.select([users.id, users.email]).from(users).toSql(),
        'SELECT "users"."id" AS "users__id", '
        '"users"."email" AS "users__email" FROM "users";',
      );
    });

    test('where clause binds parameters', () {
      final q = db.select().from(users).where(eq(users.id, 1));
      expect(q.toSql(), 'SELECT * FROM "users" WHERE "users"."id" = ?;');
      expect(q.getParameters(), [1]);
    });

    test('join + order + limit/offset', () {
      final q = db
          .select([posts.title, users.name])
          .from(posts)
          .innerJoin(users, eqCol(posts.userId, users.id))
          .orderBy(posts.id, Order.desc)
          .limit(10)
          .offset(5);
      final sql = q.toSql();
      expect(sql,
          contains('INNER JOIN "users" ON "posts"."user_id" = "users"."id"'));
      expect(sql, contains('ORDER BY "posts"."id" DESC'));
      expect(sql, contains('LIMIT 10 OFFSET 5'));
    });
  });

  group('INSERT', () {
    test('values emits columns + placeholders in order', () {
      final q = db.insert(users).values([
        users.email.value('a@b.com'),
        users.name.value('Alice'),
      ]);
      expect(q.toSql(), 'INSERT INTO "users" ("email", "name") VALUES (?, ?);');
      expect(q.getParameters(), ['a@b.com', 'Alice']);
    });

    test('boolean values encode to 1/0', () {
      final q = db.insert(users).values([
        users.email.value('a@b.com'),
        users.name.value('x'),
        users.active.value(true),
      ]);
      expect(q.getParameters(), ['a@b.com', 'x', 1]);
    });

    test('returning appends RETURNING *', () {
      final q = db.insert(users).values([
        users.email.value('a@b.com'),
        users.name.value('x'),
      ]).returning();
      expect(q.toSql(), endsWith('RETURNING *;'));
    });
  });

  group('UPDATE', () {
    test('set + where', () {
      final q =
          db.update(users).set([users.name.value('Bob')]).where(eq(users.id, 3));
      expect(q.toSql(), 'UPDATE "users" SET "name" = ? WHERE "users"."id" = ?;');
      expect(q.getParameters(), ['Bob', 3]);
    });
  });

  group('DELETE', () {
    test('delete + where', () {
      final q = db.delete(users).where(eq(users.id, 7));
      expect(q.toSql(), 'DELETE FROM "users" WHERE "users"."id" = ?;');
      expect(q.getParameters(), [7]);
    });
  });
}
