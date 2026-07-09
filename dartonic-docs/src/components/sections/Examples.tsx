import { useState } from "react";
import { CodeBlock } from "@/components/CodeBlock";
import { useI18n } from "@/lib/i18n-context";
import { cn } from "@/lib/utils";

const SAMPLES = {
  routes: `// Schema as plain Dart classes — no code generation
class UsersTable extends Table {
  final id        = integer('id').primaryKey(autoIncrement: true);
  final email     = text('email').notNull().unique();
  final name      = text('name').notNull();
  final createdAt = datetime('created_at').defaultNow();
}
final users = UsersTable();`,
  middleware: `// A fully-typed, chainable query builder
final list = await db.select().from(users)
  .where(eq(users.email, 'ada@example.com'))
  .orderBy(users.createdAt, Order.desc)
  .limit(20);

await db.insert(users).values([
  users.email.value('ada@example.com'),
  users.name.value('Ada'),
]);`,
  validation: `// Relations without N+1 — one batched query per level
final usersWithPosts = await db.findManyWith<User, Post, int>(
  parent: users,
  parentDecoder: User.fromRow,
  parentKey: (u) => u.id,
  childTable: posts,
  childForeignKey: posts.userId,
  childDecoder: Post.fromRow,
);
// → List<WithChildren<User, Post>>`,
  websocket: `// Atomic transactions — rollback on any error
await db.transaction((tx) async {
  await tx.update(accounts)
    .set([accounts.balance.value(900)])
    .where(eq(accounts.id, 1));
  await tx.update(accounts)
    .set([accounts.balance.value(1100)])
    .where(eq(accounts.id, 2));
});`,
};

export function Examples() {
  const { t } = useI18n();
  const [tab, setTab] = useState<keyof typeof SAMPLES>("routes");

  const tabs: { key: keyof typeof SAMPLES; label: string }[] = [
    { key: "routes", label: t.examples.tabs.routes },
    { key: "middleware", label: t.examples.tabs.middleware },
    { key: "validation", label: t.examples.tabs.validation },
    { key: "websocket", label: t.examples.tabs.websocket },
  ];

  return (
    <section className="border-b border-border section-animate">
      <div className="container py-20 lg:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">{t.examples.title}</h2>
          <p className="mt-3 text-muted-foreground">{t.examples.subtitle}</p>
        </div>

        <div className="mx-auto mt-10 max-w-3xl">
          <div className="mb-4 flex items-center gap-1 border-b border-border">
            {tabs.map(tb => (
              <button
                key={tb.key}
                onClick={() => setTab(tb.key)}
                className={cn(
                  "relative whitespace-nowrap px-3 py-2 text-sm font-medium transition-colors",
                  tab === tb.key
                    ? "text-foreground after:absolute after:inset-x-0 after:-bottom-px after:h-px after:bg-primary"
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                {tb.label}
              </button>
            ))}
          </div>
          <CodeBlock code={SAMPLES[tab]} filename={`${tab}.dart`} />
        </div>
      </div>
    </section>
  );
}