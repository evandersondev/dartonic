# dartonic_migrations_fs

Filesystem migration loader for [Dartonic](https://github.com/evandersondev/dartonic).

Reads `.sql` migration files from a directory so you can apply them with
`db.migrate(...)`. This package uses `dart:io`, so it's for **CLI / server /
desktop** runtimes. On Flutter, load migrations from assets via `rootBundle`
instead (see the core README).

## Install

```yaml
dependencies:
  dartonic_core: ^1.0.0
  dartonic_sqlite: ^1.0.0          # or dartonic_postgres / dartonic_mysql
  dartonic_migrations_fs: ^1.0.0
```

## Usage

Put your migrations in a directory, named so they sort in order:

```
db/migrations/
  001_init.sql
  002_add_users.sql
  003_add_posts.sql
```

Then load and apply them:

```dart
import 'package:dartonic_sqlite/dartonic_sqlite.dart';
import 'package:dartonic_migrations_fs/dartonic_migrations_fs.dart';

final db = await connectSqlite('app.db', schemas: [users, posts]);

await db.migrate(loadMigrationsFromDir('db/migrations'));
```

`loadMigrationsFromDir`:

- returns the `.sql` files sorted by filename (so the `NNN_` prefix controls order);
- ignores non-`.sql` files;
- returns an empty list when the directory doesn't exist.

Each file's name is recorded in the `__dartonic_migrations` table, so applied
migrations are skipped on subsequent runs.
