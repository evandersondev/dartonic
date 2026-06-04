# relations_blog

A small but **layered** [darto](https://pub.dev/packages/darto) HTTP API that
demonstrates the **four kinds of table relations** in
[Dartonic](https://github.com/evandersondev/dartonic), with request validation
by [zard](https://pub.dev/packages/zard) and SQLite storage (`:memory:`).

## Project structure

```
bin/
  server.dart                  # entry point — bootstrap() + listen
lib/
  relations_blog.dart          # public barrel (exports bootstrap)
  src/
    app.dart                   # composition root: builds the DI container
    di.dart                    # darto_inject providers (db + repositories)
    config/
      database.dart            # opens the connection
    database/
      tables.dart              # Table classes + foreign keys (the schema)
      seed.dart                # initial data
    models/                    # plain Dart entities (User, Post, Profile, Group)
    repositories/              # data access — joins & relation loaders live here
      user_repository.dart
      post_repository.dart
      meta_repository.dart
    validators/                # zard request schemas
      user_validator.dart
    controllers/               # HTTP layer — parse, validate, map to JSON
      user_controller.dart
      post_controller.dart
      meta_controller.dart
```

Request flow: **controller** (HTTP) → **repository** (data access) →
**dartonic** (SQL). Models are the shared currency between layers; the
relation-loading details stay inside the repositories.

## Dependency injection (darto_inject)

Wiring is handled by [darto_inject](https://pub.dev/packages/darto_inject) in
[lib/src/di.dart](lib/src/di.dart):

- The database is an `AsyncProvider<DartonicDb>` (connecting + seeding is async).
- Each repository is an `AsyncProvider` that pulls the db via `di.readAsync(dbProvider)`.
- `bootstrap()` builds the container, calls `di.warmup()` (eagerly opens/seeds
  the DB), and attaches `di.middleware()` so every request gets a DI scope.
- Controllers resolve their repository per request with `await c.readAsync(...)`
  instead of receiving it through a constructor.

All providers are app-scoped, so the db and repositories are singletons built
once at startup.

## The data model

```
users ──1:1── profiles          (a user has one profile)
users ──1:N── posts             (a user has many posts / a post has one author)
users ──N:N── groups            (through the user_groups junction table)
```

Five tables are created from the schema (printed at startup and at
`GET /_tables`):

```
groups   posts   profiles   user_groups   users
```

## How relations are *defined* (schema layer)

Relations are **foreign keys**, declared on the column with `.references()` in
[lib/src/database/tables.dart](lib/src/database/tables.dart):

```dart
class PostsTable extends Table {
  final id     = integer('id').primaryKey(autoIncrement: true);
  final userId = integer('user_id')
      .notNull()
      .references(() => users.id, onDelete: ReferentialAction.cascade);
  final title  = text('title').notNull();
}
```

- **one-to-one** → the FK column is also `.unique()` (a user can't have two profiles).
- **one-to-many / many-to-one** → a single FK, read from either side.
- **many-to-many** → a junction table (`user_groups`) with one FK to each side.

`connectSqlite(..., sync: true)` (the default) issues `CREATE TABLE IF NOT
EXISTS` for every table in `allSchemas`, foreign keys included.

## How relations are *queried* (query layer)

There is no implicit `with:` — you pick how to load related rows. The query
details live in the **repositories**:

| Endpoint | Relation | How | Where |
|---|---|---|---|
| `GET /posts/:id` | many-to-one | `innerJoin` + `eqCol` | [post_repository.dart](lib/src/repositories/post_repository.dart) |
| `GET /users/:id/posts` | one-to-many | `findManyWith(...)` | [user_repository.dart](lib/src/repositories/user_repository.dart) |
| `GET /users/:id/profile` | one-to-one | `findManyWithOne(...)` | [user_repository.dart](lib/src/repositories/user_repository.dart) |
| `GET /users/:id/groups` | many-to-many | `findManyThrough(...)` | [user_repository.dart](lib/src/repositories/user_repository.dart) |
| `POST /users` | — | insert + zard validation | [user_controller.dart](lib/src/controllers/user_controller.dart) |
| `GET /_tables` | — | lists the created tables | [meta_repository.dart](lib/src/repositories/meta_repository.dart) |

## Run it

```bash
dart pub get
dart run bin/server.dart
```

Then:

```bash
curl localhost:3000/_tables
# {"tables":["groups","posts","profiles","user_groups","users"]}

curl localhost:3000/posts/1
# {"id":1,"title":"Hello world","author":{"id":1,"name":"Alice",...}}

curl localhost:3000/users/1/posts      # one-to-many
curl localhost:3000/users/1/profile    # one-to-one
curl localhost:3000/users/1/groups     # many-to-many

curl -X POST localhost:3000/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"Carol","email":"carol@acme.dev"}'

# invalid email -> 400 {"errors":["Invalid email format"]}
curl -X POST localhost:3000/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"X","email":"nope"}'
```

The database is in-memory, so it resets (and re-seeds) on every restart.
