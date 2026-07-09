## 1.0.0

- First stable release.
- `createInsertSchema`, `createSelectSchema`, `createUpdateSchema` derive zard
  schemas from Dartonic tables.
- Per-column `refine` overrides; presence rules (required / optional / nullable)
  derived from column metadata (`NOT NULL`, `DEFAULT`, auto-increment /
  auto-generate PKs).
- Type mapping for integer/text/real/boolean/timestamp/uuid/json/blob/pgEnum.
