export type Lang = "en" | "pt";

export const translations = {
  en: {
    nav: { docs: "Documentation", github: "GitHub", getStarted: "Get Started" },
    hero: {
      badge: "v1.0 · Type-safe SQL for Dart",
      title1: "Type-safe SQL for Dart,",
      title2: "inspired by Drizzle.",
      subtitle:
        "Define your schema once as plain Dart classes and query SQLite, PostgreSQL and MySQL with a fluent, fully-typed builder. No code generation. No dynamic.",
      cta1: "Get Started",
      cta2: "View Documentation",
      installNote: "dart pub add dartonic_core",
      tagline: "One schema, three databases. Pure Dart. No codegen.",
      credibility: {
        version: "v1.0.0",
        oss: "Open source · MIT",
        pub: "pub.dev",
        github: "GitHub",
      },
    },
    features: {
      title: "Everything you expect from a modern ORM",
      subtitle:
        "Schema DSL, a typed query builder, relations, transactions and migrations — for SQLite, PostgreSQL and MySQL.",
      items: [
        {
          icon: "route",
          title: "Typed query builder",
          desc: "select / insert / update / delete with typed conditions, joins, aggregates and returning.",
        },
        {
          icon: "layers",
          title: "Schema as Dart classes",
          desc: "Tables are plain classes. No build_runner, no generated files to commit.",
        },
        {
          icon: "package",
          title: "Three databases",
          desc: "One API over SQLite, PostgreSQL and MySQL — the driver handles the dialect.",
        },
        {
          icon: "blocks",
          title: "Relations without N+1",
          desc: "Batched one-to-many, one-to-one and many-to-many loaders — 2–3 queries, never N+1.",
        },
        {
          icon: "shield",
          title: "Migrations & CLI",
          desc: "Filesystem .sql migrations, schema diffing and the dartonic CLI (init/migrate/studio).",
        },
        {
          icon: "check",
          title: "Zero dynamic",
          desc: "Typed columns, typed rows, parameterized queries — SQL-injection-safe by construction.",
        },
      ],
    },
    perf: {
      title: "Built for real workloads",
      subtitle:
        "Dartonic sends parameterized SQL straight to the native driver — thin, safe and pool-ready.",
      chips: [
        { label: "Connection pooling", desc: "PoolConfig for Postgres & MySQL." },
        { label: "Prepared-statement cache", desc: "Repeated queries reuse statements." },
        { label: "Parameterized queries", desc: "No string interpolation of user data." },
      ],
    },
    examples: {
      title: "Real Dart, no magic",
      subtitle: "Pick a tab to see Dartonic in action.",
      tabs: {
        routes: "Schema",
        middleware: "Queries",
        validation: "Relations",
        websocket: "Transactions",
      },
    },
    usedFor: {
      title: "Used for",
      subtitle: "Wherever your Dart app talks to SQL, Dartonic fits.",
      items: [
        {
          title: "REST API backends",
          desc: "Pair it with darto (or any server) for a fully-typed data layer.",
        },
        {
          title: "Flutter local database",
          desc: "SQLite on device with the same schema and query API as the server.",
        },
        {
          title: "CLI tools & scripts",
          desc: "Migrations, seeds and one-off scripts with the dartonic CLI.",
        },
        {
          title: "Multi-database apps",
          desc: "Develop on SQLite, deploy on PostgreSQL or MySQL — the same code.",
        },
      ],
    },
    realWorld: {
      title: "Real-world usage",
      subtitle: "Snippets you can paste into a Dartonic project today.",
      tabs: {
        api: "CRUD",
        auth: "Relations",
        upload: "Transaction",
      },
      samples: {
        api: `// Insert with RETURNING, then query back
final created = await db.insert(users)
  .values([users.email.value('ada@example.com'), users.name.value('Ada')])
  .returning([users.id]);

final ada = await db.select().from(users)
  .where(eq(users.id, created.first.read(users.id)))
  .first();`,
        auth: `// Eager-load a one-to-many relation (no N+1)
final withPosts = await db.orm(users).findManyWithRelations(
  with_: {'posts': true},
  where: eq(users.active, true),
);
// → [{ id, name, posts: [ {..}, {..} ] }, ...]`,
        upload: `// Move money atomically — any throw rolls back
await db.transaction((tx) async {
  await tx.update(accounts)
    .set([accounts.balance.value(900)])
    .where(eq(accounts.id, 1));
  await tx.update(accounts)
    .set([accounts.balance.value(1100)])
    .where(eq(accounts.id, 2));
});`,
      },
    },
    compare: {
      title: "Why Dartonic over the alternatives",
      subtitle: "Type safety and ergonomics — without a code-generation step.",
      headers: ["Feature", "Dartonic", "Raw driver", "Codegen ORMs"],
      rows: [
        ["Type-safe queries", "✅", "❌", "✅"],
        ["No code generation", "✅", "✅", "❌"],
        ["Relations (no N+1)", "✅", "⚙️", "⚠️"],
        ["SQLite / Postgres / MySQL", "✅", "⚙️", "⚠️"],
        ["Migrations & CLI", "✅", "❌", "⚠️"],
        ["Injection-safe by default", "✅", "⚙️", "✅"],
      ],
      note: "Raw drivers give you full control but no type safety; codegen ORMs add a build step. Dartonic keeps the types and drops the codegen.",
    },
    how: {
      title: "How it works",
      subtitle: "Three steps. Define a schema, connect, query.",
      steps: [
        {
          title: "Define a schema",
          desc: "Tables are plain Dart classes — columns are typed fields.",
          code: "class UsersTable extends Table {\n  final id    = integer('id').primaryKey(autoIncrement: true);\n  final email = text('email').notNull().unique();\n}\nfinal users = UsersTable();",
        },
        {
          title: "Connect",
          desc: "Pick a driver; sync creates the tables. Pool for Postgres/MySQL.",
          code: "final db = await connectSqlite(\n  ':memory:',\n  schemas: [users],\n);",
        },
        {
          title: "Query",
          desc: "A fluent, fully-typed builder — just await it.",
          code: "final rows = await db.select()\n  .from(users)\n  .where(eq(users.id, 1));",
        },
      ],
    },
    why: {
      title: "Why Dartonic",
      subtitle: "A data layer that respects how Dart developers actually work.",
      items: [
        {
          title: "No code generation",
          desc: "Schemas are plain classes. No build_runner, no generated files to keep in sync.",
        },
        {
          title: "Type-safe end to end",
          desc: "Columns, conditions and rows are typed — mistakes are compile errors, not runtime ones.",
        },
        {
          title: "One API, many databases",
          desc: "Write once against the query builder; the driver adapts the SQL dialect.",
        },
      ],
    },
    cta: {
      title: "Type-safe SQL in your next Dart app",
      subtitle: "Add dartonic_core and a driver to your pubspec and run your first query in under a minute.",
      install: "Install",
      docs: "Documentation",
    },
    callouts: { tip: "Tip", warning: "Warning", bestPractice: "Best practice" },
    footer: {
      rights: "All rights reserved.",
      made: "A type-safe SQL query builder & ORM for Dart — inspired by Drizzle",
    },
    docs: {
      search: "Search the docs…",
      onThisPage: "On this page",
      previous: "Previous",
      next: "Next",
      badge: "Documentation",
      title: "Dartonic Docs",
      subtitle: "Schema DSL, the query builder, relations, transactions, migrations and more.",
      results: (n: number, q: string) => `${n} result${n === 1 ? "" : "s"} for "${q}"`,
      noMatches: "No matches.",
      groups: {
        start: "Getting Started",
        schema: "Schema",
        connections: "Connections",
        queries: "Queries",
        mutations: "Mutations",
        transactions: "Transactions",
        relations: "Relations",
        advanced: "Advanced",
        migrations: "Migrations",
        tooling: "CLI & Studio",
        validation: "Validation",
        errors: "Error Handling",
        examples: "Examples",
        reference: "Package Reference",
      },
    },
  },
  pt: {
    nav: { docs: "Documentação", github: "GitHub", getStarted: "Começar" },
    hero: {
      badge: "v1.0 · SQL type-safe para Dart",
      title1: "SQL type-safe para Dart,",
      title2: "inspirado no Drizzle.",
      subtitle:
        "Defina o schema uma vez como classes Dart e consulte SQLite, PostgreSQL e MySQL com um builder fluente e totalmente tipado. Sem code generation. Sem dynamic.",
      cta1: "Começar",
      cta2: "Ver documentação",
      installNote: "dart pub add dartonic_core",
      tagline: "Um schema, três bancos. Dart puro. Sem codegen.",
      credibility: {
        version: "v1.0.0",
        oss: "Código aberto · MIT",
        pub: "pub.dev",
        github: "GitHub",
      },
    },
    features: {
      title: "Tudo que você espera de um ORM moderno",
      subtitle:
        "DSL de schema, query builder tipado, relações, transações e migrations — para SQLite, PostgreSQL e MySQL.",
      items: [
        {
          icon: "route",
          title: "Query builder tipado",
          desc: "select / insert / update / delete com condições tipadas, joins, agregações e returning.",
        },
        {
          icon: "layers",
          title: "Schema como classes Dart",
          desc: "Tabelas são classes comuns. Sem build_runner, sem arquivos gerados para versionar.",
        },
        {
          icon: "package",
          title: "Três bancos de dados",
          desc: "Uma API sobre SQLite, PostgreSQL e MySQL — o driver cuida do dialeto.",
        },
        {
          icon: "blocks",
          title: "Relações sem N+1",
          desc: "Carregadores em lote de um-para-muitos, um-para-um e muitos-para-muitos — 2–3 queries, nunca N+1.",
        },
        {
          icon: "shield",
          title: "Migrations & CLI",
          desc: "Migrations .sql em arquivos, schema diffing e a CLI dartonic (init/migrate/studio).",
        },
        {
          icon: "check",
          title: "Zero dynamic",
          desc: "Colunas, linhas e condições tipadas; queries parametrizadas — seguro contra SQL injection.",
        },
      ],
    },
    perf: {
      title: "Feito para cargas reais",
      subtitle:
        "O Dartonic envia SQL parametrizado direto ao driver nativo — fino, seguro e pronto para pool.",
      chips: [
        { label: "Connection pooling", desc: "PoolConfig para Postgres e MySQL." },
        { label: "Cache de prepared statements", desc: "Queries repetidas reusam statements." },
        { label: "Queries parametrizadas", desc: "Sem interpolar dado do usuário em string." },
      ],
    },
    examples: {
      title: "Dart real, sem mágica",
      subtitle: "Escolha uma aba para ver o Dartonic em ação.",
      tabs: {
        routes: "Schema",
        middleware: "Queries",
        validation: "Relações",
        websocket: "Transações",
      },
    },
    usedFor: {
      title: "Para que serve",
      subtitle: "Onde quer que seu app Dart fale com SQL, o Dartonic se encaixa.",
      items: [
        {
          title: "Backends de API REST",
          desc: "Combine com o darto (ou qualquer servidor) para uma camada de dados tipada.",
        },
        {
          title: "Banco local no Flutter",
          desc: "SQLite no dispositivo com o mesmo schema e a mesma API do servidor.",
        },
        {
          title: "Ferramentas & scripts CLI",
          desc: "Migrations, seeds e scripts pontuais com a CLI dartonic.",
        },
        {
          title: "Apps multi-banco",
          desc: "Desenvolva em SQLite, publique em PostgreSQL ou MySQL — o mesmo código.",
        },
      ],
    },
    realWorld: {
      title: "Casos de uso reais",
      subtitle: "Snippets prontos para colar no seu projeto Dartonic hoje.",
      tabs: {
        api: "CRUD",
        auth: "Relações",
        upload: "Transação",
      },
      samples: {
        api: `// Insert com RETURNING e consulta de volta
final created = await db.insert(users)
  .values([users.email.value('ada@example.com'), users.name.value('Ada')])
  .returning([users.id]);

final ada = await db.select().from(users)
  .where(eq(users.id, created.first.read(users.id)))
  .first();`,
        auth: `// Carrega uma relação um-para-muitos (sem N+1)
final withPosts = await db.orm(users).findManyWithRelations(
  with_: {'posts': true},
  where: eq(users.active, true),
);
// → [{ id, name, posts: [ {..}, {..} ] }, ...]`,
        upload: `// Move dinheiro de forma atômica — qualquer throw dá rollback
await db.transaction((tx) async {
  await tx.update(accounts)
    .set([accounts.balance.value(900)])
    .where(eq(accounts.id, 1));
  await tx.update(accounts)
    .set([accounts.balance.value(1100)])
    .where(eq(accounts.id, 2));
});`,
      },
    },
    compare: {
      title: "Por que Dartonic em vez das alternativas",
      subtitle: "Type-safety e ergonomia — sem passo de code generation.",
      headers: ["Recurso", "Dartonic", "Driver cru", "ORMs com codegen"],
      rows: [
        ["Queries type-safe", "✅", "❌", "✅"],
        ["Sem code generation", "✅", "✅", "❌"],
        ["Relações (sem N+1)", "✅", "⚙️", "⚠️"],
        ["SQLite / Postgres / MySQL", "✅", "⚙️", "⚠️"],
        ["Migrations & CLI", "✅", "❌", "⚠️"],
        ["Seguro contra injection", "✅", "⚙️", "✅"],
      ],
      note: "Drivers crus dão controle total mas sem type-safety; ORMs com codegen adicionam um passo de build. O Dartonic mantém os tipos e dispensa o codegen.",
    },
    how: {
      title: "Como funciona",
      subtitle: "Três passos. Defina um schema, conecte, consulte.",
      steps: [
        {
          title: "Defina um schema",
          desc: "Tabelas são classes Dart comuns — colunas são campos tipados.",
          code: "class UsersTable extends Table {\n  final id    = integer('id').primaryKey(autoIncrement: true);\n  final email = text('email').notNull().unique();\n}\nfinal users = UsersTable();",
        },
        {
          title: "Conecte",
          desc: "Escolha um driver; o sync cria as tabelas. Pool para Postgres/MySQL.",
          code: "final db = await connectSqlite(\n  ':memory:',\n  schemas: [users],\n);",
        },
        {
          title: "Consulte",
          desc: "Um builder fluente e totalmente tipado — só dar await.",
          code: "final rows = await db.select()\n  .from(users)\n  .where(eq(users.id, 1));",
        },
      ],
    },
    why: {
      title: "Por que Dartonic",
      subtitle: "Uma camada de dados que respeita como devs Dart realmente trabalham.",
      items: [
        {
          title: "Sem code generation",
          desc: "Schemas são classes comuns. Sem build_runner, sem arquivos gerados para manter em sincronia.",
        },
        {
          title: "Type-safe de ponta a ponta",
          desc: "Colunas, condições e linhas tipadas — erros viram erro de compilação, não de runtime.",
        },
        {
          title: "Uma API, vários bancos",
          desc: "Escreva uma vez no query builder; o driver adapta o dialeto SQL.",
        },
      ],
    },
    cta: {
      title: "SQL type-safe no seu próximo app Dart",
      subtitle: "Adicione dartonic_core e um driver ao pubspec e rode sua primeira query em menos de um minuto.",
      install: "Instalar",
      docs: "Documentação",
    },
    callouts: { tip: "Dica", warning: "Atenção", bestPractice: "Boa prática" },
    footer: {
      rights: "Todos os direitos reservados.",
      made: "Um query builder & ORM SQL type-safe para Dart — inspirado no Drizzle",
    },
    docs: {
      search: "Buscar na documentação…",
      onThisPage: "Nesta página",
      previous: "Anterior",
      next: "Próximo",
      badge: "Documentação",
      title: "Documentação Dartonic",
      subtitle: "DSL de schema, query builder, relações, transações, migrations e mais.",
      results: (n: number, q: string) => `${n} resultado${n === 1 ? "" : "s"} para "${q}"`,
      noMatches: "Nenhum resultado.",
      groups: {
        start: "Primeiros passos",
        schema: "Schema",
        connections: "Conexões",
        queries: "Consultas",
        mutations: "Mutações",
        transactions: "Transações",
        relations: "Relações",
        advanced: "Avançado",
        migrations: "Migrations",
        tooling: "CLI & Studio",
        validation: "Validação",
        errors: "Tratamento de erros",
        examples: "Exemplos",
        reference: "Referência de pacotes",
      },
    },
  },
};

export type Translations = typeof translations.en;
