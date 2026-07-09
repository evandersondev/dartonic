<p align="center">
  <img src="./assets/logo.png" width="200px" align="center" alt="Dartonic logo" />
</p>

# dartonic_core

**Type-safe SQL for Dart. No code generation. No `dynamic`.**

`dartonic_core` is the driver-agnostic heart of Dartonic: the schema DSL,
typed query builder, conditions, relations, migrations and ORM helpers.
Inspired by Drizzle ORM, but built around Dart 3 generics so the analyzer
catches mistakes before you run anything.

📚 **Official documentation:** [dartonic.vercel.app](https://dartonic.vercel.app/)

### Support 💖

If you find Dartonic useful, please consider supporting its development 🌟 [Buy Me a Coffee](https://buymeacoffee.com/evandersondev). 🌟 Your support helps us improve the package and make it even better!

```dart
class UsersTable extends Table {
  final id        = integer('id').primaryKey(autoIncrement: true);
  final email     = text('email').notNull().unique();
  final name      = text('name').notNull();
  final createdAt = datetime('created_at').defaultNow();
}

final users = UsersTable();

final db = await connectSqlite(':memory:', schemas: [users]);

await db.insert(users).values([
  users.email.value('alice@example.com'),
  users.name.value('Alice'),
]);

final rows = await db.select().from(users).where(eq(users.id, 1));
final id   = rows.first.read(users.id);   // int?  — decoded via the column codec
```

`dartonic_core` ships no driver. Add one of the plugin packages and import
both:

```yaml
dependencies:
  dartonic_core: ^1.0.0
  dartonic_sqlite: ^1.0.0   # or dartonic_postgres / dartonic_mysql
```

```dart
import 'package:dartonic_core/dartonic_core.dart';      // schema, queries, types
import 'package:dartonic_sqlite/dartonic_sqlite.dart';  // connectSqlite()
```

---

## Table of contents

- [Core concepts](#core-concepts)
- [Defining a schema](#defining-a-schema)
  - [Table naming](#table-naming)
  - [Column types](#column-types)
  - [Column modifiers](#column-modifiers)
  - [Foreign keys](#foreign-keys)
  - [Indexes](#indexes)
- [Connecting](#connecting)
- [Reading data (SELECT)](#reading-data-select)
  - [RowMap and typed decoding](#rowmap-and-typed-decoding)
  - [Projections](#projections)
  - [Conditions](#conditions)
  - [Ordering, grouping, pagination](#ordering-grouping-pagination)
  - [Joins](#joins)
  - [Aggregates and HAVING](#aggregates-and-having)
  - [Subqueries](#subqueries)
  - [UNION](#union)
- [Writing data](#writing-data)
  - [Insert](#insert)
  - [Batch insert](#batch-insert)
  - [Upsert (ON CONFLICT)](#upsert-on-conflict)
  - [Update](#update)
  - [Delete](#delete)
  - [RETURNING](#returning)
- [Transactions](#transactions)
- [Relations](#relations)
  - [Many-to-one](#many-to-one)
  - [One-to-many](#one-to-many)
  - [One-to-one](#one-to-one)
  - [Many-to-many](#many-to-many)
- [ORM helpers](#orm-helpers)
- [CTEs](#ctes)
- [Views](#views)
- [Migrations](#migrations)
- [Raw SQL](#raw-sql)
- [Sharing the connection](#sharing-the-connection)

---

## Core concepts

| Type | What it is |
|---|---|
| `Table` | Base class for a schema. Subclass it; columns are collected automatically. |
| `Column<T>` | A typed column. `integer('id')` is a `Column<int>`, `text('x')` a `Column<String>`. |
| `ColumnRef<T>` | A typed reference used in conditions/projections. Every `Column<T>` is a `ColumnRef<T>`. |
| `ColumnValue<T>` | A column bound to a value for insert/update, via `column.value(v)`. |
| `Condition` | A boolean SQL fragment built by `eq`, `and`, `gt`, … |
| `RowMap` | A result row. `row.read(col)` decodes a cell back to its Dart type. |
| `DartonicDb` | The database handle returned by `connect*()`. Exposes all query methods. |
| `QueryBuilder` | The fluent builder returned by `select`/`insert`/`update`/`delete`. It *is* a `Future`. |

---

## Defining a schema

Subclass `Table` and declare each column as a `final` field. That's it — the
framework collects the columns for you (no list to maintain, no
`build_runner`).

```dart
class PostsTable extends Table {
  final id        = integer('id').primaryKey(autoIncrement: true);
  final userId    = integer('user_id').notNull();
  final title     = text('title').notNull();
  final body      = text('body');                       // nullable
  final published = boolean('published').notNull().withDefault(0);
  final createdAt  = datetime('created_at').defaultNow();
}

final posts = PostsTable();
```

`posts.id` is statically a `Column<int>`, `posts.title` a `Column<String>`,
and so on. The analyzer enforces these types throughout your queries.

### Table naming

By default the SQL table name is derived from the class name: the suffix
`Table`, `Tbl` or `Schema` is stripped and the rest is converted to
snake_case.

| Class | Table name |
|---|---|
| `UsersTable` | `users` |
| `BlogPostsTable` | `blog_posts` |
| `OrderItemSchema` | `order_item` |
| `User` | `user` |

Override `tableName` when you need a custom name:

```dart
class LegacyAccount extends Table {
  final id = integer('id').primaryKey();

  @override
  String get tableName => 'tb_legacy_account_v3';
}
```

### Column types

Each factory takes the SQL column name as its first argument and returns a
typed `Column<T>`.

| Factory | Dart type | SQL type |
|---|---|---|
| `integer(name)` | `int` | INTEGER |
| `serial(name)` / `smallserial` / `bigserial` | `int` | SERIAL family |
| `tinyint` / `smallint` / `bigint` / `mediumint` | `int` | sized ints |
| `text(name)` | `String` | TEXT |
| `varchar(name, length: 255)` | `String` | VARCHAR(n) |
| `char(name, length: 256)` | `String` | CHAR(n) |
| `boolean(name)` | `bool` | INTEGER (0/1) |
| `real(name, {precision, scale})` | `double` | REAL |
| `decimal` / `numeric` / `doubleColumn` / `doublePrecision` / `floatColumn` | `double` | numeric family |
| `datetime(name, {fsp, storage})` | `DateTime` | DATETIME |
| `date(name)` | `DateTime` | DATE |
| `timestamp(name, {precision, withTimezone, storage})` | `DateTime` | TIMESTAMP |
| `time(name, {fsp, withTimezone})` | `DateTime` | TIME |
| `uuid(name)` | `String` | UUID |
| `blob(name)` / `binary` / `varbinary(name, {length})` | `Uint8List` | BLOB family |
| `json<T>(name, decoder:, encoder:)` | `T` | JSON / JSONB |
| `jsonMap(name, {binary})` | `Map<String, Object?>` | JSON / JSONB |
| `pgEnum(name, values)(columnName)` | `String` | ENUM (Postgres) |

Each column carries its own **codec** — booleans round-trip as `0/1`,
`DateTime` as ISO-8601 text (or epoch ms, see `storage:`), JSON columns
serialize/deserialize automatically. Drivers never inspect column types
themselves.

#### `DateTime` storage strategy

```dart
datetime('created_at')                                    // ISO-8601 text (default)
datetime('logged_at', storage: DateTimeStorage.epochMs)   // integer epoch ms
datetime('seen_at',   storage: DateTimeStorage.native)    // pass through (Postgres)
```

#### Typed JSON columns

```dart
class SettingsTable extends Table {
  final id    = integer('id').primaryKey(autoIncrement: true);
  final prefs = jsonMap('prefs');                          // Map<String, Object?>
  final tags  = json<List<String>>(
    'tags',
    decoder: (raw) => (raw as List).cast<String>(),
    encoder: (value) => value,
  );
}
```

### Column modifiers

Fluent, chainable, and they refine the type where it matters:

```dart
integer('id').primaryKey(autoIncrement: true)   // serial PK
uuid('id').primaryKey(autoGenerate: true)        // auto-filled UUID v4 on insert
text('email').notNull().unique()
text('role').withDefault('guest')                // DEFAULT 'guest'
datetime('created_at').defaultNow()              // DEFAULT CURRENT_TIMESTAMP
integer('user_id').references(() => users.id)    // foreign key (see below)
```

### Foreign keys

Single-column foreign keys are declared inline on the column. Pass a **thunk**
(`() => target`) so the referenced table can be declared in any order:

```dart
class PostsTable extends Table {
  final id     = integer('id').primaryKey(autoIncrement: true);
  final userId = integer('user_id')
      .notNull()
      .references(() => users.id, onDelete: ReferentialAction.cascade);
  final title  = text('title').notNull();
}
```

`ReferentialAction` values: `cascade`, `restrict`, `noAction`, `setNull`,
`setDefault`.

For composite or table-level foreign keys, override `defineForeignKeys`:

```dart
class EnrollmentsTable extends Table {
  final studentId = integer('student_id').notNull();
  final courseId  = integer('course_id').notNull();

  @override
  List<ForeignKey> defineForeignKeys() => [
    ForeignKey.single(
      from: studentId,
      to: () => students.id,
      onDelete: ReferentialAction.cascade,
    ),
    ForeignKey(
      from: [courseId],
      to: () => [courses.id],
    ),
  ];
}
```

### Indexes

Override `defineIndexes`. Indexes are materialized during `db.sync()` via
`CREATE [UNIQUE] INDEX IF NOT EXISTS`.

```dart
class UsersTable extends Table {
  final id        = integer('id').primaryKey(autoIncrement: true);
  final email     = text('email').notNull();
  final createdAt = datetime('created_at').defaultNow();

  @override
  List<Index> defineIndexes() => [
    index('idx_users_created_at').on([createdAt]),
    uniqueIndex('idx_users_email').on([email]),
    // Partial index (SQLite / Postgres). Predicate values are inlined as
    // literals — partial indexes can't use bind parameters.
    index('idx_active_users').on([email], where: isNotNull(createdAt)),
  ];
}
```

---

## Connecting

```dart
final db = await connectSqlite('app.db', schemas: [users, posts]);
final db = await connectPostgres('postgres://u:p@host:5432/db', schemas: [...]);
final db = await connectMysql('mysql://u:p@host:3306/db', schemas: [...]);
```

Common parameters:

| Parameter | Meaning |
|---|---|
| `schemas` | List of `Table` instances. |
| `views` | List of `ViewSchema` (see [Views](#views)). |
| `relations` | List of `RelationsTable`. |
| `sync` | When `true` (default), runs `CREATE TABLE / INDEX / VIEW IF NOT EXISTS`. |

The connector also validates that every column type is supported by the
target dialect, throwing a clear error otherwise (e.g. `SERIAL` on SQLite).

### Closing the connection

Call `db.close()` when you're done (e.g. on app shutdown) to release the
underlying socket (Postgres/MySQL) or file handle (SQLite):

```dart
final db = await connectSqlite('app.db', schemas: [users]);
try {
  // ... use the database ...
} finally {
  await db.close();
}
```

---

## Reading data (SELECT)

A `QueryBuilder` *is* a `Future<List<RowMap>>`, so `await` it directly.

```dart
final rows = await db.select().from(users);                 // SELECT *
```

### RowMap and typed decoding

Each result row is a `RowMap`. Read a cell by passing the column — the value
comes back decoded to that column's Dart type:

```dart
for (final row in rows) {
  final int?    id    = row.read(users.id);       // null if missing/NULL
  final String  email = row.readNotNull(users.email); // throws if null
}
```

Map a whole result set into your own model with `.rows(decoder)`:

```dart
class User {
  final int id;
  final String email;
  const User({required this.id, required this.email});

  factory User.fromRow(RowMap row) => User(
    id:    row.readNotNull(users.id),
    email: row.readNotNull(users.email),
  );
}

final List<User> list = await db.select().from(users).rows(User.fromRow);
```

For a single row use `.first()` (adds `LIMIT 1`, returns `RowMap?`):

```dart
final row = await db.select().from(users).where(eq(users.id, 1)).first();
final user = row == null ? null : User.fromRow(row);
```

`row.raw` exposes the underlying `Map<String, Object?>` if you need it.

### Projections

`select()` accepts three forms:

```dart
// 1. SELECT *
db.select().from(users);

// 2. Explicit columns / expressions
db.select([users.id, users.email]).from(users);

// 3. Aliased projection (Drizzle-style map)
db.select({
  'id':    users.id,
  'total': sum(orders.total),
}).from(orders);
```

### Conditions

All condition helpers are typed: `eq(users.id, 'x')` won't compile because
`users.id` is `Column<int>`.

```dart
eq(users.id, 1)                       // col = ?
ne(users.status, 'inactive')          // col <> ?
gt(users.age, 18)                     // col > ?     (gte, lt, lte too)
isNull(users.deletedAt)               // col IS NULL
isNotNull(users.email)                // col IS NOT NULL
inArray(users.role, ['admin', 'mod']) // col IN (?, ?)
notInArray(users.role, ['banned'])    // col NOT IN (?)
between(users.age, 18, 65)            // col BETWEEN ? AND ?
notBetween(users.age, 0, 17)
like(users.name, 'Al%')               // text only
ilike(users.email, '%@x.com')         // text only
not(eq(users.id, 0))                  // NOT (...)
and([eq(users.active, true), gt(users.age, 18)])
or([eq(users.role, 'admin'), eq(users.role, 'mod')])

// Compare two columns:
eqCol(posts.userId, users.id)         // a = b
neCol(posts.userId, users.id)         // a <> b
```

### Ordering, grouping, pagination

```dart
db.select()
  .from(users)
  .orderBy(users.createdAt, Order.desc)   // Order.asc is the default
  .limit(20)
  .offset(40);

db.select({'role': users.role, 'n': countAll()})
  .from(users)
  .groupBy([users.role]);
```

### Joins

`innerJoin`, `leftJoin`, `rightJoin`, `fullJoin` — each takes a `Table` and a
`Condition` (use `eqCol` to compare two columns):

```dart
final feed = await db
  .select({
    'id':       posts.id,
    'content':  posts.body,
    'username': users.name,
  })
  .from(posts)
  .innerJoin(users, eqCol(posts.userId, users.id))
  .orderBy(posts.createdAt, Order.desc)
  .rows(PostWithAuthor.fromRow);
```

In the decoder, read joined columns through their own table refs:
`row.readNotNull(users.name)`.

### Aggregates and HAVING

Aggregate helpers return a `SqlExpression`:

```dart
countAll()                       // COUNT(*)
count(users.id)                  // COUNT("users"."id")
count(users.id, distinct: true)  // COUNT(DISTINCT …)
sum(orders.total)                // SUM(…)   (num columns)
avg(orders.total)                // AVG(…)
max(orders.total)                // MAX(…)
min(orders.total)                // MIN(…)
```

For `HAVING` over an aggregate, use the `*Expr` condition helpers (they take a
`SqlExpression` on the left):

```dart
final big = await db
  .select({'customer': orders.customer, 'total': sum(orders.total)})
  .from(orders)
  .groupBy([orders.customer])
  .having(gtExpr(sum(orders.total), 100));   // HAVING SUM(total) > ?
```

`*Expr` variants: `eqExpr`, `neExpr`, `gtExpr`, `gteExpr`, `ltExpr`, `lteExpr`.

### Subqueries

Compare a column against a subquery (`QueryBuilder`):

```dart
final avgQ = db.select([avg(orders.total)]).from(orders);

final aboveAvg = await db
  .select()
  .from(orders)
  .where(gtSubquery<double>(orders.total, avgQ));   // total > (SELECT AVG…)

final cancelledCustomers = db
  .select([orders.customer])
  .from(orders)
  .where(eq(orders.status, 'cancelled'));

final affected = await db
  .select()
  .from(orders)
  .where(inSubquery<String>(orders.customer, cancelledCustomers));
```

Subquery helpers: `eqSubquery`, `neSubquery`, `gtSubquery`, `gteSubquery`,
`ltSubquery`, `lteSubquery`, `inSubquery`, `notInSubquery`, plus `exists` /
`notExists` which take a `QueryBuilder` directly.

### UNION

```dart
db.select().from(users).union(db.select().from(admins));
```

---

## Writing data

### Insert

Pass a list of `ColumnValue`s built with `column.value(...)` — each value is
type-checked against its column:

```dart
await db.insert(users).values([
  users.email.value('alice@example.com'),
  users.name.value('Alice'),
  // omit columns with defaults / autoincrement
]);
```

For dynamic shapes (forms, imports) where you don't have the columns at
compile time, use `valuesRaw`:

```dart
await db.insert(users).valuesRaw({'email': 'a@b.com', 'name': 'A'});
```

### Batch insert

One statement, many rows. Every row must use the same column set:

```dart
await db.insert(users).valuesMany([
  [users.email.value('a@b.com'), users.name.value('Alice')],
  [users.email.value('c@d.com'), users.name.value('Bob')],
  [users.email.value('e@f.com'), users.name.value('Carol')],
]);
// INSERT INTO "users" ("email", "name") VALUES (?,?),(?,?),(?,?);
```

### Upsert (ON CONFLICT)

```dart
// Insert, or update name when the email already exists:
await db.insert(users).values([
  users.email.value('a@b.com'),
  users.name.value('Alice'),
]).onConflictDoUpdate(
  target: [users.email],
  set:    [users.name.value('Alice Updated')],
);

// Insert, or do nothing on conflict:
await db.insert(users).values([...]).onConflictDoNothing(target: [users.email]);
```

The correct dialect is emitted automatically: `ON CONFLICT (…) DO UPDATE` for
SQLite/Postgres, `ON DUPLICATE KEY UPDATE` for MySQL.

### Update

```dart
await db.update(users)
  .set([users.name.value('Bob')])
  .where(eq(users.id, 1));

// Dynamic shape:
await db.update(users).setRaw({'name': 'Bob'}).where(eq(users.id, 1));
```

### Delete

```dart
await db.delete(users).where(eq(users.id, 1));
```

> There is no `.execute()` — `await` the builder and it runs. For
> INSERT/UPDATE/DELETE without `.returning()`, the awaited result is an empty
> list you can ignore.

### RETURNING

```dart
final inserted = await db.insert(users)
  .values([users.email.value('a@b.com'), users.name.value('A')])
  .returning([users.id, users.email]);     // List<RowMap>

final newId = inserted.first.read(users.id);

// Shortcut for the id column:
await db.insert(users).values([...]).returningId();
```

---

## Transactions

```dart
await db.transaction((tx) async {
  await tx.insert(accounts).values([
    accounts.owner.value('Alice'),
    accounts.balance.value(1000),
  ]);
  await tx.update(accounts)
      .set([accounts.balance.value(900)])
      .where(eq(accounts.id, 1));

  // Roll back without throwing to the caller:
  // tx.rollback();
});
```

Any thrown exception rolls the transaction back and rethrows. Throwing
`TransactionRollback` (via `tx.rollback()`) rolls back silently.

---

## Relations

Dartonic models relationships in **two independent layers**:

1. **Schema layer — foreign keys.** Declare how tables reference each other so
   the database enforces referential integrity and `ON DELETE` / `ON UPDATE`
   behavior. See [Foreign keys](#foreign-keys).
2. **Query layer — loading related rows.** There is no code generation and no
   implicit `with:`. You choose *how* to fetch related data: a **JOIN** (one
   query, flat rows) or a **typed loader** (`findManyWith` / `findManyWithOne` /
   `findManyThrough`) that batches the classic N+1 into a fixed number of
   queries and returns grouped objects.

The loaders don't require a foreign key (they take explicit columns), but
declaring one is recommended for integrity. The decoder callbacks
(`Type.fromRow`) are the same ones described in
[RowMap and typed decoding](#rowmap-and-typed-decoding).

| Relationship | Declare in schema | Load at query time |
|---|---|---|
| **many-to-one** — a post → its one author | FK on the child: `posts.userId → users.id` | JOIN |
| **one-to-many** — an author → their posts | the same FK, from the parent side | `findManyWith` |
| **one-to-one** — a user → their profile | FK + `UNIQUE` on the child | `findManyWithOne` |
| **many-to-many** — users ↔ groups | a junction table with two FKs | `findManyThrough` |

All four start from a foreign key. Single-column FKs are declared inline with
`references()`; composite/table-level FKs use `defineForeignKeys()` — see
[Foreign keys](#foreign-keys):

```dart
class PostsTable extends Table {
  final id     = integer('id').primaryKey(autoIncrement: true);
  final userId = integer('user_id')
      .notNull()
      .references(() => users.id, onDelete: ReferentialAction.cascade);
  final title  = text('title').notNull();
}
```

### Many-to-one

A child belongs to a single parent (each post has one author). Load both sides
with a JOIN, projecting the columns you need from each table:

```dart
final rows = await db
    .select([posts.id, posts.title, users.name])
    .from(posts)
    .innerJoin(users, eqCol(posts.userId, users.id));

for (final r in rows) {
  print('${r.readNotNull(posts.title)} — by ${r.readNotNull(users.name)}');
}
```

Use `leftJoin` if the foreign key is nullable and you still want children that
have no parent. (See [Joins](#joins) for all join types.)

### One-to-many

A parent has many children (an author has many posts). `findManyWith` runs
**two** queries — parents, then all their children via a batched `IN (…)` —
and groups them:

```dart
final usersWithPosts = await db.findManyWith<User, Post, int>(
  parent:          users,
  parentDecoder:   User.fromRow,
  parentKey:       (u) => u.id,
  childTable:      posts,
  childForeignKey: posts.userId,    // ColumnRef<int>
  childDecoder:    Post.fromRow,
  // where: eq(users.active, true), // optional filter on parents
);
// Type: List<WithChildren<User, Post>>

for (final entry in usersWithPosts) {
  print('${entry.parent.email}: ${entry.children.length} posts');
}
```

### One-to-one

A parent has at most one child (a user has one profile — enforce it with
`UNIQUE` on the child's FK column). `findManyWithOne` is the one-to-many loader
that keeps the first child:

```dart
final usersWithProfile = await db.findManyWithOne<User, Profile, int>(
  parent:          users,
  parentDecoder:   User.fromRow,
  parentKey:       (u) => u.id,
  childTable:      profiles,
  childForeignKey: profiles.userId,
  childDecoder:    Profile.fromRow,
);
// Type: List<WithOne<User, Profile>>  (child may be null)
```

### Many-to-many

Two tables related through a **junction table** that holds a foreign key to
each side (`user_groups` with `user_id` and `group_id`). `findManyThrough`
runs **three** queries — parents, junction rows, children — and groups them:

```dart
final usersWithGroups = await db.findManyThrough<User, Group, int, int>(
  parent:            users,
  parentDecoder:     User.fromRow,
  parentKey:         (u) => u.id,
  junction:          userGroups,
  junctionParentKey: userGroups.userId,    // ColumnRef<int>
  junctionChildKey:  userGroups.groupId,   // ColumnRef<int>
  child:             groups,
  childKey:          groups.id,            // ColumnRef<int>
  childDecoder:      Group.fromRow,
);
// Type: List<WithChildren<User, Group>>
```

---

## ORM helpers

`db.orm(table)` returns a small convenience wrapper:

```dart
final repo = db.orm(users);

final all     = await repo.findMany();
final paged   = await repo.findMany(limit: 10, offset: 20);
final active  = await repo.findMany(where: eq(users.active, true));
final sorted  = await repo.findMany(orderBy: users.createdAt, order: Order.desc);
final one     = await repo.findFirst(where: eq(users.email, 'a@b.com'));
final byId    = await repo.findById<int>(42, idColumn: users.id);

// Decode in one step:
final models  = await repo.mapMany(User.fromRow, where: eq(users.active, true));
```

`findMany` / `findFirst` return `RowMap`(s); decode with `row.read(col)` or
`mapMany`.

---

## CTEs

```dart
final bigOrders = db.withCte('big_orders').as(
  db.select().from(orders).where(gt(orders.total, 100.0)),
);

final rows = await db.fromCte(bigOrders);   // SELECT * FROM "big_orders"
```

Parameters from the inner query are carried through automatically.

---

## Views

Declare a view and pass it to the connector. It's created during `sync()`.
Predicate values are inlined as literals (engines reject bind parameters in
`CREATE VIEW`).

```dart
final activeOrders = sqliteView('active_orders').as((qb) => qb
    .select([orders.id, orders.customer, orders.total])
    .from(orders)
    .where(eq(orders.status, 'active')));

final db = await connectSqlite(
  ':memory:',
  schemas: [orders],
  views: [activeOrders],
);

final rows = await db.rawQuery('SELECT * FROM "active_orders"');
```

Use `pgView` / `mysqlView` for the other dialects.

---

## Migrations

`MigrationRunner` is data-driven and pure Dart (no `dart:io` in the core), so
it works on Flutter too. Pass a list of `Migration`s:

```dart
await db.migrate([
  Migration(name: '001_init.sql', sql: '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL UNIQUE
    );
  '''),
  Migration(name: '002_add_posts.sql', sql: '...'),
]);
```

Executed migrations are tracked in `__dartonic_migrations` and run only once,
in order.

- **CLI / server**: load `.sql` files from disk with the optional
  `dartonic_migrations_fs` package:

  ```dart
  import 'package:dartonic_migrations_fs/dartonic_migrations_fs.dart';
  await db.migrate(loadMigrationsFromDir('db/migrations'));
  ```

- **Flutter**: load from assets via `rootBundle.loadString(...)` and build the
  `Migration` list yourself.

`db.sync()` (run automatically by the connectors unless `sync: false`) is the
schema-first alternative: it issues `CREATE TABLE / INDEX / VIEW IF NOT
EXISTS` from your `Table` definitions.

---

## Raw SQL

When the builder doesn't cover something, drop down to raw SQL:

```dart
final rows = await db.rawQuery(
  'SELECT * FROM users WHERE email LIKE ?',
  ['%@example.com'],
);
// rows: List<Map<String, Object?>>  (undecoded)
```

---

## Sharing the connection

Open **one** connection per process and share it — never call `connect*()`
more than once (with `:memory:` each call is a fresh, empty database).

```dart
// db.dart
late final DartonicDb db;

Future<void> initDatabase() async {
  db = await connectSqlite('app.db', schemas: [users, posts]);
}
```

```dart
// main.dart
Future<void> main() async {
  await initDatabase();          // once, at startup
  final all = await db.select().from(users);
}
```

Any other file just imports `db.dart` and uses the shared `db`. Dependency
injection (passing `DartonicDb` into repositories) works equally well for
larger apps.
