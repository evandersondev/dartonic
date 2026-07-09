export type Lang = "en" | "pt";

export type Block =
  | { kind: "p"; text: string }
  | { kind: "code"; lang?: "dart" | "yaml" | "sh" | "html"; code: string; filename?: string }
  | { kind: "h3"; text: string; id?: string }
  | { kind: "ul"; items: string[] }
  | { kind: "table"; headers: string[]; rows: string[][] }
  | { kind: "note"; text: string }
  | { kind: "callout"; variant: "tip" | "warning" | "success"; text: string }
  | { kind: "links"; links: { label: string; href: string }[] }
  | { kind: "ref"; to: string; label: string };

export type Group =
  | "start"
  | "schema"
  | "connections"
  | "queries"
  | "mutations"
  | "transactions"
  | "relations"
  | "advanced"
  | "migrations"
  | "tooling"
  | "validation"
  | "errors"
  | "examples"
  | "reference";

export interface DocSection {
  id: string;
  title: string;
  group: Group;
  blocks: Block[];
  /** Marks a section whose package is still in beta (pre-1.0, API may change). */
  beta?: boolean;
}

type Bi<T> = { en: T; pt: T };
const bi = <T>(en: T, pt: T): Bi<T> => ({ en, pt });

interface BiSection {
  id: string;
  group: Group;
  title: Bi<string>;
  blocks: Bi<Block[]>;
  beta?: boolean;
}

const SECTIONS: BiSection[] = [
  // ────────────────────────────── START ──────────────────────────────
  {
    id: "overview",
    group: "start",
    title: bi("Overview", "Visão geral"),
    blocks: bi(
      [
        { kind: "p", text: "Dartonic is a type-safe SQL query builder and ORM for Dart, inspired by Drizzle ORM. You define your schema once as plain Dart classes and query SQLite, PostgreSQL and MySQL through one fluent, fully-typed API — with no code generation and no dynamic." },
        { kind: "h3", text: "Design principles" },
        { kind: "ul", items: [
          "No code generation — tables are plain Dart classes, no build_runner.",
          "Type-safe — typed columns, typed conditions, typed rows.",
          "Injection-safe — every value goes through parameterized queries.",
          "Driver-agnostic core — one API over SQLite, PostgreSQL and MySQL.",
          "Modular — depend only on the core plus the driver you need.",
        ] },
        { kind: "h3", text: "Packages" },
        { kind: "table", headers: ["Package", "Role"], rows: [
          ["dartonic_core", "Query builder, schema DSL, relations, migrations, ORM. No driver deps."],
          ["dartonic_sqlite", "SQLite driver — connectSqlite()."],
          ["dartonic_postgres", "PostgreSQL driver — connectPostgres()."],
          ["dartonic_mysql", "MySQL driver — connectMysql()."],
          ["dartonic_migrations_fs (beta)", "Load .sql migrations from the filesystem."],
          ["dartonic_zard", "Derive zard validation schemas from tables."],
          ["dartonic_cli (beta)", "CLI — init, migrate, generate, studio."],
          ["dartonic_studio (beta)", "HTTP API to inspect tables and run read-only queries."],
        ] },
        { kind: "links", links: [
          { label: "dartonic_core", href: "https://pub.dev/packages/dartonic_core" },
          { label: "dartonic_sqlite", href: "https://pub.dev/packages/dartonic_sqlite" },
          { label: "dartonic_postgres", href: "https://pub.dev/packages/dartonic_postgres" },
          { label: "dartonic_mysql", href: "https://pub.dev/packages/dartonic_mysql" },
          { label: "dartonic_zard", href: "https://pub.dev/packages/dartonic_zard" },
          { label: "dartonic_migrations_fs", href: "https://pub.dev/packages/dartonic_migrations_fs" },
          { label: "dartonic_cli", href: "https://pub.dev/packages/dartonic_cli" },
          { label: "dartonic_studio", href: "https://pub.dev/packages/dartonic_studio" },
        ] },
        { kind: "ref", to: "installation", label: "Next: Installation" },
      ],
      [
        { kind: "p", text: "Dartonic é um query builder e ORM SQL type-safe para Dart, inspirado no Drizzle ORM. Você define o schema uma vez como classes Dart e consulta SQLite, PostgreSQL e MySQL por uma API fluente e totalmente tipada — sem code generation e sem dynamic." },
        { kind: "h3", text: "Princípios de design" },
        { kind: "ul", items: [
          "Sem code generation — tabelas são classes Dart comuns, sem build_runner.",
          "Type-safe — colunas, condições e linhas tipadas.",
          "Seguro contra injection — todo valor passa por query parametrizada.",
          "Core agnóstico de driver — uma API sobre SQLite, PostgreSQL e MySQL.",
          "Modular — dependa só do core mais o driver que você usa.",
        ] },
        { kind: "h3", text: "Pacotes" },
        { kind: "table", headers: ["Pacote", "Papel"], rows: [
          ["dartonic_core", "Query builder, DSL de schema, relações, migrations, ORM. Sem deps de driver."],
          ["dartonic_sqlite", "Driver SQLite — connectSqlite()."],
          ["dartonic_postgres", "Driver PostgreSQL — connectPostgres()."],
          ["dartonic_mysql", "Driver MySQL — connectMysql()."],
          ["dartonic_migrations_fs (beta)", "Carrega migrations .sql do sistema de arquivos."],
          ["dartonic_zard", "Deriva schemas de validação zard a partir das tabelas."],
          ["dartonic_cli (beta)", "CLI — init, migrate, generate, studio."],
          ["dartonic_studio (beta)", "API HTTP para inspecionar tabelas e rodar queries somente-leitura."],
        ] },
        { kind: "links", links: [
          { label: "dartonic_core", href: "https://pub.dev/packages/dartonic_core" },
          { label: "dartonic_sqlite", href: "https://pub.dev/packages/dartonic_sqlite" },
          { label: "dartonic_postgres", href: "https://pub.dev/packages/dartonic_postgres" },
          { label: "dartonic_mysql", href: "https://pub.dev/packages/dartonic_mysql" },
          { label: "dartonic_zard", href: "https://pub.dev/packages/dartonic_zard" },
          { label: "dartonic_migrations_fs", href: "https://pub.dev/packages/dartonic_migrations_fs" },
          { label: "dartonic_cli", href: "https://pub.dev/packages/dartonic_cli" },
          { label: "dartonic_studio", href: "https://pub.dev/packages/dartonic_studio" },
        ] },
        { kind: "ref", to: "installation", label: "A seguir: Instalação" },
      ],
    ),
  },
  {
    id: "installation",
    group: "start",
    title: bi("Installation", "Instalação"),
    blocks: bi(
      [
        { kind: "p", text: "Add the core plus the driver for your database. The core has no driver dependencies, so you only ship what you use." },
        { kind: "code", lang: "sh", code: "dart pub add dartonic_core\ndart pub add dartonic_sqlite   # or dartonic_postgres / dartonic_mysql" },
        { kind: "p", text: "Or in pubspec.yaml:" },
        { kind: "code", lang: "yaml", filename: "pubspec.yaml", code: "dependencies:\n  dartonic_core: ^1.0.1\n  dartonic_sqlite: ^1.0.0" },
        { kind: "callout", variant: "tip", text: "SQLite is the quickest way to try Dartonic — it needs no server and supports an in-memory database with ':memory:'." },
      ],
      [
        { kind: "p", text: "Adicione o core mais o driver do seu banco. O core não depende de nenhum driver, então você entrega só o que usa." },
        { kind: "code", lang: "sh", code: "dart pub add dartonic_core\ndart pub add dartonic_sqlite   # ou dartonic_postgres / dartonic_mysql" },
        { kind: "p", text: "Ou no pubspec.yaml:" },
        { kind: "code", lang: "yaml", filename: "pubspec.yaml", code: "dependencies:\n  dartonic_core: ^1.0.1\n  dartonic_sqlite: ^1.0.0" },
        { kind: "callout", variant: "tip", text: "SQLite é o jeito mais rápido de experimentar o Dartonic — não precisa de servidor e suporta banco em memória com ':memory:'." },
      ],
    ),
  },
  {
    id: "quick-start",
    group: "start",
    title: bi("Quick Start", "Início rápido"),
    blocks: bi(
      [
        { kind: "p", text: "Define a table, connect, and run a query — the whole loop in one file." },
        { kind: "code", filename: "main.dart", code: "import 'package:dartonic_core/dartonic_core.dart';\nimport 'package:dartonic_sqlite/dartonic_sqlite.dart';\n\nclass UsersTable extends Table {\n  final id        = integer('id').primaryKey(autoIncrement: true);\n  final email     = text('email').notNull().unique();\n  final name      = text('name').notNull();\n  final createdAt = datetime('created_at').defaultNow();\n}\nfinal users = UsersTable();\n\nvoid main() async {\n  // `sync: true` (default) creates the tables on connect.\n  final db = await connectSqlite(':memory:', schemas: [users]);\n\n  await db.insert(users).values([\n    users.email.value('ada@example.com'),\n    users.name.value('Ada'),\n  ]);\n\n  final rows = await db.select().from(users).where(eq(users.name, 'Ada'));\n  print(rows.first.raw); // {id: 1, email: ada@example.com, name: Ada, ...}\n\n  await db.close();\n}" },
        { kind: "ref", to: "tables-and-columns", label: "Next: Tables & Columns" },
      ],
      [
        { kind: "p", text: "Defina uma tabela, conecte e rode uma query — o ciclo inteiro em um arquivo." },
        { kind: "code", filename: "main.dart", code: "import 'package:dartonic_core/dartonic_core.dart';\nimport 'package:dartonic_sqlite/dartonic_sqlite.dart';\n\nclass UsersTable extends Table {\n  final id        = integer('id').primaryKey(autoIncrement: true);\n  final email     = text('email').notNull().unique();\n  final name      = text('name').notNull();\n  final createdAt = datetime('created_at').defaultNow();\n}\nfinal users = UsersTable();\n\nvoid main() async {\n  // `sync: true` (padrão) cria as tabelas ao conectar.\n  final db = await connectSqlite(':memory:', schemas: [users]);\n\n  await db.insert(users).values([\n    users.email.value('ada@example.com'),\n    users.name.value('Ada'),\n  ]);\n\n  final rows = await db.select().from(users).where(eq(users.name, 'Ada'));\n  print(rows.first.raw); // {id: 1, email: ada@example.com, name: Ada, ...}\n\n  await db.close();\n}" },
        { kind: "ref", to: "tables-and-columns", label: "A seguir: Tabelas & Colunas" },
      ],
    ),
  },
  {
    id: "choosing-a-database",
    group: "start",
    title: bi("Choosing a database", "Escolhendo o banco"),
    blocks: bi(
      [
        { kind: "p", text: "The same schema and query code runs on all three drivers. Pick by deployment target; swap the connect call to move between them." },
        { kind: "table", headers: ["Driver", "Best for", "Notes"], rows: [
          ["SQLite", "Local/embedded, Flutter, tests", "No server; ':memory:' or a file. RETURNING needs SQLite 3.35+."],
          ["PostgreSQL", "Production servers", "Full RETURNING, JSONB, connection pooling."],
          ["MySQL", "Existing MySQL infra", "ON DUPLICATE KEY upserts; no RETURNING."],
        ] },
        { kind: "callout", variant: "tip", text: "Develop against SQLite for speed, deploy on PostgreSQL — the query builder emits the right dialect per driver." },
      ],
      [
        { kind: "p", text: "O mesmo schema e código de query roda nos três drivers. Escolha pelo alvo de deploy; troque a chamada de conexão para migrar entre eles." },
        { kind: "table", headers: ["Driver", "Melhor para", "Notas"], rows: [
          ["SQLite", "Local/embarcado, Flutter, testes", "Sem servidor; ':memory:' ou arquivo. RETURNING exige SQLite 3.35+."],
          ["PostgreSQL", "Servidores em produção", "RETURNING completo, JSONB, connection pooling."],
          ["MySQL", "Infra MySQL existente", "Upserts com ON DUPLICATE KEY; sem RETURNING."],
        ] },
        { kind: "callout", variant: "tip", text: "Desenvolva em SQLite pela velocidade e publique em PostgreSQL — o query builder emite o dialeto certo por driver." },
      ],
    ),
  },

  // ────────────────────────────── SCHEMA ──────────────────────────────
  {
    id: "tables-and-columns",
    group: "schema",
    title: bi("Tables & Columns", "Tabelas & Colunas"),
    blocks: bi(
      [
        { kind: "p", text: "A table is a class that extends Table. Each field is a column created by a factory (integer, text, …). Dartonic collects the columns from the field initializers — no annotations, no code generation." },
        { kind: "code", code: "class UsersTable extends Table {\n  final id        = integer('id').primaryKey(autoIncrement: true);\n  final email     = text('email').notNull().unique();\n  final name      = text('name').notNull();\n  final createdAt = datetime('created_at').defaultNow();\n}\n\nfinal users = UsersTable();" },
        { kind: "p", text: "Instantiate the table once and reuse that instance everywhere — its columns (users.id, users.email) are the typed references you pass to the query builder." },
        { kind: "note", text: "The table name is derived from the class name: UsersTable → \"users\". See Table Naming to override it." },
      ],
      [
        { kind: "p", text: "Uma tabela é uma classe que estende Table. Cada campo é uma coluna criada por um factory (integer, text, …). O Dartonic coleta as colunas dos inicializadores de campo — sem anotações, sem code generation." },
        { kind: "code", code: "class UsersTable extends Table {\n  final id        = integer('id').primaryKey(autoIncrement: true);\n  final email     = text('email').notNull().unique();\n  final name      = text('name').notNull();\n  final createdAt = datetime('created_at').defaultNow();\n}\n\nfinal users = UsersTable();" },
        { kind: "p", text: "Instancie a tabela uma vez e reutilize essa instância em todo lugar — suas colunas (users.id, users.email) são as referências tipadas que você passa ao query builder." },
        { kind: "note", text: "O nome da tabela é derivado do nome da classe: UsersTable → \"users\". Veja Nomeação de tabela para sobrescrever." },
      ],
    ),
  },
  {
    id: "column-types",
    group: "schema",
    title: bi("Column types", "Tipos de coluna"),
    blocks: bi(
      [
        { kind: "p", text: "Each factory returns a typed Column<T>. Not every type is valid on every dialect — Dartonic validates that at connect time." },
        { kind: "table", headers: ["Factory", "Dart type", "SQL"], rows: [
          ["integer(name)", "int", "INTEGER"],
          ["serial / bigserial / smallserial", "int", "SERIAL (PG/MySQL)"],
          ["text(name)", "String", "TEXT"],
          ["varchar(name, length: 255) / char", "String", "VARCHAR(n) / CHAR(n)"],
          ["boolean(name)", "bool", "INTEGER 0/1"],
          ["real / decimal / numeric / doubleColumn", "double", "REAL / NUMERIC"],
          ["datetime(name) / date / timestamp / time", "DateTime", "DATETIME / DATE / TIMESTAMP"],
          ["uuid(name)", "String", "UUID"],
          ["json<T>(name, ...) / jsonMap(name)", "T / Map", "JSON / JSONB"],
          ["blob / binary / varbinary", "Uint8List", "BLOB family"],
          ["pgEnum(name, values)(col)", "String", "ENUM (Postgres)"],
        ] },
        { kind: "p", text: "DateTime columns choose a storage strategy via `storage:` — DateTimeStorage.string (ISO-8601, default), .epochMs, or .native." },
      ],
      [
        { kind: "p", text: "Cada factory retorna um Column<T> tipado. Nem todo tipo é válido em todo dialeto — o Dartonic valida isso no momento da conexão." },
        { kind: "table", headers: ["Factory", "Tipo Dart", "SQL"], rows: [
          ["integer(name)", "int", "INTEGER"],
          ["serial / bigserial / smallserial", "int", "SERIAL (PG/MySQL)"],
          ["text(name)", "String", "TEXT"],
          ["varchar(name, length: 255) / char", "String", "VARCHAR(n) / CHAR(n)"],
          ["boolean(name)", "bool", "INTEGER 0/1"],
          ["real / decimal / numeric / doubleColumn", "double", "REAL / NUMERIC"],
          ["datetime(name) / date / timestamp / time", "DateTime", "DATETIME / DATE / TIMESTAMP"],
          ["uuid(name)", "String", "UUID"],
          ["json<T>(name, ...) / jsonMap(name)", "T / Map", "JSON / JSONB"],
          ["blob / binary / varbinary", "Uint8List", "família BLOB"],
          ["pgEnum(name, values)(col)", "String", "ENUM (Postgres)"],
        ] },
        { kind: "p", text: "Colunas DateTime escolhem a estratégia de armazenamento via `storage:` — DateTimeStorage.string (ISO-8601, padrão), .epochMs ou .native." },
      ],
    ),
  },
  {
    id: "constraints",
    group: "schema",
    title: bi("Constraints & modifiers", "Restrições & modificadores"),
    blocks: bi(
      [
        { kind: "p", text: "Modifiers are chainable and return the same Column<T>." },
        { kind: "code", code: "final id    = integer('id').primaryKey(autoIncrement: true);\nfinal uid   = uuid('uid').primaryKey(autoGenerate: true); // UUID v4 filled on insert\nfinal email = text('email').notNull().unique();\nfinal role  = text('role').withDefault('user');          // DEFAULT 'user'\nfinal at    = datetime('created_at').defaultNow();        // DEFAULT CURRENT_TIMESTAMP" },
        { kind: "ul", items: [
          ".notNull() — NOT NULL",
          ".unique() — UNIQUE",
          ".primaryKey(autoIncrement: true) — auto-increment integer PK",
          ".primaryKey(autoGenerate: true) — UUID PK filled on insert",
          ".withDefault(value) — DEFAULT <value>",
          ".defaultNow() — DEFAULT CURRENT_TIMESTAMP",
          ".references(() => other.id, onDelete: …) — foreign key",
        ] },
      ],
      [
        { kind: "p", text: "Os modificadores são encadeáveis e retornam a mesma Column<T>." },
        { kind: "code", code: "final id    = integer('id').primaryKey(autoIncrement: true);\nfinal uid   = uuid('uid').primaryKey(autoGenerate: true); // UUID v4 preenchido no insert\nfinal email = text('email').notNull().unique();\nfinal role  = text('role').withDefault('user');          // DEFAULT 'user'\nfinal at    = datetime('created_at').defaultNow();        // DEFAULT CURRENT_TIMESTAMP" },
        { kind: "ul", items: [
          ".notNull() — NOT NULL",
          ".unique() — UNIQUE",
          ".primaryKey(autoIncrement: true) — PK inteira auto-incremento",
          ".primaryKey(autoGenerate: true) — PK UUID preenchida no insert",
          ".withDefault(value) — DEFAULT <value>",
          ".defaultNow() — DEFAULT CURRENT_TIMESTAMP",
          ".references(() => other.id, onDelete: …) — chave estrangeira",
        ] },
      ],
    ),
  },
  {
    id: "foreign-keys",
    group: "schema",
    title: bi("Foreign keys", "Chaves estrangeiras"),
    blocks: bi(
      [
        { kind: "p", text: "Declare a single-column FK inline with .references(). The target is a thunk so tables can reference each other in any order." },
        { kind: "code", code: "class PostsTable extends Table {\n  final id     = integer('id').primaryKey(autoIncrement: true);\n  final userId = integer('user_id')\n      .notNull()\n      .references(() => users.id, onDelete: ReferentialAction.cascade);\n  final title  = text('title').notNull();\n}" },
        { kind: "p", text: "For composite keys or to keep FKs together, override defineForeignKeys():" },
        { kind: "code", code: "@override\nList<ForeignKey> defineForeignKeys() => [\n  ForeignKey.single(from: courseId, to: () => courses.id,\n    onDelete: ReferentialAction.cascade),\n];" },
        { kind: "p", text: "ReferentialAction: cascade, restrict, noAction, setNull, setDefault." },
      ],
      [
        { kind: "p", text: "Declare uma FK de coluna única inline com .references(). O alvo é um thunk, então as tabelas podem se referenciar em qualquer ordem." },
        { kind: "code", code: "class PostsTable extends Table {\n  final id     = integer('id').primaryKey(autoIncrement: true);\n  final userId = integer('user_id')\n      .notNull()\n      .references(() => users.id, onDelete: ReferentialAction.cascade);\n  final title  = text('title').notNull();\n}" },
        { kind: "p", text: "Para chaves compostas ou para manter as FKs juntas, sobrescreva defineForeignKeys():" },
        { kind: "code", code: "@override\nList<ForeignKey> defineForeignKeys() => [\n  ForeignKey.single(from: courseId, to: () => courses.id,\n    onDelete: ReferentialAction.cascade),\n];" },
        { kind: "p", text: "ReferentialAction: cascade, restrict, noAction, setNull, setDefault." },
      ],
    ),
  },
  {
    id: "indexes",
    group: "schema",
    title: bi("Indexes", "Índices"),
    blocks: bi(
      [
        { kind: "p", text: "Declare indexes by overriding defineIndexes(). They are materialized during sync() with CREATE INDEX IF NOT EXISTS." },
        { kind: "code", code: "@override\nList<Index> defineIndexes() => [\n  index('idx_users_created_at').on([createdAt]),\n  uniqueIndex('idx_users_email').on([email]),\n  // Partial index (SQLite/Postgres) — the predicate is inlined as a literal:\n  index('idx_active').on([email]).where(isNotNull(archivedAt)),\n];" },
      ],
      [
        { kind: "p", text: "Declare índices sobrescrevendo defineIndexes(). Eles são materializados durante o sync() com CREATE INDEX IF NOT EXISTS." },
        { kind: "code", code: "@override\nList<Index> defineIndexes() => [\n  index('idx_users_created_at').on([createdAt]),\n  uniqueIndex('idx_users_email').on([email]),\n  // Índice parcial (SQLite/Postgres) — o predicado é inserido como literal:\n  index('idx_active').on([email]).where(isNotNull(archivedAt)),\n];" },
      ],
    ),
  },
  {
    id: "table-naming",
    group: "schema",
    title: bi("Table naming", "Nomeação de tabela"),
    blocks: bi(
      [
        { kind: "p", text: "By default the table name is derived from the class: the suffixes Table/Tbl/Schema are stripped and CamelCase becomes snake_case (BlogPostsTable → blog_posts). Override tableName for full control." },
        { kind: "code", code: "class Person extends Table {\n  @override\n  String get tableName => 'people';\n  final id = integer('id').primaryKey(autoIncrement: true);\n}" },
      ],
      [
        { kind: "p", text: "Por padrão o nome da tabela é derivado da classe: os sufixos Table/Tbl/Schema são removidos e CamelCase vira snake_case (BlogPostsTable → blog_posts). Sobrescreva tableName para controle total." },
        { kind: "code", code: "class Person extends Table {\n  @override\n  String get tableName => 'people';\n  final id = integer('id').primaryKey(autoIncrement: true);\n}" },
      ],
    ),
  },

  // ────────────────────────────── CONNECTIONS ──────────────────────────────
  {
    id: "connect-sqlite",
    group: "connections",
    title: bi("SQLite", "SQLite"),
    blocks: bi(
      [
        { kind: "p", text: "connectSqlite() opens an in-memory or file-based database. Foreign keys are enabled automatically (PRAGMA foreign_keys = ON)." },
        { kind: "code", code: "import 'package:dartonic_sqlite/dartonic_sqlite.dart';\n\nfinal db = await connectSqlite(\n  ':memory:',           // or 'app.db'\n  schemas: [users, posts],\n  views: const [],\n  relations: const [],\n  sync: true,           // CREATE TABLE IF NOT EXISTS on connect\n);" },
        { kind: "note", text: "RETURNING requires SQLite 3.35+. A `pool` argument is accepted for API symmetry but is a no-op for SQLite." },
      ],
      [
        { kind: "p", text: "connectSqlite() abre um banco em memória ou em arquivo. Chaves estrangeiras são habilitadas automaticamente (PRAGMA foreign_keys = ON)." },
        { kind: "code", code: "import 'package:dartonic_sqlite/dartonic_sqlite.dart';\n\nfinal db = await connectSqlite(\n  ':memory:',           // ou 'app.db'\n  schemas: [users, posts],\n  views: const [],\n  relations: const [],\n  sync: true,           // CREATE TABLE IF NOT EXISTS ao conectar\n);" },
        { kind: "note", text: "RETURNING exige SQLite 3.35+. O argumento `pool` é aceito por simetria de API, mas é no-op no SQLite." },
      ],
    ),
  },
  {
    id: "connect-postgres",
    group: "connections",
    title: bi("PostgreSQL", "PostgreSQL"),
    blocks: bi(
      [
        { kind: "p", text: "connectPostgres() takes a connection URI. `?` placeholders are converted to $1, $2, … automatically." },
        { kind: "code", code: "import 'package:dartonic_postgres/dartonic_postgres.dart';\n\nfinal db = await connectPostgres(\n  'postgres://user:pass@localhost:5432/mydb?sslmode=require',\n  schemas: [users, posts],\n  pool: const PoolConfig(max: 20, min: 2),\n);" },
        { kind: "p", text: "URI: postgres://[user[:password]@][host[:port]][/database][?sslmode=require]." },
      ],
      [
        { kind: "p", text: "connectPostgres() recebe uma URI de conexão. Placeholders `?` são convertidos para $1, $2, … automaticamente." },
        { kind: "code", code: "import 'package:dartonic_postgres/dartonic_postgres.dart';\n\nfinal db = await connectPostgres(\n  'postgres://user:pass@localhost:5432/mydb?sslmode=require',\n  schemas: [users, posts],\n  pool: const PoolConfig(max: 20, min: 2),\n);" },
        { kind: "p", text: "URI: postgres://[user[:senha]@][host[:port]][/database][?sslmode=require]." },
      ],
    ),
  },
  {
    id: "connect-mysql",
    group: "connections",
    title: bi("MySQL", "MySQL"),
    blocks: bi(
      [
        { kind: "p", text: "connectMysql() takes a MySQL URI. ANSI_QUOTES is enabled on every connection so identifiers use double quotes consistently." },
        { kind: "code", code: "import 'package:dartonic_mysql/dartonic_mysql.dart';\n\nfinal db = await connectMysql(\n  'mysql://user:pass@localhost:3306/mydb',\n  schemas: [users, posts],\n  pool: const PoolConfig(max: 10),\n);" },
        { kind: "note", text: "MySQL has no RETURNING; upserts translate to ON DUPLICATE KEY UPDATE." },
      ],
      [
        { kind: "p", text: "connectMysql() recebe uma URI MySQL. O ANSI_QUOTES é habilitado em toda conexão, então identificadores usam aspas duplas de forma consistente." },
        { kind: "code", code: "import 'package:dartonic_mysql/dartonic_mysql.dart';\n\nfinal db = await connectMysql(\n  'mysql://user:pass@localhost:3306/mydb',\n  schemas: [users, posts],\n  pool: const PoolConfig(max: 10),\n);" },
        { kind: "note", text: "MySQL não tem RETURNING; upserts viram ON DUPLICATE KEY UPDATE." },
      ],
    ),
  },
  {
    id: "pooling",
    group: "connections",
    title: bi("Connection pooling", "Connection pooling"),
    blocks: bi(
      [
        { kind: "p", text: "For Postgres and MySQL, pass a PoolConfig so concurrent requests don't serialize on a single connection. A transaction pins one connection for its duration." },
        { kind: "code", code: "final db = await connectPostgres(\n  uri,\n  schemas: [users],\n  pool: const PoolConfig(\n    max: 20,                              // max concurrent connections\n    min: 2,                               // warm connections to keep\n    idleTimeout: Duration(minutes: 5),\n  ),\n);" },
        { kind: "callout", variant: "warning", text: "Without a pool, every query shares one connection — fine for scripts and Flutter, a bottleneck under server concurrency. SQLite ignores PoolConfig." },
      ],
      [
        { kind: "p", text: "Para Postgres e MySQL, passe um PoolConfig para que requisições concorrentes não serializem numa única conexão. Uma transação fixa uma conexão por toda a sua duração." },
        { kind: "code", code: "final db = await connectPostgres(\n  uri,\n  schemas: [users],\n  pool: const PoolConfig(\n    max: 20,                              // máx. de conexões concorrentes\n    min: 2,                               // conexões quentes a manter\n    idleTimeout: Duration(minutes: 5),\n  ),\n);" },
        { kind: "callout", variant: "warning", text: "Sem pool, toda query compartilha uma conexão — ok para scripts e Flutter, gargalo sob concorrência de servidor. O SQLite ignora o PoolConfig." },
      ],
    ),
  },
  {
    id: "closing",
    group: "connections",
    title: bi("Closing connections", "Fechando conexões"),
    blocks: bi(
      [
        { kind: "p", text: "Call db.close() to release the socket (Postgres/MySQL) or file handle (SQLite). In a long-running server you usually keep one db for the process lifetime and close it on shutdown." },
        { kind: "code", code: "await db.close();" },
      ],
      [
        { kind: "p", text: "Chame db.close() para liberar o socket (Postgres/MySQL) ou o handle de arquivo (SQLite). Num servidor de longa duração você normalmente mantém um db pela vida do processo e o fecha no shutdown." },
        { kind: "code", code: "await db.close();" },
      ],
    ),
  },

  // ────────────────────────────── QUERIES ──────────────────────────────
  {
    id: "select-basics",
    group: "queries",
    title: bi("SELECT basics", "SELECT básico"),
    blocks: bi(
      [
        { kind: "p", text: "The query builder implements Future<List<RowMap>> — just await it, no .execute() needed." },
        { kind: "code", code: "// SELECT *\nfinal all = await db.select().from(users);\n\n// Explicit columns\nfinal some = await db.select([users.id, users.email]).from(users);\n\n// Aliased projection (Drizzle-style map)\nfinal shaped = await db.select({\n  'id': users.id,\n  'total': sum(orders.total),\n}).from(orders);" },
      ],
      [
        { kind: "p", text: "O query builder implementa Future<List<RowMap>> — só dar await, sem precisar de .execute()." },
        { kind: "code", code: "// SELECT *\nfinal all = await db.select().from(users);\n\n// Colunas explícitas\nfinal some = await db.select([users.id, users.email]).from(users);\n\n// Projeção com alias (estilo Drizzle, via map)\nfinal shaped = await db.select({\n  'id': users.id,\n  'total': sum(orders.total),\n}).from(orders);" },
      ],
    ),
  },
  {
    id: "where-conditions",
    group: "queries",
    title: bi("WHERE & conditions", "WHERE & condições"),
    blocks: bi(
      [
        { kind: "p", text: "Conditions are typed helpers that produce parameterized SQL — the value never touches the SQL string." },
        { kind: "code", code: "await db.select().from(users).where(\n  and([\n    eq(users.active, true),\n    or([ gt(users.age, 18), isNull(users.age) ]),\n    inArray(users.role, ['admin', 'editor']),\n    like(users.email, '%@example.com'),\n  ]),\n);" },
        { kind: "table", headers: ["Helper", "SQL"], rows: [
          ["eq / ne / eqCol / neCol", "=, <>, col=col"],
          ["gt / gte / lt / lte", "> >= < <="],
          ["isNull / isNotNull", "IS [NOT] NULL"],
          ["inArray / notInArray", "IN / NOT IN"],
          ["between / notBetween", "BETWEEN … AND …"],
          ["like / ilike / notIlike", "LIKE / ILIKE"],
          ["exists / notExists", "EXISTS (subquery)"],
          ["and / or / not", "boolean composition"],
        ] },
      ],
      [
        { kind: "p", text: "Condições são helpers tipados que produzem SQL parametrizado — o valor nunca entra na string SQL." },
        { kind: "code", code: "await db.select().from(users).where(\n  and([\n    eq(users.active, true),\n    or([ gt(users.age, 18), isNull(users.age) ]),\n    inArray(users.role, ['admin', 'editor']),\n    like(users.email, '%@example.com'),\n  ]),\n);" },
        { kind: "table", headers: ["Helper", "SQL"], rows: [
          ["eq / ne / eqCol / neCol", "=, <>, col=col"],
          ["gt / gte / lt / lte", "> >= < <="],
          ["isNull / isNotNull", "IS [NOT] NULL"],
          ["inArray / notInArray", "IN / NOT IN"],
          ["between / notBetween", "BETWEEN … AND …"],
          ["like / ilike / notIlike", "LIKE / ILIKE"],
          ["exists / notExists", "EXISTS (subquery)"],
          ["and / or / not", "composição booleana"],
        ] },
      ],
    ),
  },
  {
    id: "joins",
    group: "queries",
    title: bi("Joins", "Joins"),
    blocks: bi(
      [
        { kind: "p", text: "innerJoin / leftJoin / rightJoin / fullJoin take the joined table and an ON condition. Use eqCol to compare two columns. Joined columns are aliased table__column to avoid collisions." },
        { kind: "code", code: "await db.select().from(posts)\n  .innerJoin(users, eqCol(posts.userId, users.id))\n  .leftJoin(comments, eqCol(posts.id, comments.postId))\n  .where(eq(users.active, true));" },
      ],
      [
        { kind: "p", text: "innerJoin / leftJoin / rightJoin / fullJoin recebem a tabela e uma condição ON. Use eqCol para comparar duas colunas. Colunas de join recebem alias table__column para evitar colisões." },
        { kind: "code", code: "await db.select().from(posts)\n  .innerJoin(users, eqCol(posts.userId, users.id))\n  .leftJoin(comments, eqCol(posts.id, comments.postId))\n  .where(eq(users.active, true));" },
      ],
    ),
  },
  {
    id: "aggregates",
    group: "queries",
    title: bi("Aggregates & GROUP BY", "Agregações & GROUP BY"),
    blocks: bi(
      [
        { kind: "p", text: "Aggregate helpers return a SqlExpression you can select or filter in HAVING with the *Expr condition helpers." },
        { kind: "code", code: "await db.select({\n  'role': users.role,\n  'count': countAll(),\n})\n  .from(users)\n  .groupBy([users.role])\n  .having(gtExpr(countAll(), 5));" },
        { kind: "ul", items: [
          "countAll(), count(col, distinct: true)",
          "sum(col), avg(col), max(col), min(col)",
          "HAVING: eqExpr / gtExpr / gteExpr / ltExpr / lteExpr / neExpr",
        ] },
      ],
      [
        { kind: "p", text: "Helpers de agregação retornam um SqlExpression que você pode selecionar ou filtrar no HAVING com os helpers de condição *Expr." },
        { kind: "code", code: "await db.select({\n  'role': users.role,\n  'count': countAll(),\n})\n  .from(users)\n  .groupBy([users.role])\n  .having(gtExpr(countAll(), 5));" },
        { kind: "ul", items: [
          "countAll(), count(col, distinct: true)",
          "sum(col), avg(col), max(col), min(col)",
          "HAVING: eqExpr / gtExpr / gteExpr / ltExpr / lteExpr / neExpr",
        ] },
      ],
    ),
  },
  {
    id: "order-limit-offset",
    group: "queries",
    title: bi("Order, limit & offset", "Order, limit & offset"),
    blocks: bi(
      [
        { kind: "code", code: "await db.select().from(users)\n  .orderBy(users.createdAt, Order.desc)\n  .limit(20)\n  .offset(40);" },
        { kind: "p", text: "Order is Order.asc | Order.desc. Combine limit + offset for pagination." },
      ],
      [
        { kind: "code", code: "await db.select().from(users)\n  .orderBy(users.createdAt, Order.desc)\n  .limit(20)\n  .offset(40);" },
        { kind: "p", text: "Order é Order.asc | Order.desc. Combine limit + offset para paginação." },
      ],
    ),
  },
  {
    id: "subqueries-union",
    group: "queries",
    title: bi("Subqueries & UNION", "Subqueries & UNION"),
    blocks: bi(
      [
        { kind: "p", text: "Use a subquery inside a condition (exists, inSubquery, …) or combine result sets with union." },
        { kind: "code", code: "// EXISTS subquery\nawait db.select().from(users).where(\n  exists(db.select().from(orders).where(eqCol(orders.userId, users.id))),\n);\n\n// UNION\nawait db.select().from(users).union(db.select().from(admins));" },
      ],
      [
        { kind: "p", text: "Use uma subquery dentro de uma condição (exists, inSubquery, …) ou combine conjuntos de resultado com union." },
        { kind: "code", code: "// Subquery EXISTS\nawait db.select().from(users).where(\n  exists(db.select().from(orders).where(eqCol(orders.userId, users.id))),\n);\n\n// UNION\nawait db.select().from(users).union(db.select().from(admins));" },
      ],
    ),
  },
  {
    id: "result-mapping",
    group: "queries",
    title: bi("Result mapping", "Mapeando resultados"),
    blocks: bi(
      [
        { kind: "p", text: "Rows come back as RowMap. Read cells with the typed .read()/.readNotNull(), grab the raw map with .raw, or decode straight into your model with .rows()." },
        { kind: "code", code: "// Typed cell access\nfinal row = await db.select().from(users).where(eq(users.id, 1)).first();\nfinal id    = row?.read(users.id);           // int?\nfinal email = row?.readNotNull(users.email); // String (throws if null)\n\n// Decode into a model\nclass User {\n  final int id; final String email;\n  User.fromRow(RowMap r)\n    : id = r.readNotNull(users.id),\n      email = r.readNotNull(users.email);\n}\nfinal list = await db.select().from(users).rows(User.fromRow); // List<User>" },
        { kind: "note", text: ".first() adds LIMIT 1 and returns RowMap?. Only valid after select()." },
      ],
      [
        { kind: "p", text: "Linhas voltam como RowMap. Leia células com os tipados .read()/.readNotNull(), pegue o map cru com .raw, ou decodifique direto no seu modelo com .rows()." },
        { kind: "code", code: "// Acesso tipado a células\nfinal row = await db.select().from(users).where(eq(users.id, 1)).first();\nfinal id    = row?.read(users.id);           // int?\nfinal email = row?.readNotNull(users.email); // String (lança se null)\n\n// Decodificar num modelo\nclass User {\n  final int id; final String email;\n  User.fromRow(RowMap r)\n    : id = r.readNotNull(users.id),\n      email = r.readNotNull(users.email);\n}\nfinal list = await db.select().from(users).rows(User.fromRow); // List<User>" },
        { kind: "note", text: ".first() adiciona LIMIT 1 e retorna RowMap?. Válido só após select()." },
      ],
    ),
  },

  // ────────────────────────────── MUTATIONS ──────────────────────────────
  {
    id: "insert",
    group: "mutations",
    title: bi("Insert", "Insert"),
    blocks: bi(
      [
        { kind: "p", text: "Build a typed insert with column.value(). Omit columns that have defaults or auto-increment." },
        { kind: "code", code: "await db.insert(users).values([\n  users.email.value('ada@example.com'),\n  users.name.value('Ada'),\n]);\n\n// Raw map-based insert (dynamic shapes / forms)\nawait db.insert(users).valuesRaw({'email': 'x@y.com', 'name': 'X'});" },
      ],
      [
        { kind: "p", text: "Monte um insert tipado com column.value(). Omita colunas com default ou auto-incremento." },
        { kind: "code", code: "await db.insert(users).values([\n  users.email.value('ada@example.com'),\n  users.name.value('Ada'),\n]);\n\n// Insert por map cru (formas dinâmicas / formulários)\nawait db.insert(users).valuesRaw({'email': 'x@y.com', 'name': 'X'});" },
      ],
    ),
  },
  {
    id: "batch-insert",
    group: "mutations",
    title: bi("Batch insert", "Insert em lote"),
    blocks: bi(
      [
        { kind: "p", text: "valuesMany() inserts many rows in a single statement." },
        { kind: "code", code: "await db.insert(users).valuesMany([\n  [users.email.value('a@b.com'), users.name.value('Alice')],\n  [users.email.value('c@d.com'), users.name.value('Bob')],\n]);" },
      ],
      [
        { kind: "p", text: "valuesMany() insere várias linhas em uma única instrução." },
        { kind: "code", code: "await db.insert(users).valuesMany([\n  [users.email.value('a@b.com'), users.name.value('Alice')],\n  [users.email.value('c@d.com'), users.name.value('Bob')],\n]);" },
      ],
    ),
  },
  {
    id: "returning",
    group: "mutations",
    title: bi("Returning", "Returning"),
    blocks: bi(
      [
        { kind: "p", text: "On PostgreSQL and SQLite, .returning() gives back the affected rows — great for reading generated ids." },
        { kind: "code", code: "final rows = await db.insert(users)\n  .values([users.email.value('a@b.com'), users.name.value('A')])\n  .returning([users.id, users.email]);\nfinal newId = rows.first.read(users.id);\n\n// Shortcut\nawait db.insert(users).values([...]).returningId();" },
      ],
      [
        { kind: "p", text: "No PostgreSQL e SQLite, .returning() devolve as linhas afetadas — ótimo para ler ids gerados." },
        { kind: "code", code: "final rows = await db.insert(users)\n  .values([users.email.value('a@b.com'), users.name.value('A')])\n  .returning([users.id, users.email]);\nfinal newId = rows.first.read(users.id);\n\n// Atalho\nawait db.insert(users).values([...]).returningId();" },
      ],
    ),
  },
  {
    id: "upsert",
    group: "mutations",
    title: bi("Upsert (on conflict)", "Upsert (on conflict)"),
    blocks: bi(
      [
        { kind: "code", code: "// Do nothing on conflict\nawait db.insert(users)\n  .values([users.email.value('a@b.com'), users.name.value('A')])\n  .onConflictDoNothing(target: [users.email]);\n\n// Update on conflict\nawait db.insert(users)\n  .values([users.email.value('a@b.com'), users.name.value('A2')])\n  .onConflictDoUpdate(target: [users.email], set: [users.name.value('A2')]);" },
        { kind: "note", text: "SQLite/Postgres use ON CONFLICT; MySQL maps this to ON DUPLICATE KEY UPDATE." },
      ],
      [
        { kind: "code", code: "// Não faz nada no conflito\nawait db.insert(users)\n  .values([users.email.value('a@b.com'), users.name.value('A')])\n  .onConflictDoNothing(target: [users.email]);\n\n// Atualiza no conflito\nawait db.insert(users)\n  .values([users.email.value('a@b.com'), users.name.value('A2')])\n  .onConflictDoUpdate(target: [users.email], set: [users.name.value('A2')]);" },
        { kind: "note", text: "SQLite/Postgres usam ON CONFLICT; o MySQL mapeia para ON DUPLICATE KEY UPDATE." },
      ],
    ),
  },
  {
    id: "update-delete",
    group: "mutations",
    title: bi("Update & delete", "Update & delete"),
    blocks: bi(
      [
        { kind: "code", code: "await db.update(users)\n  .set([users.name.value('Bob')])\n  .where(eq(users.id, 1));\n\n// Raw map variant\nawait db.update(users).setRaw({'name': 'Bob'}).where(eq(users.id, 1));\n\nawait db.delete(users).where(eq(users.id, 1));" },
        { kind: "callout", variant: "warning", text: "An update or delete without .where() affects every row. Always scope it unless you truly mean all rows." },
      ],
      [
        { kind: "code", code: "await db.update(users)\n  .set([users.name.value('Bob')])\n  .where(eq(users.id, 1));\n\n// Variante por map cru\nawait db.update(users).setRaw({'name': 'Bob'}).where(eq(users.id, 1));\n\nawait db.delete(users).where(eq(users.id, 1));" },
        { kind: "callout", variant: "warning", text: "Um update ou delete sem .where() afeta todas as linhas. Sempre limite o escopo, a menos que realmente queira todas." },
      ],
    ),
  },

  // ────────────────────────────── TRANSACTIONS ──────────────────────────────
  {
    id: "transactions",
    group: "transactions",
    title: bi("Transactions", "Transações"),
    blocks: bi(
      [
        { kind: "p", text: "db.transaction() runs a block against a pinned connection. Any thrown exception rolls back and rethrows; commit happens on success." },
        { kind: "code", code: "await db.transaction((tx) async {\n  await tx.update(accounts)\n    .set([accounts.balance.value(900)])\n    .where(eq(accounts.id, 1));\n  await tx.update(accounts)\n    .set([accounts.balance.value(1100)])\n    .where(eq(accounts.id, 2));\n  // throw to roll back everything, or tx.rollback() to roll back silently\n});" },
        { kind: "callout", variant: "tip", text: "Call tx.rollback() (which throws TransactionRollback) to abort without surfacing an error to the caller." },
      ],
      [
        { kind: "p", text: "db.transaction() roda um bloco numa conexão fixa. Qualquer exceção lançada faz rollback e é relançada; o commit ocorre no sucesso." },
        { kind: "code", code: "await db.transaction((tx) async {\n  await tx.update(accounts)\n    .set([accounts.balance.value(900)])\n    .where(eq(accounts.id, 1));\n  await tx.update(accounts)\n    .set([accounts.balance.value(1100)])\n    .where(eq(accounts.id, 2));\n  // lance para dar rollback em tudo, ou tx.rollback() para reverter em silêncio\n});" },
        { kind: "callout", variant: "tip", text: "Chame tx.rollback() (que lança TransactionRollback) para abortar sem propagar erro ao chamador." },
      ],
    ),
  },

  // ────────────────────────────── RELATIONS ──────────────────────────────
  {
    id: "relations-overview",
    group: "relations",
    title: bi("Relations overview", "Relações: visão geral"),
    blocks: bi(
      [
        { kind: "p", text: "Referential integrity comes from foreign keys in the schema. To read related data, Dartonic offers batched loaders (no N+1) and a declarative with_ on the ORM helpers. Each loader runs 2–3 queries total regardless of row count." },
        { kind: "ref", to: "one-to-many", label: "Next: One-to-many" },
      ],
      [
        { kind: "p", text: "A integridade referencial vem das chaves estrangeiras no schema. Para ler dados relacionados, o Dartonic oferece carregadores em lote (sem N+1) e um with_ declarativo nos helpers do ORM. Cada carregador roda 2–3 queries no total, não importa a quantidade de linhas." },
        { kind: "ref", to: "one-to-many", label: "A seguir: Um-para-muitos" },
      ],
    ),
  },
  {
    id: "one-to-many",
    group: "relations",
    title: bi("One-to-many", "Um-para-muitos"),
    blocks: bi(
      [
        { kind: "p", text: "findManyWith loads parents, then all their children in one batched IN query, and groups them in Dart." },
        { kind: "code", code: "final usersWithPosts = await db.findManyWith<User, Post, int>(\n  parent: users,\n  parentDecoder: User.fromRow,\n  parentKey: (u) => u.id,\n  childTable: posts,\n  childForeignKey: posts.userId,\n  childDecoder: Post.fromRow,\n);\nfor (final e in usersWithPosts) {\n  print('\${e.parent.name}: \${e.children.length} posts');\n}" },
      ],
      [
        { kind: "p", text: "findManyWith carrega os pais e depois todos os filhos numa única query IN em lote, agrupando em Dart." },
        { kind: "code", code: "final usersWithPosts = await db.findManyWith<User, Post, int>(\n  parent: users,\n  parentDecoder: User.fromRow,\n  parentKey: (u) => u.id,\n  childTable: posts,\n  childForeignKey: posts.userId,\n  childDecoder: Post.fromRow,\n);\nfor (final e in usersWithPosts) {\n  print('\${e.parent.name}: \${e.children.length} posts');\n}" },
      ],
    ),
  },
  {
    id: "one-to-one",
    group: "relations",
    title: bi("One-to-one", "Um-para-um"),
    blocks: bi(
      [
        { kind: "code", code: "final usersWithProfile = await db.findManyWithOne<User, Profile, int>(\n  parent: users,\n  parentDecoder: User.fromRow,\n  parentKey: (u) => u.id,\n  childTable: profiles,\n  childForeignKey: profiles.userId,\n  childDecoder: Profile.fromRow,\n);\n// → List<WithOne<User, Profile?>>" },
      ],
      [
        { kind: "code", code: "final usersWithProfile = await db.findManyWithOne<User, Profile, int>(\n  parent: users,\n  parentDecoder: User.fromRow,\n  parentKey: (u) => u.id,\n  childTable: profiles,\n  childForeignKey: profiles.userId,\n  childDecoder: Profile.fromRow,\n);\n// → List<WithOne<User, Profile?>>" },
      ],
    ),
  },
  {
    id: "many-to-many",
    group: "relations",
    title: bi("Many-to-many", "Muitos-para-muitos"),
    blocks: bi(
      [
        { kind: "p", text: "findManyThrough joins across a junction table in three queries." },
        { kind: "code", code: "final usersWithGroups = await db.findManyThrough<User, Group, int, int>(\n  parent: users,\n  parentDecoder: User.fromRow,\n  parentKey: (u) => u.id,\n  junction: userGroups,\n  junctionParentKey: userGroups.userId,\n  junctionChildKey: userGroups.groupId,\n  child: groups,\n  childKey: groups.id,\n  childDecoder: Group.fromRow,\n);\n// → List<WithChildren<User, Group>>" },
      ],
      [
        { kind: "p", text: "findManyThrough faz o join por uma tabela de junção em três queries." },
        { kind: "code", code: "final usersWithGroups = await db.findManyThrough<User, Group, int, int>(\n  parent: users,\n  parentDecoder: User.fromRow,\n  parentKey: (u) => u.id,\n  junction: userGroups,\n  junctionParentKey: userGroups.userId,\n  junctionChildKey: userGroups.groupId,\n  child: groups,\n  childKey: groups.id,\n  childDecoder: Group.fromRow,\n);\n// → List<WithChildren<User, Group>>" },
      ],
    ),
  },
  {
    id: "orm-helpers",
    group: "relations",
    title: bi("ORM helpers", "Helpers do ORM"),
    blocks: bi(
      [
        { kind: "p", text: "db.orm(table) wraps a table with higher-level CRUD helpers." },
        { kind: "code", code: "final repo = db.orm(users);\nfinal all      = await repo.findMany(where: eq(users.active, true), limit: 10);\nfinal first    = await repo.findFirst(where: eq(users.email, 'a@b.com'));\nfinal byId      = await repo.findById<int>(42, idColumn: users.id);\nfinal mapped   = await repo.mapMany<User>(User.fromRow, where: eq(users.active, true));" },
      ],
      [
        { kind: "p", text: "db.orm(table) envolve uma tabela com helpers de CRUD de mais alto nível." },
        { kind: "code", code: "final repo = db.orm(users);\nfinal all      = await repo.findMany(where: eq(users.active, true), limit: 10);\nfinal first    = await repo.findFirst(where: eq(users.email, 'a@b.com'));\nfinal byId      = await repo.findById<int>(42, idColumn: users.id);\nfinal mapped   = await repo.mapMany<User>(User.fromRow, where: eq(users.active, true));" },
      ],
    ),
  },
  {
    id: "declarative-relations",
    group: "relations",
    title: bi("Declarative loading", "Carregamento declarativo"),
    blocks: bi(
      [
        { kind: "p", text: "Register relations() metadata at connect time, then eager-load by name with findManyWithRelations. Returns plain maps with nested children." },
        { kind: "code", code: "final usersRel = relations(users, (r) => {\n  'posts': r.many('posts', fields: ['id'], references: ['user_id']),\n});\nfinal db = await connectSqlite(':memory:', schemas: [users, posts], relations: [usersRel]);\n\nfinal result = await db.orm(users).findManyWithRelations(with_: {'posts': true});\n// → [{ id, name, posts: [ {..}, {..} ] }, ...]" },
      ],
      [
        { kind: "p", text: "Registre a metadata de relations() na conexão e depois faça eager-load por nome com findManyWithRelations. Retorna maps simples com os filhos aninhados." },
        { kind: "code", code: "final usersRel = relations(users, (r) => {\n  'posts': r.many('posts', fields: ['id'], references: ['user_id']),\n});\nfinal db = await connectSqlite(':memory:', schemas: [users, posts], relations: [usersRel]);\n\nfinal result = await db.orm(users).findManyWithRelations(with_: {'posts': true});\n// → [{ id, name, posts: [ {..}, {..} ] }, ...]" },
      ],
    ),
  },

  // ────────────────────────────── ADVANCED ──────────────────────────────
  {
    id: "ctes",
    group: "advanced",
    title: bi("CTEs (WITH)", "CTEs (WITH)"),
    blocks: bi(
      [
        { kind: "code", code: "final bigOrders = db.withCte('big_orders').as(\n  db.select().from(orders).where(gt(orders.total, 100.0)),\n);\nfinal rows = await db.fromCte(bigOrders); // SELECT * FROM \"big_orders\"" },
        { kind: "p", text: "Parameters from the CTE body are carried through automatically." },
      ],
      [
        { kind: "code", code: "final bigOrders = db.withCte('big_orders').as(\n  db.select().from(orders).where(gt(orders.total, 100.0)),\n);\nfinal rows = await db.fromCte(bigOrders); // SELECT * FROM \"big_orders\"" },
        { kind: "p", text: "Os parâmetros do corpo da CTE são propagados automaticamente." },
      ],
    ),
  },
  {
    id: "views",
    group: "advanced",
    title: bi("Views", "Views"),
    blocks: bi(
      [
        { kind: "p", text: "Declare a view with the dialect-specific creator and register it at connect time." },
        { kind: "code", code: "final activeOrders = sqliteView('active_orders').as((qb) => qb\n  .select([orders.id, orders.total])\n  .from(orders)\n  .where(eq(orders.status, 'active')));\n\nfinal db = await connectSqlite(':memory:', schemas: [orders], views: [activeOrders]);" },
        { kind: "note", text: "Creators: sqliteView(), pgView(), mysqlView(). View predicate values are inlined as SQL literals (engines reject bind params in CREATE VIEW)." },
      ],
      [
        { kind: "p", text: "Declare uma view com o criador específico do dialeto e registre-a na conexão." },
        { kind: "code", code: "final activeOrders = sqliteView('active_orders').as((qb) => qb\n  .select([orders.id, orders.total])\n  .from(orders)\n  .where(eq(orders.status, 'active')));\n\nfinal db = await connectSqlite(':memory:', schemas: [orders], views: [activeOrders]);" },
        { kind: "note", text: "Criadores: sqliteView(), pgView(), mysqlView(). Valores do predicado da view são inseridos como literais SQL (engines rejeitam bind params em CREATE VIEW)." },
      ],
    ),
  },
  {
    id: "raw-sql",
    group: "advanced",
    title: bi("Raw SQL", "SQL cru"),
    blocks: bi(
      [
        { kind: "p", text: "The escape hatch: run any SQL with parameters. Returns undecoded maps." },
        { kind: "code", code: "final rows = await db.rawQuery(\n  'SELECT * FROM users WHERE email LIKE ?',\n  ['%@example.com'],\n);" },
      ],
      [
        { kind: "p", text: "A válvula de escape: rode qualquer SQL com parâmetros. Retorna maps não-decodificados." },
        { kind: "code", code: "final rows = await db.rawQuery(\n  'SELECT * FROM users WHERE email LIKE ?',\n  ['%@example.com'],\n);" },
      ],
    ),
  },
  {
    id: "prepared-statements",
    group: "advanced",
    title: bi("Prepared statements", "Prepared statements"),
    blocks: bi(
      [
        { kind: "p", text: "Drivers keep a per-connection prepared-statement cache keyed by SQL text (bounded LRU), so repeated queries reuse the compiled statement automatically — no API to call. DDL is never cached." },
      ],
      [
        { kind: "p", text: "Os drivers mantêm um cache de prepared statements por conexão, indexado pelo texto SQL (LRU limitado), então queries repetidas reutilizam o statement compilado automaticamente — sem API para chamar. DDL nunca é cacheado." },
      ],
    ),
  },
  {
    id: "schema-diff",
    group: "advanced",
    title: bi("Schema diffing", "Diff de schema"),
    blocks: bi(
      [
        { kind: "p", text: "db.diff() introspects the live database and compares it to your declared tables, returning the DDL needed to catch up. It is read-only — it never applies anything — and is the foundation for the CLI's migration generation." },
        { kind: "code", code: "final diff = await db.diff();\nfor (final stmt in diff.statements) print(stmt); // CREATE TABLE… / ADD COLUMN…" },
        { kind: "callout", variant: "warning", text: "The current diff detects new tables and new columns. It does not detect drops, renames, type changes or constraint changes — review generated DDL before applying." },
      ],
      [
        { kind: "p", text: "db.diff() faz introspecção do banco ao vivo e compara com as tabelas declaradas, retornando o DDL necessário para alinhar. É somente-leitura — nunca aplica nada — e é a base para a geração de migrations da CLI." },
        { kind: "code", code: "final diff = await db.diff();\nfor (final stmt in diff.statements) print(stmt); // CREATE TABLE… / ADD COLUMN…" },
        { kind: "callout", variant: "warning", text: "O diff atual detecta tabelas e colunas novas. Não detecta remoções, renomeações, mudanças de tipo ou de constraint — revise o DDL gerado antes de aplicar." },
      ],
    ),
  },

  // ────────────────────────────── MIGRATIONS ──────────────────────────────
  {
    id: "migrations-manual",
    group: "migrations",
    title: bi("Manual migrations", "Migrations manuais"),
    blocks: bi(
      [
        { kind: "p", text: "A Migration is a name + SQL. db.migrate() records applied names in __dartonic_migrations, so each runs exactly once." },
        { kind: "code", code: "await db.migrate([\n  Migration(name: '001_init.sql', sql: '''\n    CREATE TABLE users (\n      id INTEGER PRIMARY KEY AUTOINCREMENT,\n      email TEXT NOT NULL UNIQUE\n    );\n  '''),\n  Migration(name: '002_add_posts.sql', sql: '...'),\n]);" },
      ],
      [
        { kind: "p", text: "Uma Migration é um nome + SQL. db.migrate() registra os nomes aplicados em __dartonic_migrations, então cada uma roda exatamente uma vez." },
        { kind: "code", code: "await db.migrate([\n  Migration(name: '001_init.sql', sql: '''\n    CREATE TABLE users (\n      id INTEGER PRIMARY KEY AUTOINCREMENT,\n      email TEXT NOT NULL UNIQUE\n    );\n  '''),\n  Migration(name: '002_add_posts.sql', sql: '...'),\n]);" },
      ],
    ),
  },
  {
    id: "migrations-filesystem",
    group: "migrations",
    beta: true,
    title: bi("Filesystem migrations", "Migrations em arquivo"),
    blocks: bi(
      [
        { kind: "callout", variant: "warning", text: "Beta: dartonic_migrations_fs is a beta package (1.0.0-beta). Its API may change before a stable release." },
        { kind: "p", text: "On the server/CLI, keep .sql files in a folder and load them (sorted by filename) with dartonic_migrations_fs." },
        { kind: "code", code: "import 'package:dartonic_migrations_fs/dartonic_migrations_fs.dart';\n\nawait db.migrate(loadMigrationsFromDir('db/migrations'));" },
        { kind: "code", lang: "sh", code: "db/migrations/\n  001_init.sql\n  002_add_users.sql\n  003_add_posts.sql" },
      ],
      [
        { kind: "callout", variant: "warning", text: "Beta: o dartonic_migrations_fs é um pacote beta (1.0.0-beta). Sua API pode mudar antes de uma versão estável." },
        { kind: "p", text: "No servidor/CLI, mantenha arquivos .sql numa pasta e carregue-os (ordenados por nome) com dartonic_migrations_fs." },
        { kind: "code", code: "import 'package:dartonic_migrations_fs/dartonic_migrations_fs.dart';\n\nawait db.migrate(loadMigrationsFromDir('db/migrations'));" },
        { kind: "code", lang: "sh", code: "db/migrations/\n  001_init.sql\n  002_add_users.sql\n  003_add_posts.sql" },
      ],
    ),
  },
  {
    id: "migrations-flutter",
    group: "migrations",
    title: bi("Flutter (assets)", "Flutter (assets)"),
    blocks: bi(
      [
        { kind: "p", text: "There's no filesystem on device, so load migration SQL from bundled assets instead." },
        { kind: "code", code: "import 'package:flutter/services.dart';\n\nawait db.migrate([\n  Migration(name: '001_init.sql',\n    sql: await rootBundle.loadString('assets/migrations/001_init.sql')),\n]);" },
      ],
      [
        { kind: "p", text: "No dispositivo não há sistema de arquivos, então carregue o SQL das migrations dos assets empacotados." },
        { kind: "code", code: "import 'package:flutter/services.dart';\n\nawait db.migrate([\n  Migration(name: '001_init.sql',\n    sql: await rootBundle.loadString('assets/migrations/001_init.sql')),\n]);" },
      ],
    ),
  },

  // ────────────────────────────── TOOLING ──────────────────────────────
  {
    id: "cli",
    group: "tooling",
    beta: true,
    title: bi("CLI", "CLI"),
    blocks: bi(
      [
        { kind: "callout", variant: "warning", text: "Beta: dartonic_cli is a beta package (1.0.0-beta). Its commands and flags may change before a stable release." },
        { kind: "p", text: "The dartonic CLI scaffolds and runs migrations." },
        { kind: "code", lang: "sh", code: "dartonic init                       # create db/migrations and db/schema\ndartonic migrate --create add_users # scaffold a timestamped .sql file\ndartonic migrate --dry-run          # list pending migrations\ndartonic migrate --dir db/migrations\ndartonic generate                   # scaffold model helpers (guidance)\ndartonic studio                     # instructions to launch Studio" },
      ],
      [
        { kind: "callout", variant: "warning", text: "Beta: o dartonic_cli é um pacote beta (1.0.0-beta). Seus comandos e flags podem mudar antes de uma versão estável." },
        { kind: "p", text: "A CLI dartonic faz scaffold e roda migrations." },
        { kind: "code", lang: "sh", code: "dartonic init                       # cria db/migrations e db/schema\ndartonic migrate --create add_users # gera um arquivo .sql com timestamp\ndartonic migrate --dry-run          # lista migrations pendentes\ndartonic migrate --dir db/migrations\ndartonic generate                   # scaffold de helpers de model (orientação)\ndartonic studio                     # instruções para abrir o Studio" },
      ],
    ),
  },
  {
    id: "studio",
    group: "tooling",
    beta: true,
    title: bi("Studio", "Studio"),
    blocks: bi(
      [
        { kind: "callout", variant: "warning", text: "Beta: dartonic_studio is a beta package (1.0.0-beta). Its API and endpoints may change before a stable release." },
        { kind: "p", text: "Studio is a small HTTP API to inspect your database. Bind it to localhost — it is not meant for production exposure." },
        { kind: "code", code: "import 'package:dartonic_studio/dartonic_studio.dart';\n\nawait startStudio(db, port: 4444); // http://localhost:4444" },
        { kind: "table", headers: ["Endpoint", "Purpose"], rows: [
          ["GET /tables", "List registered table names"],
          ["GET /tables/:name", "Describe columns, types, modifiers"],
          ["POST /query", "Run a read-only SELECT (only SELECT allowed)"],
        ] },
      ],
      [
        { kind: "callout", variant: "warning", text: "Beta: o dartonic_studio é um pacote beta (1.0.0-beta). Sua API e endpoints podem mudar antes de uma versão estável." },
        { kind: "p", text: "O Studio é uma pequena API HTTP para inspecionar seu banco. Faça bind em localhost — não é para exposição em produção." },
        { kind: "code", code: "import 'package:dartonic_studio/dartonic_studio.dart';\n\nawait startStudio(db, port: 4444); // http://localhost:4444" },
        { kind: "table", headers: ["Endpoint", "Função"], rows: [
          ["GET /tables", "Lista os nomes das tabelas registradas"],
          ["GET /tables/:name", "Descreve colunas, tipos, modificadores"],
          ["POST /query", "Roda um SELECT somente-leitura (só SELECT permitido)"],
        ] },
      ],
    ),
  },

  // ────────────────────────────── VALIDATION ──────────────────────────────
  {
    id: "dartonic-zard",
    group: "validation",
    title: bi("dartonic_zard", "dartonic_zard"),
    blocks: bi(
      [
        { kind: "p", text: "dartonic_zard derives zard validation schemas from a table (the drizzle-zod pattern) — the table is the single source of truth, so validation never drifts from the database." },
        { kind: "code", code: "import 'package:dartonic_zard/dartonic_zard.dart';\n\nfinal insertUser = createInsertSchema(users); // omits auto id; nullable/default → optional\nfinal selectUser = createSelectSchema(users); // every column\nfinal updateUser = createUpdateSchema(users); // all fields optional (partial)\n\n// Refine a derived field without restating presence rules:\nfinal signup = createInsertSchema(users, refine: {\n  'email': z.string().email(),\n  'name':  z.string().min(2).max(50),\n});" },
        { kind: "table", headers: ["Column", "zard schema"], rows: [
          ["integer()", "z.int()"],
          ["text()", "z.string()"],
          ["real()", "z.double()"],
          ["boolean()", "z.bool()"],
          ["datetime()/timestamp()", "z.date()"],
          ["uuid()", "z.string().uuid()"],
          ["json()/jsonMap()", "z.map({}) (permissive)"],
          ["pgEnum(...)", "z.$enum([...])"],
        ] },
        { kind: "callout", variant: "tip", text: "The derived schema is a normal zard schema — plug it into darto_validator's zValidator and darto_zard_openapi's .openapiSchema() for validation + OpenAPI from one table." },
      ],
      [
        { kind: "p", text: "O dartonic_zard deriva schemas de validação zard a partir de uma tabela (o padrão drizzle-zod) — a tabela é a fonte única da verdade, então a validação nunca desvia do banco." },
        { kind: "code", code: "import 'package:dartonic_zard/dartonic_zard.dart';\n\nfinal insertUser = createInsertSchema(users); // omite id auto; nullable/default → opcional\nfinal selectUser = createSelectSchema(users); // todas as colunas\nfinal updateUser = createUpdateSchema(users); // tudo opcional (partial)\n\n// Refine um campo derivado sem repetir regras de presença:\nfinal signup = createInsertSchema(users, refine: {\n  'email': z.string().email(),\n  'name':  z.string().min(2).max(50),\n});" },
        { kind: "table", headers: ["Coluna", "schema zard"], rows: [
          ["integer()", "z.int()"],
          ["text()", "z.string()"],
          ["real()", "z.double()"],
          ["boolean()", "z.bool()"],
          ["datetime()/timestamp()", "z.date()"],
          ["uuid()", "z.string().uuid()"],
          ["json()/jsonMap()", "z.map({}) (permissivo)"],
          ["pgEnum(...)", "z.$enum([...])"],
        ] },
        { kind: "callout", variant: "tip", text: "O schema derivado é um schema zard normal — use-o no zValidator do darto_validator e no .openapiSchema() do darto_zard_openapi para validação + OpenAPI a partir de uma tabela." },
      ],
    ),
  },

  // ────────────────────────────── ERRORS ──────────────────────────────
  {
    id: "error-handling",
    group: "errors",
    title: bi("Error handling", "Tratamento de erros"),
    blocks: bi(
      [
        { kind: "p", text: "Drivers translate native database exceptions into a typed hierarchy under DatabaseError, so you can catch constraint violations precisely." },
        { kind: "code", code: "try {\n  await db.insert(users).values([users.email.value('taken@x.com')]);\n} on UniqueViolationError {\n  // 409 Conflict — duplicate unique/primary key\n} on ForeignKeyError {\n  // 409 — FK constraint\n} on NotNullViolationError {\n  // 400 — required column missing\n}" },
        { kind: "ul", items: [
          "DatabaseError — base (wraps the original driver error)",
          "ConnectionError, ExecutionError, QueryBuildError, SchemaError, ValidationError, TypeValidationError",
          "ConstraintViolationError → UniqueViolationError, NotNullViolationError, ForeignKeyError",
        ] },
      ],
      [
        { kind: "p", text: "Os drivers traduzem exceções nativas do banco numa hierarquia tipada sob DatabaseError, então você captura violações de constraint com precisão." },
        { kind: "code", code: "try {\n  await db.insert(users).values([users.email.value('taken@x.com')]);\n} on UniqueViolationError {\n  // 409 Conflict — unique/primary key duplicado\n} on ForeignKeyError {\n  // 409 — constraint de FK\n} on NotNullViolationError {\n  // 400 — coluna obrigatória ausente\n}" },
        { kind: "ul", items: [
          "DatabaseError — base (envolve o erro original do driver)",
          "ConnectionError, ExecutionError, QueryBuildError, SchemaError, ValidationError, TypeValidationError",
          "ConstraintViolationError → UniqueViolationError, NotNullViolationError, ForeignKeyError",
        ] },
      ],
    ),
  },

  // ────────────────────────────── EXAMPLES ──────────────────────────────
  {
    id: "examples",
    group: "examples",
    title: bi("Example projects", "Projetos de exemplo"),
    blocks: bi(
      [
        { kind: "p", text: "Runnable projects live in the examples/ folder of the repo." },
        { kind: "ul", items: [
          "book_api_crud — REST CRUD over SQLite (insert/select/update/delete, .first()).",
          "twitter_clone — joins, repository pattern, typed models via .rows().",
          "flutter_todo — Flutter app on SQLite with asset-based migrations.",
          "relations_blog — all four relation types + full HTTP API with darto + DI + validation.",
        ] },
        { kind: "code", lang: "sh", code: "cd examples/book_api_crud\ndart pub get\ndart run lib/main.dart" },
        { kind: "links", links: [
          { label: "Browse examples on GitHub", href: "https://github.com/evandersondev/dartonic/tree/main/examples" },
        ] },
      ],
      [
        { kind: "p", text: "Projetos executáveis ficam na pasta examples/ do repositório." },
        { kind: "ul", items: [
          "book_api_crud — CRUD REST sobre SQLite (insert/select/update/delete, .first()).",
          "twitter_clone — joins, padrão repository, modelos tipados via .rows().",
          "flutter_todo — app Flutter em SQLite com migrations por asset.",
          "relations_blog — os quatro tipos de relação + API HTTP completa com darto + DI + validação.",
        ] },
        { kind: "code", lang: "sh", code: "cd examples/book_api_crud\ndart pub get\ndart run lib/main.dart" },
        { kind: "links", links: [
          { label: "Ver exemplos no GitHub", href: "https://github.com/evandersondev/dartonic/tree/main/examples" },
        ] },
      ],
    ),
  },

  // ────────────────────────────── REFERENCE ──────────────────────────────
  {
    id: "reference-core",
    group: "reference",
    title: bi("dartonic_core", "dartonic_core"),
    blocks: bi(
      [
        { kind: "p", text: "The driver-agnostic heart: schema DSL, query builder, ORM helpers, relations, migrations and the typed error hierarchy." },
        { kind: "ul", items: [
          "Schema: Table, column factories, modifiers, ForeignKey, Index.",
          "Query builder: select/insert/update/delete, conditions, joins, aggregates, CTEs, views.",
          "Results: RowMap (read/readNotNull/raw), .rows(decoder), .first().",
          "ORM: db.orm(table), findManyWith/WithOne/Through, findManyWithRelations.",
          "Transactions: db.transaction. Migrations: Migration, db.migrate, db.diff.",
          "Pooling: PoolConfig. Errors: DatabaseError + subclasses.",
        ] },
        { kind: "links", links: [{ label: "pub.dev/packages/dartonic_core", href: "https://pub.dev/packages/dartonic_core" }] },
      ],
      [
        { kind: "p", text: "O coração agnóstico de driver: DSL de schema, query builder, helpers de ORM, relações, migrations e a hierarquia de erros tipada." },
        { kind: "ul", items: [
          "Schema: Table, factories de coluna, modificadores, ForeignKey, Index.",
          "Query builder: select/insert/update/delete, condições, joins, agregações, CTEs, views.",
          "Resultados: RowMap (read/readNotNull/raw), .rows(decoder), .first().",
          "ORM: db.orm(table), findManyWith/WithOne/Through, findManyWithRelations.",
          "Transações: db.transaction. Migrations: Migration, db.migrate, db.diff.",
          "Pooling: PoolConfig. Erros: DatabaseError + subclasses.",
        ] },
        { kind: "links", links: [{ label: "pub.dev/packages/dartonic_core", href: "https://pub.dev/packages/dartonic_core" }] },
      ],
    ),
  },
  {
    id: "reference-drivers",
    group: "reference",
    title: bi("Drivers", "Drivers"),
    blocks: bi(
      [
        { kind: "table", headers: ["Package", "Entry point", "Notes"], rows: [
          ["dartonic_sqlite", "connectSqlite(path, …)", "':memory:' or file; FK on; no-op pool."],
          ["dartonic_postgres", "connectPostgres(uri, …)", "$n placeholders; RETURNING; pooling."],
          ["dartonic_mysql", "connectMysql(uri, …)", "ANSI_QUOTES; ON DUPLICATE KEY; pooling."],
        ] },
        { kind: "p", text: "All three share the same DartonicDb API; only the connect call and dialect differ." },
      ],
      [
        { kind: "table", headers: ["Pacote", "Entrada", "Notas"], rows: [
          ["dartonic_sqlite", "connectSqlite(path, …)", "':memory:' ou arquivo; FK on; pool no-op."],
          ["dartonic_postgres", "connectPostgres(uri, …)", "placeholders $n; RETURNING; pooling."],
          ["dartonic_mysql", "connectMysql(uri, …)", "ANSI_QUOTES; ON DUPLICATE KEY; pooling."],
        ] },
        { kind: "p", text: "Os três compartilham a mesma API DartonicDb; só a chamada de conexão e o dialeto mudam." },
      ],
    ),
  },
  {
    id: "reference-tooling",
    group: "reference",
    title: bi("CLI, Studio & migrations_fs", "CLI, Studio & migrations_fs"),
    blocks: bi(
      [
        { kind: "callout", variant: "warning", text: "dartonic_cli, dartonic_studio and dartonic_migrations_fs are currently beta (1.0.0-beta) — their APIs may change before a stable release." },
        { kind: "ul", items: [
          "dartonic_cli (beta) — dartonic init / migrate / generate / studio.",
          "dartonic_studio (beta) — startStudio(db, port, host) + REST API (tables, query).",
          "dartonic_migrations_fs (beta) — loadMigrationsFromDir(dir) for VM/CLI/server.",
          "dartonic_zard — createInsertSchema / createSelectSchema / createUpdateSchema.",
        ] },
      ],
      [
        { kind: "callout", variant: "warning", text: "dartonic_cli, dartonic_studio e dartonic_migrations_fs estão em beta (1.0.0-beta) — suas APIs podem mudar antes de uma versão estável." },
        { kind: "ul", items: [
          "dartonic_cli (beta) — dartonic init / migrate / generate / studio.",
          "dartonic_studio (beta) — startStudio(db, port, host) + API REST (tables, query).",
          "dartonic_migrations_fs (beta) — loadMigrationsFromDir(dir) para VM/CLI/servidor.",
          "dartonic_zard — createInsertSchema / createSelectSchema / createUpdateSchema.",
        ] },
      ],
    ),
  },
];

export function getDocSections(lang: Lang): DocSection[] {
  return SECTIONS.map((s) => ({
    id: s.id,
    group: s.group,
    title: s.title[lang],
    blocks: s.blocks[lang],
    beta: s.beta,
  }));
}
