<p align="center">
  <img src="./dartonic_core/assets/logo.png" width="200px" align="center" alt="Dartonic logo" />
</p>

<h1 align="center">Dartonic</h1>

<p align="center">
  Type-safe SQL for Dart, inspired by Drizzle ORM. No code generation. No <code>dynamic</code>.
</p>

---

This is the **Dartonic monorepo**. The project is split into focused packages so you
only depend on what you need: the driver-agnostic core, one package per database driver,
plus CLI and tooling.

The main, publishable package is **[`dartonic_core`](./dartonic_core)** — start there.

## Packages

| Package | Description |
| --- | --- |
| [`dartonic_core`](./dartonic_core) | Core query builder, schema DSL, conditions, relations, migrations and ORM. No driver dependencies. |
| [`dartonic_sqlite`](./dartonic_sqlite) | SQLite driver — `connectSqlite()`. |
| [`dartonic_postgres`](./dartonic_postgres) | PostgreSQL driver — `connectPostgres()`. |
| [`dartonic_mysql`](./dartonic_mysql) | MySQL driver — `connectMysql()`. |
| [`dartonic_migrations_fs`](./dartonic_migrations_fs) | Filesystem migration loader (reads `.sql` files in CLI/server environments). |
| [`dartonic_cli`](./dartonic_cli) | Official CLI — `init`, `migrate`, `generate`, `studio`. |
| [`dartonic_studio`](./dartonic_studio) | Studio backend — HTTP API to inspect tables and run queries. |

## Examples

Runnable projects live in [`examples/`](./examples):

- [`book_api_crud`](./examples/book_api_crud) — REST API with CRUD over SQLite.
- [`twitter_clone`](./examples/twitter_clone) — relations and repositories.
- [`flutter_todo`](./examples/flutter_todo) — Flutter app using Dartonic.
- [`manual_test`](./examples/manual_test) — scratchpad for manual testing.

## License

[MIT](./LICENSE)
