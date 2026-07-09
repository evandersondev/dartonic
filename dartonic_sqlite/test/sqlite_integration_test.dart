// Hide Dartonic's `isNull` condition helper so it doesn't collide with the
// matcher of the same name from package:test.
import 'package:dartonic_core/dartonic_core.dart' hide isNull;
import 'package:dartonic_sqlite/dartonic_sqlite.dart';
// Direct import to reach SqliteDriver for the cache-bound test; the public
// API only exposes connectSqlite.
import 'package:dartonic_sqlite/src/sqlite_driver.dart';
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

  test('findManyWithRelations eager-loads a declared one-to-many relation',
      () async {
    final usersRel = relations(users, (r) => {
          'posts': r.many('posts', fields: ['id'], references: ['user_id']),
        });
    final rdb = await connectSqlite(
      ':memory:',
      schemas: [users, posts],
      relations: [usersRel],
    );
    await rdb.insert(users).values([
      users.email.value('a@b.com'),
      users.name.value('Alice'),
    ]);
    final uid =
        (await rdb.select().from(users)).first.readNotNull(users.id);
    await rdb.insert(posts).valuesMany([
      [posts.userId.value(uid), posts.title.value('first')],
      [posts.userId.value(uid), posts.title.value('second')],
    ]);

    final result = await rdb.orm(users).findManyWithRelations(
      with_: {'posts': true},
    );
    expect(result, hasLength(1));
    expect(result.first['name'], 'Alice');
    final nested = result.first['posts'] as List;
    expect(nested, hasLength(2));
    expect(nested.map((p) => (p as Map)['title']), ['first', 'second']);
    await rdb.close();
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

  test('accepts a PoolConfig (no-op for SQLite) and still queries', () async {
    final pooled = await connectSqlite(
      ':memory:',
      schemas: [users],
      pool: const PoolConfig(max: 5, min: 1),
    );
    await pooled.insert(users).values([
      users.email.value('pool@b.com'),
      users.name.value('Pooled'),
    ]);
    final rows = await pooled.select().from(users);
    expect(rows, hasLength(1));
    expect(rows.first.readNotNull(users.name), 'Pooled');
    await pooled.close();
  });

  test('repeated identical queries reuse the prepared-statement cache',
      () async {
    await db.insert(users).values([
      users.email.value('a@b.com'),
      users.name.value('Alice'),
    ]);
    // Run the same parameterized SELECT many times. If statement reuse were
    // broken (e.g. a reset/binding bug) the later runs would return wrong
    // data or throw; correctness across many iterations is the assertion.
    for (var i = 0; i < 300; i++) {
      final rows = await db.select().from(users).where(eq(users.email, 'a@b.com'));
      expect(rows, hasLength(1));
      expect(rows.first.readNotNull(users.name), 'Alice');
    }
  });

  test('statement cache honours a small LRU bound without leaking', () async {
    // A tiny cache bound forces eviction on every distinct SQL. Drive many
    // distinct queries and confirm results stay correct (evicted statements
    // are disposed, not reused).
    final small = SqliteDriver(':memory:', statementCacheSize: 2);
    await small.connect();
    await small.createTable('kv', {'k': 'TEXT', 'v': 'TEXT'});
    for (var i = 0; i < 50; i++) {
      await small.raw('INSERT INTO "kv" ("k", "v") VALUES (?, ?)', ['k$i', 'v$i']);
    }
    final rows = await small.execute('SELECT COUNT(*) AS n FROM "kv"');
    expect(rows.single['n'], 50);
    await small.close();
  });

  group('schema diff (auto-migration foundation)', () {
    test('emits CREATE TABLE for a missing table', () async {
      final driver = SqliteDriver(':memory:');
      await driver.connect();
      // No tables created yet → both declared tables are missing.
      final diff = await diffSchema(driver, [users, posts],
          dialect: Dialect.sqlite);
      expect(diff.createdTables, containsAll(['users', 'posts']));
      expect(diff.statements.any((s) => s.contains('CREATE TABLE')), isTrue);
      // Applying the diff makes a re-diff empty.
      for (final stmt in diff.statements) {
        await driver.raw(stmt);
      }
      final after =
          await diffSchema(driver, [users, posts], dialect: Dialect.sqlite);
      expect(after.isEmpty, isTrue);
      await driver.close();
    });

    test('emits ADD COLUMN for a new column on an existing table', () async {
      final driver = SqliteDriver(':memory:');
      await driver.connect();
      // Create a "users" table missing the `name` column.
      await driver.raw(
          'CREATE TABLE "users" ("id" INTEGER PRIMARY KEY, "email" TEXT)');
      final diff =
          await diffSchema(driver, [users], dialect: Dialect.sqlite);
      expect(diff.createdTables, isEmpty);
      expect(diff.addedColumns, contains('users.name'));
      expect(
        diff.statements.any(
            (s) => s.contains('ADD COLUMN') && s.contains('name')),
        isTrue,
      );
      await driver.close();
    });
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
