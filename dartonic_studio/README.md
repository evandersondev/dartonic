# dartonic_studio

Lightweight HTTP backend for inspecting a Dartonic database. Add it to your app to explore tables and run queries from any REST client or browser.

## Installation

```yaml
dependencies:
  dartonic_studio:
    path: ../dartonic_studio   # or pub.dev version when published
```

## Starting Studio

```dart
import 'package:dartonic_sqlite/dartonic_sqlite.dart';
import 'package:dartonic_studio/dartonic_studio.dart';

void main() async {
  final db = await connectSqlite('app.db', schemas: [users, posts]);
  await startStudio(db, port: 4444);
  // Listening at http://localhost:4444
}
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `db` | `DartonicDb` | required | Connected database handle |
| `port` | `int` | `4444` | HTTP port |
| `host` | `String` | `'localhost'` | Bind address |

## Endpoints

### `GET /tables`

Returns a list of all registered table names.

```json
{ "tables": ["users", "posts"] }
```

### `GET /tables/:name`

Describes the columns of a table.

```json
{
  "table": "users",
  "columns": {
    "id":         { "type": "INTEGER", "modifiers": ["PRIMARY KEY AUTOINCREMENT"] },
    "email":      { "type": "TEXT",    "modifiers": ["NOT NULL", "UNIQUE"] },
    "created_at": { "type": "DATETIME","modifiers": ["DEFAULT CURRENT_TIMESTAMP"] }
  }
}
```

### `POST /query`

Executes a raw `SELECT` query. Only `SELECT` statements are allowed.

```json
{ "sql": "SELECT * FROM users LIMIT 10" }
```

Response:

```json
{ "rows": [...], "count": 10 }
```

## CORS

All endpoints include permissive CORS headers (`Access-Control-Allow-Origin: *`) so the API can be consumed from a browser or external UI.

## Security

- Only `SELECT` queries are accepted via `/query`
- Bind to `localhost` (default) to avoid exposing the endpoint on the network
- Do not run Studio in production
