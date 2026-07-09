/**
 * Generates the llms.txt / llms-full.txt files from the structured docs content.
 *
 * - llms.txt      → a curated index: project summary + grouped links to every
 *                   doc section, each with a one-line description.
 * - llms-full.txt → the entire documentation concatenated as plain Markdown,
 *                   so a model can ingest everything in a single fetch.
 *
 * Both are written to public/ so Vite serves them at the site root
 * (e.g. https://darto-docs.vercel.app/llms.txt).
 *
 * Run with: bun run docs:llms   (also wired into the build script).
 */
import { writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { getDocSections, type Block, type DocSection } from "../src/lib/docs-content";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PUBLIC_DIR = resolve(__dirname, "../public");

const SITE_URL = "https://dartonic-docs.vercel.app";

// llms.txt is conventionally English; we render the English variant of the docs.
const sections = getDocSections("en");

const GROUP_LABELS: Record<DocSection["group"], string> = {
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
};

const GROUP_ORDER: DocSection["group"][] = [
  "start",
  "schema",
  "connections",
  "queries",
  "mutations",
  "transactions",
  "relations",
  "advanced",
  "migrations",
  "tooling",
  "validation",
  "errors",
  "examples",
  "reference",
];

const sectionUrl = (id: string) => `${SITE_URL}/docs?section=${id}`;

/** Collapse whitespace and trim a string to a single clean line. */
const oneLine = (s: string) => s.replace(/\s+/g, " ").trim();

/** Derive a one-line description for a section from its first paragraph. */
function sectionSummary(section: DocSection): string {
  const firstParagraph = section.blocks.find((b): b is Extract<Block, { kind: "p" }> => b.kind === "p");
  const text = firstParagraph ? oneLine(firstParagraph.text) : section.title;
  // Keep it to the first sentence, capped, so the index stays scannable.
  const firstSentence = text.split(/(?<=[.!?])\s/)[0] ?? text;
  return firstSentence.length > 160 ? `${firstSentence.slice(0, 157)}…` : firstSentence;
}

/** Render a single content block to Markdown for llms-full.txt. */
function blockToMarkdown(block: Block): string {
  switch (block.kind) {
    case "p":
      return oneLine(block.text);
    case "h3":
      return `### ${block.text}`;
    case "code": {
      // Code blocks without an explicit lang are Dart (matches the UI default).
      const lang = block.lang ?? "dart";
      const commentChar = lang === "yaml" || lang === "sh" ? "#" : "//";
      const head = block.filename ? `${commentChar} ${block.filename}\n` : "";
      return `\`\`\`${lang}\n${head}${block.code}\n\`\`\``;
    }
    case "ul":
      return block.items.map((i) => `- ${oneLine(i)}`).join("\n");
    case "table": {
      const header = `| ${block.headers.join(" | ")} |`;
      const divider = `| ${block.headers.map(() => "---").join(" | ")} |`;
      const rows = block.rows.map((r) => `| ${r.map((c) => oneLine(c)).join(" | ")} |`);
      return [header, divider, ...rows].join("\n");
    }
    case "note":
      return `> **Note:** ${oneLine(block.text)}`;
    case "callout": {
      const label = { tip: "Tip", warning: "Warning", success: "Success" }[block.variant];
      return `> **${label}:** ${oneLine(block.text)}`;
    }
    case "links":
      return block.links.map((l) => `- [${l.label}](${l.href})`).join("\n");
    case "ref":
      return `See: [${block.label}](${sectionUrl(block.to)})`;
  }
}

// ── llms.txt: curated index ──────────────────────────────────────────────────
function buildIndex(): string {
  const out: string[] = [];
  out.push("# Dartonic");
  out.push("");
  out.push(
    "> A type-safe SQL query builder and ORM for Dart, inspired by Drizzle. Define your " +
      "schema once as plain Dart classes and query SQLite, PostgreSQL and MySQL with a " +
      "fluent, fully-typed builder. No code generation. No dynamic.",
  );
  out.push("");
  out.push(
    "Dartonic is a monorepo: dartonic_core (driver-agnostic query builder, schema DSL, " +
      "relations, migrations and ORM), one package per driver (dartonic_sqlite, " +
      "dartonic_postgres, dartonic_mysql), filesystem migrations (dartonic_migrations_fs), " +
      "a validation bridge to zard (dartonic_zard), a CLI (dartonic_cli) and a DB inspector " +
      "(dartonic_studio). The docs below cover the schema DSL, connections, the query " +
      "builder, mutations, transactions, relations, advanced features, migrations, tooling, " +
      "validation, error handling, examples and a per-package reference.",
  );
  out.push("");

  for (const group of GROUP_ORDER) {
    const groupSections = sections.filter((s) => s.group === group);
    if (groupSections.length === 0) continue;
    out.push(`## ${GROUP_LABELS[group]}`);
    out.push("");
    for (const s of groupSections) {
      const summary = sectionSummary(s);
      // The description is optional; skip it when it would just echo the title.
      out.push(
        summary === s.title
          ? `- [${s.title}](${sectionUrl(s.id)})`
          : `- [${s.title}](${sectionUrl(s.id)}): ${summary}`,
      );
    }
    out.push("");
  }

  out.push("## Optional");
  out.push("");
  out.push(
    `- [Full documentation](${SITE_URL}/llms-full.txt): the entire Dartonic documentation ` +
      "concatenated into a single file.",
  );
  out.push(`- [GitHub repository](https://github.com/evandersondev/dartonic): source code and issues.`);
  out.push(`- [pub.dev package](https://pub.dev/packages/dartonic_core): published package.`);
  out.push("");

  return out.join("\n");
}

// ── llms-full.txt: entire documentation ──────────────────────────────────────
function buildFull(): string {
  const out: string[] = [];
  out.push("# Dartonic — Full Documentation");
  out.push("");
  out.push(
    "> A type-safe SQL query builder and ORM for Dart. This file concatenates the entire " +
      "Dartonic documentation for ingestion by language models.",
  );
  out.push("");
  out.push(`Source: ${SITE_URL}`);
  out.push("");

  let currentGroup: DocSection["group"] | null = null;
  const ordered = GROUP_ORDER.flatMap((g) => sections.filter((s) => s.group === g));

  for (const s of ordered) {
    if (s.group !== currentGroup) {
      currentGroup = s.group;
      out.push(`\n---\n`);
      out.push(`# ${GROUP_LABELS[s.group]}`);
      out.push("");
    }
    out.push(`## ${s.title}`);
    out.push(`<!-- ${sectionUrl(s.id)} -->`);
    out.push("");
    for (const block of s.blocks) {
      out.push(blockToMarkdown(block));
      out.push("");
    }
  }

  return out.join("\n");
}

const index = buildIndex();
const full = buildFull();

writeFileSync(resolve(PUBLIC_DIR, "llms.txt"), index.trimEnd() + "\n");
writeFileSync(resolve(PUBLIC_DIR, "llms-full.txt"), full.trimEnd() + "\n");

console.log(
  `Generated llms.txt (${index.length} chars) and llms-full.txt (${full.length} chars) ` +
    `from ${sections.length} doc sections.`,
);
