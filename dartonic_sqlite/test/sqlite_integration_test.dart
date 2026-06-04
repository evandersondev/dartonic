// Hide Dartonic's `isNull` condition helper so it doesn't collide with the
// matcher of the same name from package:test.
import 'package:dartonic_core/dartonic_core.dart' hide isNull;
import 'package:dartonic_sqlite/dartonic_sqlite.dart';
import 'package:test/test.dart';

class Users extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final email = text('email').notNull().unique();
  final name = text('name').notNull();
}

class Posts extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final userId = integer('user_id')
      .notNull()
      .references(() => users.id, onDelete: ReferentialAction.cascade);
  final title = text('title').notNull();
}

final users = Users();
final posts = Posts();

class User {
  final int id;
  final String email;
  final String name;
  User(this.id, this.email, this.name);
  static User fromRow(RowMap r) => User(
        r.readNotNull(users.id),
        r.readNotNull(users.email),
        r.readNotNull(users.name),
      );
}

class Post {
  final int id;
  final int userId;
  final String title;
  Post(this.id, this.userId, this.title);
  static Post fromRow(RowMap r) => Post(
        r.readNotNull(posts.id),
        r.readNotNull(posts.userId),
        r.readNotNull(posts.title),
      );
}

void main() {
  late DartonicDb db;

  setUp(() async {
    db = await connectSqlite(':memory:', schemas: [users, posts]);
  });

  tearDown(() async => db.close());

  test('insert + select round-trips', () async {
    await db.insert(users).values([
      users.email.value('a@b.com'),
      users.name.value('Alice'),
    ]);
    final rows = await db.select().from(users);
    expect(rows, hasLength(1));
    expect(rows.first.readNotNull(users.email), 'a@b.com');
    expect(rows.first.readNotNull(users.name), 'Alice');
  });

  test('insert ... returning gives the generated id', () async {
    final returned = await db.insert(users).values([
      users.email.value('a@b.com'),
      users.name.value('Alice'),
    ]).returning();
    expect(returned, hasLength(1));
    expect(returned.first.readNotNull(users.id), isPositive);
  });

  test('update and delete', () async {
    await db.insert(users).values([
      users.email.value('a@b.com'),
      users.name.value('Alice'),
    ]);
    await db.update(users).set([users.name.value('Bob')]).where(
        eq(users.email, 'a@b.com'));
    var rows = await db.select().from(users);
    expect(rows.first.readNotNull(users.name), 'Bob');

    await db.delete(users).where(eq(users.email, 'a@b.com'));
    rows = await db.select().from(users);
    expect(rows, isEmpty);
  });

  group('constraint errors map to typed exceptions', () {
    test('UNIQUE violation', () async {
      await db.insert(users).values([
        users.email.value('a@b.com'),
        users.name.value('Alice'),
      ]);
      expect(
        () => db.insert(users).values([
          users.email.value('a@b.com'),
          users.name.value('Other'),
        ]),
        throwsA(isA<UniqueViolationError>()),
      );
    });

    test('FOREIGN KEY violation', () async {
      expect(
        () => db.insert(posts).values([
          posts.userId.value(999),
          posts.title.value('orphan'),
        ]),
        throwsA(isA<ForeignKeyError>()),
      );
    });

    test('NOT NULL violation', () async {
      expect(
        () => db.insert(users).valuesRaw({'email': 'x@y.com', 'name': null}),
        throwsA(isA<NotNullViolationError>()),
      );
    });
  });

  group('transactions', () {
    test('commit persists', () async {
      await db.transaction((tx) async {
        await tx.insert(users).values([
          users.email.value('a@b.com'),
          users.name.value('Alice'),
        ]);
      });
      expect(await db.select().from(users), hasLength(1));
    });

    test('rollback() reverts the whole transaction', () async {
      await db.transaction((tx) async {
        await tx.insert(users).values([
          users.email.value('a@b.com'),
          users.name.value('Alice'),
        ]);
        tx.rollback();
      });
      expect(await db.select().from(users), isEmpty);
    });
  });

  test('findManyWith batches a one-to-many relation', () async {
    await db.insert(users).values([
      users.email.value('a@b.com'),
      users.name.value('Alice'),
    ]);
    final uid = (await db.select().from(users)).first.readNotNull(users.id);
    await db.insert(posts).valuesMany([
      [posts.userId.value(uid), posts.title.value('first')],
      [posts.userId.value(uid), posts.title.value('second')],
    ]);

    final result = await db.findManyWith<User, Post, int>(
      parent: users,
      parentDecoder: User.fromRow,
      parentKey: (u) => u.id,
      childTable: posts,
      childForeignKey: posts.userId,
      childDecoder: Post.fromRow,
    );
    expect(result, hasLength(1));
    expect(result.first.parent.name, 'Alice');
    expect(result.first.children.map((p) => p.title), ['first', 'second']);
  });

  test('migrate runs .sql migrations once', () async {
    final fresh = await connectSqlite(':memory:', schemas: const []);
    await fresh.migrate([
      Migration(
        name: '001_init.sql',
        sql: 'CREATE TABLE widget (id INTEGER PRIMARY KEY, label TEXT);',
      ),
      Migration(
        name: '002_seed.sql',
        sql: "INSERT INTO widget (label) VALUES ('hello');",
      ),
    ]);
    final rows = await fresh.rawQuery('SELECT label FROM widget');
    expect(rows.single['label'], 'hello');

    // Re-running is a no-op (already applied).
    await fresh.migrate([
      Migration(
        name: '002_seed.sql',
        sql: "INSERT INTO widget (label) VALUES ('hello');",
      ),
    ]);
    final after = await fresh.rawQuery('SELECT COUNT(*) AS n FROM widget');
    expect(after.single['n'], 1);
    await fresh.close();
  });
}
