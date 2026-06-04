# dartonic_sqlite

SQLite driver for Dartonic. Uses the [`sqlite3`](https://pub.dev/packages/sqlite3) package.

## Installation

```yaml
dependencies:
  dartonic_sqlite:
    path: ../dartonic_sqlite
```

## Connection

```dart
import 'package:dartonic_sqlite/dartonic_sqlite.dart';

final db = await connectSqlite(
  'app.db',            // file path, or ':memory:' for in-memory
  schemas: [users, posts],
);
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `path` | `String` | required | File path or `:memory:` |
| `schemas` | `List<TableSchema>` | required | Tables to register |
| `views` | `List<ViewSchema>` | `[]` | Views to create |
| `relations` | `List<RelationsTable>` | `[]` | Relation join tables |
| `sync` | `bool` | `true` | Run `CREATE TABLE IF NOT EXISTS` on connect |

## Schema Definition

Use `sqliteTable` — validates that column types are SQLite-compatible (`INTEGER`, `TEXT`, `REAL`, `BLOB`, `DATETIME`).

```dart
import 'package:dartonic_core/dartonic_core.dart';

final users = sqliteTable('users', {
  'id': integer().primaryKey(autoIncrement: true),
  'name': text().notNull(),
  'email': text().notNull().unique(),
  'created_at': datetime().defaultNow(),
});

final posts = sqliteTable('posts', {
  'id': integer().primaryKey(autoIncrement: true),
  'user_id': integer().references(() => 'users.id'),
  'title': text().notNull(),
  'body': text(),
});
```

## Usage

```dart
// SELECT
final rows = await db.select().from(users);

// Typed SELECT
final rows = await db.select({
  'id':    users.id,
  'email': users.email,
}).from(users);

// INSERT
await db.insert(users).values({'name': 'Alice', 'email': 'alice@example.com'});

// UPDATE
await db.update(users).set({'name': 'Bob'}).where(eq(users.id, 1));

// DELETE
await db.delete(users).where(eq(users.id, 1));

// JOIN
await db
    .select()
    .from(posts)
    .innerJoin(users, eq(posts.user_id, users.id));

// Raw query
final rows = await db.rawQuery('SELECT * FROM users WHERE id = ?', [1]);
```

## Migrations

```dart
await db.migrate(migrationsDir: 'db/migrations');
```

## In-memory database

```dart
final db = await connectSqlite(':memory:', schemas: [users]);
```

## Notes

- Foreign keys are enabled automatically (`PRAGMA foreign_keys = ON`)
- `RETURNING` requires SQLite 3.35+
- `INTEGER PRIMARY KEY AUTOINCREMENT` mapped from `.primaryKey(autoIncrement: true)`
