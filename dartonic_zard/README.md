# dartonic_zard

Bridge between [Dartonic](../dartonic_core) and [Zard](https://github.com/evandersondev/zard).
Define a table **once** with Dartonic and derive [zard](https://pub.dev/packages/zard)
validation schemas from it — the [`drizzle-zod`](https://orm.drizzle.team/docs/zod)
pattern, in Dart.

## Why

Without the bridge you declare each entity twice — a Dartonic table for the
database and a zard schema for request validation — and they can drift apart.
Here the **table is the single source of truth**; the schemas are derived.

## API

```dart
import 'package:dartonic_zard/dartonic_zard.dart'; // re-exports zard's `z` too

class UserSchema extends Table {
  final id        = integer('id').primaryKey(autoIncrement: true);
  final name      = text('name').notNull();
  final email     = text('email').notNull().unique();
  final age        = integer('age');                 // nullable
  final createdAt = timestamp('created_at').defaultNow();
}
final users = UserSchema();

final insertUser = createInsertSchema(users); // omits id; age & created_at optional
final selectUser = createSelectSchema(users); // every column; nullables .nullable()
final updateUser = createUpdateSchema(users); // every field optional (partial)
```

### Refining derived fields

`refine` overrides the *base* schema of named columns; presence rules
(required / optional / nullable) still come from the column metadata:

```dart
final signup = createInsertSchema(users, refine: {
  'email': z.string().email(),
  'name':  z.string().min(2).max(50),
});
```

## Type mapping

| Dartonic column | zard schema |
| --- | --- |
| `integer()` | `z.int()` |
| `text()` | `z.string()` |
| `real()` | `z.double()` |
| `boolean()` | `z.bool()` |
| `timestamp()` | `z.date()` |
| `uuid()` | `z.string().uuid()` |
| `json()` / `jsonMap()` | `z.map({})` (permissive) |
| `blob()` | `z.string()` (base64) |
| `pgEnum(...)` | `z.$enum([...])` |

Presence rules: auto-increment / auto-generate PKs are omitted from insert;
columns with a SQL `DEFAULT` or that are nullable become optional; `NOT NULL`
columns without a default stay required.

## Pair it with darto

The derived schema is a normal zard schema, so it plugs straight into
`darto_validator`'s `zValidator` and `darto_zard_openapi`'s `.openapiSchema()`
— one table drives the database, request validation and the OpenAPI document.
