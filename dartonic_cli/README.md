# dartonic_cli

Official CLI for Dartonic. Scaffolds projects, manages migrations, and launches Studio.

## Installation

```bash
dart pub global activate --source path dartonic_cli
```

Or run directly:

```bash
dart run dartonic_cli:dartonic <command>
```

## Commands

### `dartonic init`

Initialises Dartonic in the current project. Creates:

```
db/
  migrations/
    001_init.sql
  schema/
    schema.dart
```

```bash
dartonic init
```

### `dartonic migrate`

Lists or manages migration files.

```bash
# List pending .sql files
dartonic migrate

# Dry run — show files without running
dartonic migrate --dry-run

# Create a new migration file
dartonic migrate --create add_users_table
# Creates: db/migrations/1712345678_add_users_table.sql

# Use a custom migrations directory
dartonic migrate --dir path/to/migrations
```

To actually run migrations, call `db.migrate()` in your Dart app:

```dart
await db.sync();
await db.migrate(migrationsDir: 'db/migrations');
```

### `dartonic generate`

Displays guidance for generating typed model helpers from your schema.

```bash
dartonic generate
dartonic generate --schema db/schema/schema.dart
```

### `dartonic studio`

Prints instructions for starting Dartonic Studio locally.

```bash
dartonic studio
```

## Flags

| Flag | Command | Description |
|---|---|---|
| `--dir`, `-d` | migrate | Custom migrations directory |
| `--dry-run` | migrate | List pending files without running |
| `--create`, `-c` | migrate | Create a new migration file |
| `--schema`, `-s` | generate | Path to schema file |
