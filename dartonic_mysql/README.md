# dartonic_mysql

MySQL driver for Dartonic. Uses the [`mysql1`](https://pub.dev/packages/mysql1) package.

## Installation

```yaml
dependencies:
  dartonic_mysql:
    path: ../dartonic_mysql
```

## Connection

```dart
import 'package:dartonic_mysql/dartonic_mysql.dart';

final db = await connectMysql(
  'mysql://user:password@localhost:3306/mydb',
  schemas: [users, posts],
);
```

URI format: `mysql://user:password@host:port/database`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `uri` | `String` | required | MySQL connection URI |
| `schemas` | `List<TableSchema>` | required | Tables to register |
| `views` | `List<ViewSchema>` | `[]` | Views to create |
| `relations` | `List<RelationsTable>` | `[]` | Relation join tables |
| `sync` | `bool` | `true` | Run `CREATE TABLE IF NOT EXISTS` on connect |

## Schema Definition

Use `mysqlTable` — validates that column types are MySQL-compatible.

```dart
import 'package:dartonic_core/dartonic_core.dart';

final users = mysqlTable('users', {
  'id': integer().primaryKey(autoIncrement: true),
  'name': varchar(length: 255).notNull(),
  'email': varchar(length: 255).notNull().unique(),
  'role': mysqlEnum(['admin', 'user', 'guest']).$default('user'),
  'created_at': datetime().defaultNow(),
});

final posts = mysqlTable('posts', {
  'id': integer().primaryKey(autoIncrement: true),
  'user_id': integer().references(() => 'users.id'),
  'title': varchar(length: 500).notNull(),
  'body': text(),
});
```

## Usage

```dart
// SELECT
final rows = await db.select({
  'id':    users.id,
  'email': users.email,
}).from(users);

// INSERT
await db.insert(users).values({'name': 'Alice', 'email': 'alice@example.com'});

// UPDATE
await db.update(users).set({'role': 'admin'}).where(eq(users.id, 1));

// DELETE
await db.delete(users).where(eq(users.id, 1));

// JOIN
await db
    .select()
    .from(posts)
    .innerJoin(users, eq(posts.user_id, users.id));
```

## Migrations

```dart
await db.migrate(migrationsDir: 'db/migrations');
```

## Notes

- `AUTOINCREMENT` is replaced automatically with `AUTO_INCREMENT`
- `RETURNING` is not supported — fetch inserted rows by ID with `rawQuery`
- Uses `?` placeholders (not `$n`)
