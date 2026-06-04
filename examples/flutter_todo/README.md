# flutter_todo

Flutter sample que persiste uma lista de tarefas usando Dartonic + SQLite.

## Como rodar

```bash
cd examples/flutter_todo
flutter pub get
flutter run
```

Roda em **Android, iOS, Linux, macOS e Windows**. Web requer um driver
diferente (a fazer: `dartonic_sqlite_web` via `sqlite3.wasm`).

## Como funciona

1. `lib/schema.dart` declara a tabela `todos` extendendo `Table`. Cada coluna é
   um `Column<T>` paramétrico — `id` é `Column<int>`, `title` é
   `Column<String>`, etc.
2. `lib/database.dart` resolve o caminho do banco via
   `path_provider.getApplicationDocumentsDirectory()` e abre a conexão com
   `connectSqlite()`. As migrações são carregadas de `assets/migrations/*.sql`
   via `rootBundle` e aplicadas pelo `MigrationRunner` (puro Dart, sem
   `dart:io`).
3. `lib/main.dart` mostra o CRUD: insert, update, delete, select — todos
   tipados (`db.insert(todos).values([todos.title.value('...'), ...])`).

## Dependências relevantes

- `dartonic_sqlite` — driver SQLite + reexporta `dartonic_core`.
- `sqlite3_flutter_libs` — empacota o binário nativo do SQLite no app.
- `path_provider` — resolve diretório de documentos do app.
