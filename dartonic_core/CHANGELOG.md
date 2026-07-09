## 1.0.0

First stable release of the modular Dartonic ecosystem. `dartonic_core` is the
driver-agnostic foundation — pair it with a driver package (`dartonic_sqlite`,
`dartonic_postgres` or `dartonic_mysql`).

> This package is the successor to the legacy all-in-one
> [`dartonic`](https://pub.dev/packages/dartonic) package.

### Features

- **Schema DSL** — define tables as classes with typed columns
  (`integer`, `text`, `real`, `boolean`, `datetime`, `blob`, `json`, `uuid`,
  Postgres `pgEnum`), constraints (`primaryKey`, `notNull`, `unique`,
  `references`), defaults (`default`, `defaultNow`) and indexes.
- **Type-safe query builder** — `select`/`insert`/`update`/`delete` with a
  composable condition API (`eq`, `gt`, `lt`, `like`, `inArray`, `and`, `or`,
  `isNull`, …), joins, `orderBy`, `limit`/`offset`, aggregates and `groupBy`/
  `having`.
- **ORM helpers** — `findMany`, `findFirst`, `findById`, and declarative
  relation loading for one-to-many, one-to-one and many-to-many.
- **Mutations** — `returning()`, batch insert, and upsert.
- **Transactions** — `transaction()` with automatic commit/rollback.
- **Migrations** — programmatic runner and schema diffing (`diffSchema`).
- **Typed errors** — `DatabaseError` hierarchy (`UniqueViolationError`,
  `ForeignKeyError`, `NotNullViolationError`, `ConnectionError`, …) so callers
  can map failures to meaningful responses.
- **Driver-agnostic core** — no database dependencies; drivers plug in via the
  driver interfaces. Network drivers support connection pooling through
  `PoolConfig`.
