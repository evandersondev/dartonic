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
| [`dartonic_migrations_fs`](./dartonic_migrations_fs) 🧪 _beta_ | Filesystem migration loader (reads `.sql` files in CLI/server environments). |
| [`dartonic_zard`](./dartonic_zard) | Bridge to [zard](https://github.com/evandersondev/zard) — derive validation schemas from tables (`createInsertSchema` / `createSelectSchema` / `createUpdateSchema`), drizzle-zod style. |
| [`dartonic_cli`](./dartonic_cli) 🧪 _beta_ | Official CLI — `init`, `migrate`, `generate`, `studio`. |
| [`dartonic_studio`](./dartonic_studio) 🧪 _beta_ | Studio backend — HTTP API to inspect tables and run queries. |
| [`dartonic-docs`](./dartonic-docs) | Documentation site (Vite + React). `bun install && bun run dev`; `bun run build` also generates `llms.txt`. |

### Connection pooling

Network drivers accept a `PoolConfig` — `connectPostgres(uri, schemas: [...], pool: PoolConfig(max: 20))`
(same for `connectMysql`). SQLite accepts it as a no-op for API symmetry.

### Publishing status

`dartonic_core` is publishable. The driver packages and `dartonic_zard` depend
on `dartonic_core` (and `zard`) via **path** dependencies, so they can only be
published to pub.dev after `dartonic_core` (and `zard`) are published there —
swap the path deps for version deps at that point. Run `dart pub publish --dry-run`
per package before publishing.

## Examples

Runnable projects live in [`examples/`](./examples):

- [`book_api_crud`](./examples/book_api_crud) — REST API with CRUD over SQLite.
- [`twitter_clone`](./examples/twitter_clone) — relations and repositories.
- [`flutter_todo`](./examples/flutter_todo) — Flutter app using Dartonic.
- [`manual_test`](./examples/manual_test) — scratchpad for manual testing.

## License

[MIT](./LICENSE)
