# Twitter Clone — Dartonic Example

A minimal Twitter-like backend built with Dartonic and SQLite. Demonstrates real-world usage of the typed query builder, JOIN queries, and the repository pattern.

## What it covers

- Schema definition with foreign keys
- INSERT / SELECT / UPDATE / DELETE
- Typed column access via `table['column']`
- JOIN query returning a structured model
- Type-safe conditions with `eq`, `like`, etc.
- `.as(Model.fromJson)` for typed results
- Repository pattern with clean separation

## Structure

```
lib/
  db/
    schema.dart       — table definitions (users + posts)
    database.dart     — connectSqlite() wrapper
  models/
    user.dart         — User model
    post.dart         — Post and PostWithAuthor models
  repositories/
    user_repository.dart  — findAll, findByUsername, create, update, delete
    post_repository.dart  — timeline (JOIN), findByUsername, create, delete
  main.dart           — seed data + example output
```

## Run

```bash
cd examples/twitter_clone
dart pub get
dart run lib/main.dart
```

Expected output:

```
── Timeline (4 posts) ─────────────────────
  @carol: "Testing Dartonic with PostgreSQL next — fingers crossed!"
  @bob: "Finally a Dart ORM that feels like Drizzle. Love it."
  @alice: "Joins, conditions, and migrations. All in one package."
  @alice: "Just shipped Dartonic — type-safe SQL for Dart with zero codegen 🚀"

── @alice's posts (2) ─────────────────────
  @alice: "Joins, conditions, and migrations. All in one package."
  @alice: "Just shipped Dartonic — type-safe SQL for Dart with zero codegen 🚀"

── All users (3) ──────────────────────────
  @alice (Alice Smith) — Dart developer. Building things with Dartonic.
  @bob (Bob Jones) — Flutter enthusiast.
  @carol (Carol Wu)

── Updated carol ──────────────────────────
  @carol (Carol Wu) — PostgreSQL results: 🎉 works great!
```

## Key patterns

### Typed column access

```dart
// Use table['column'] for analyzer-safe typed access
.where(eq(users['username'], 'alice'))
.orderBy(posts['created_at'], 'DESC')
```

### JOIN query with typed result

```dart
final posts = await db
  .select({
    'id':           posts['id'],
    'content':      posts['content'],
    'created_at':   posts['created_at'],
    'username':     users['username'],
    'display_name': users['display_name'],
  })
  .from(posts)
  .innerJoin(users, eq(posts['user_id'], users['id']))
  .orderBy(posts['created_at'], 'DESC')
  .as(PostWithAuthor.fromJson);  // → List<PostWithAuthor>
```

### Repository pattern

```dart
class PostRepository {
  final DartonicDb db;
  const PostRepository(this.db);

  Future<List<PostWithAuthor>> timeline() => db
    .select({...})
    .from(posts)
    .innerJoin(users, eq(posts['user_id'], users['id']))
    .as(PostWithAuthor.fromJson);
}
```

## Switch to a real database

Change `openDatabase()` in `lib/db/database.dart`:

```dart
// Persistent SQLite file
Future<DartonicDb> openDatabase() =>
    connectSqlite('twitter.db', schemas: [users, posts]);

// PostgreSQL
import 'package:dartonic_postgres/dartonic_postgres.dart';
Future<DartonicDb> openDatabase() => connectPostgres(
  'postgres://user:pass@localhost:5432/twitter',
  schemas: [users, posts],
);
```
