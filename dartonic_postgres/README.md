# dartonic_postgres

PostgreSQL driver for Dartonic. Uses the [`postgres`](https://pub.dev/packages/postgres) package.

## Installation

```yaml
dependencies:
  dartonic_postgres:
    path: ../dartonic_postgres
```

## Connection

```dart
import 'package:dartonic_postgres/dartonic_postgres.dart';

final db = await connectPostgres(
  'postgres://user:password@localhost:5432/mydb',
  schemas: [users, posts],
);
```

URI format: `postgres://user:password@host:port/database?sslmode=require`

Supported `sslmode` values: `require`, `verify-full`, or omit for no SSL.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `uri` | `String` | required | PostgreSQL connection URI |
| `schemas` | `List<TableSchema>` | required | Tables to register |
| `views` | `List<ViewSchema>` | `[]` | Views to create |
| `relations` | `List<RelationsTable>` | `[]` | Relation join tables |
| `sync` | `bool` | `true` | Run `CREATE TABLE IF NOT EXISTS` on connect |

## Schema Definition

Use `pgTable` — validates that column types are PostgreSQL-compatible.

```dart
import 'package:dartonic_core/dartonic_core.dart';

final users = pgTable('users', {
  'id': serial().primaryKey(),
  'name': varchar(length: 255).notNull(),
  'email': text().notNull().unique(),
  'role': text().$default('user'),
  'created_at': timestamp().defaultNow(),
});

final posts = pgTable('posts', {
  'id': serial().primaryKey(),
  'user_id': integer().references(() => 'users.id'),
  'title': varchar(length: 500).notNull(),
  'body': text(),
});
```

## PostgreSQL Enums

```dart
final roleEnum = pgEnum('role', ['admin', 'user', 'guest']);

final users = pgTable('users', {
  'id': serial().primaryKey(),
  'role': roleEnum(),
});
```

## Usage

```dart
// SELECT with typed columns
final rows = await db.select({
  'id':    users.id,
  'email': users.email,
}).from(users);

// INSERT with RETURNING
final inserted = await db
    .insert(users)
    .values({'name': 'Alice', 'email': 'alice@example.com'})
    .returning();

// UPDATE
await db.update(users).set({'role': 'admin'}).where(eq(users.id, 1));

// JOIN
final rows = await db
    .select()
    .from(posts)
    .innerJoin(users, eq(posts.user_id, users.id))
    .where(eq(users.role, 'admin'));
```

## Parameterized Queries

`?` placeholders are automatically converted to `$1`, `$2`, ... for PostgreSQL.

## Migrations

```dart
await db.migrate(migrationsDir: 'db/migrations');
```

## Notes

- `AUTOINCREMENT` is stripped; use `SERIAL` / `BIGSERIAL` instead
- Full `RETURNING` support
- SSL: pass `?sslmode=require` in the URI
