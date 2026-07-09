import 'package:dartonic_core/dartonic_core.dart';
import 'package:zard/zard.dart';

/// A per-column schema override passed via the `refine` argument of
/// [createInsertSchema] / [createSelectSchema] / [createUpdateSchema].
///
/// The value fully replaces the *base* schema derived from the column's type,
/// but the builder still applies presence rules (optional / nullable) from the
/// column metadata on top of it. So `refine: {'email': z.string().email()}`
/// tightens the validation of `email` without you having to restate that it is
/// required (from `NOT NULL`) or omitted (from an auto-increment key).
typedef SchemaOverrides = Map<String, Schema>;

/// Maps a Dartonic [Column] to its base zard [Schema] by concrete column type.
///
/// `PgEnumColumn` and `UuidColumn` are checked before their `TextColumn`
/// supertype so the more specific mapping wins.
Schema baseSchemaForColumn(Column<Object?> col) {
  if (col is PgEnumColumn) return z.$enum(col.enumDefinition.values);
  if (col is UuidColumn) return z.string().uuid();
  if (col is TextColumn) return z.string();
  if (col is IntColumn) return z.int();
  if (col is DoubleColumn) return z.double();
  if (col is BoolColumn) return z.bool();
  if (col is DateTimeColumn) return z.date();
  if (col is JsonColumn) return z.map(const <String, Schema>{}); // permissive
  if (col is BlobColumn) return z.string(); // transported as base64
  return z.string(); // conservative fallback
}

/// True when the database generates the value, so it must NOT appear in an
/// insert payload: auto-increment integer PKs and auto-generate UUID PKs.
bool _isGenerated(Column<Object?> col) =>
    col.isAutoGenerate ||
    col.modifiers.any((m) => m.contains('AUTOINCREMENT'));

/// True when the column has a SQL `DEFAULT` (including `DEFAULT CURRENT_TIMESTAMP`),
/// so it may be omitted from an insert payload.
bool _hasDefault(Column<Object?> col) =>
    col.modifiers.any((m) => m.startsWith('DEFAULT'));

Schema _base(Column<Object?> col, SchemaOverrides refine) =>
    refine[col.column] ?? baseSchemaForColumn(col);

/// Derives a zard schema describing a **full row** of [table] — every column is
/// present. Nullable columns become `.nullable()`.
///
/// ```dart
/// final selectUser = createSelectSchema(users);
/// // z.map({ 'id': z.int(), 'name': z.string(), 'age': z.int().nullable(), ... })
/// ```
ZMap createSelectSchema(Table table, {SchemaOverrides refine = const {}}) {
  final shape = <String, Schema>{};
  for (final col in table.columns) {
    var s = _base(col, refine);
    if (col.nullable) s = s.nullable();
    shape[col.column] = s;
  }
  return z.map(shape);
}

/// Derives a zard schema for an **insert payload**: database-generated columns
/// (auto-increment / auto-generate PKs) are omitted; columns that are nullable
/// or have a SQL default become optional; `NOT NULL` columns without a default
/// stay required.
///
/// ```dart
/// final insertUser = createInsertSchema(users, refine: {
///   'email': z.string().email(),
/// });
/// ```
ZMap createInsertSchema(Table table, {SchemaOverrides refine = const {}}) {
  final shape = <String, Schema>{};
  for (final col in table.columns) {
    if (_isGenerated(col)) continue;
    var s = _base(col, refine);
    if (col.nullable) s = s.nullable();
    if (col.nullable || _hasDefault(col)) s = s.optional();
    shape[col.column] = s;
  }
  return z.map(shape);
}

/// Derives a zard schema for an **update payload**: like [createInsertSchema]
/// but every field is optional (a partial), since updates set a subset.
ZMap createUpdateSchema(Table table, {SchemaOverrides refine = const {}}) {
  final shape = <String, Schema>{};
  for (final col in table.columns) {
    if (_isGenerated(col)) continue;
    var s = _base(col, refine);
    if (col.nullable) s = s.nullable();
    shape[col.column] = s.optional();
  }
  return z.map(shape);
}
