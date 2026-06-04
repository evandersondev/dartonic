import 'dart:convert';
import 'dart:typed_data';

import 'column_ref.dart';
import 'database_error.dart';

/// Base class for typed schema columns.
///
/// A column is parameterized by its Dart [T] type. Concrete subclasses
/// ([IntColumn], [TextColumn], etc.) own the encode/decode logic for their
/// type.
///
/// Columns are declared on a [Table] subclass. The framework collects them
/// automatically:
///
/// ```dart
/// class Users extends Table {
///   final id    = integer('id').primaryKey(autoIncrement: true);
///   final email = text('email').notNull().unique();
///
///   @override String get tableName => 'users';
/// }
/// ```
abstract class Column<T> extends ColumnRef<T> {
  // ── Internal pending registry ──────────────────────────────────────────
  //
  // Every column factory ([integer], [text], …) pushes its newly-created
  // column onto [_pending]. The [Table] constructor body — which runs after
  // the subclass field initializers have fired — drains the list and binds
  // each column to its owning [Table].
  //
  // These statics are public-by-convention so the [Table] class can reach
  // in; treat them as private.

  static final List<Column<Object?>> _pending = [];

  /// Internal — called by every column factory in this file.
  static void track(Column<Object?> column) => _pending.add(column);

  /// Internal — called by [Table] to consume the pending columns and reset.
  static List<Column<Object?>> takePending() {
    final list = List<Column<Object?>>.from(_pending);
    _pending.clear();
    return list;
  }

  // ── Public column shape ────────────────────────────────────────────────

  /// SQL column name.
  @override
  final String column;

  /// Underlying SQL type, e.g. `INTEGER`, `TEXT`, `JSONB`.
  final String sqlType;

  /// Whether the column accepts NULL. Toggled to `false` by [notNull].
  bool nullable;

  /// SQL modifiers appended after the type (e.g. `PRIMARY KEY`, `UNIQUE`).
  final List<String> modifiers = [];

  String? _tableName;

  Column({required this.column, required this.sqlType, this.nullable = true});

  @override
  String get table => _tableName ?? '';

  /// Internal: binds the column to its owning table. Called by [Table].
  void bindToTable(String tableName) {
    _tableName = tableName;
  }

  // ── Fluent modifiers ────────────────────────────────────────────────────

  /// Marks the column as `NOT NULL`. Returns `this` for chaining.
  Column<T> notNull() {
    if (modifiers.contains('NOT NULL')) {
      throw TypeValidationError('Column "$column" is already NOT NULL');
    }
    modifiers.add('NOT NULL');
    nullable = false;
    return this;
  }

  /// Marks the column as `UNIQUE`. Returns `this` for chaining.
  Column<T> unique() {
    if (modifiers.contains('UNIQUE')) {
      throw TypeValidationError('Column "$column" is already UNIQUE');
    }
    modifiers.add('UNIQUE');
    return this;
  }

  /// Marks the column as a primary key. Pass [autoIncrement] for serial ints,
  /// or [autoGenerate] for UUID auto-generation.
  Column<T> primaryKey({bool autoIncrement = false, bool autoGenerate = false}) {
    if (autoIncrement && autoGenerate) {
      throw TypeValidationError(
          'autoIncrement and autoGenerate are mutually exclusive');
    }
    if (modifiers.any((m) => m.startsWith('PRIMARY KEY'))) {
      throw TypeValidationError('Column "$column" is already a primary key');
    }
    if (autoGenerate && sqlType != 'UUID') {
      throw TypeValidationError(
          'autoGenerate is only valid for UUID columns');
    }
    if (autoIncrement) {
      modifiers.add('PRIMARY KEY AUTOINCREMENT');
    } else if (autoGenerate) {
      modifiers.add('PRIMARY KEY AUTOGENERATE');
    } else {
      modifiers.add('PRIMARY KEY');
    }
    return this;
  }

  /// Adds a FOREIGN KEY reference to another column.
  ///
  /// Pass a thunk so the target column can be declared in any order (avoids
  /// circular initialization between two tables in the same file):
  ///
  /// ```dart
  /// final userId = integer('user_id')
  ///     .notNull()
  ///     .references(() => users.id, onDelete: ReferentialAction.cascade);
  /// ```
  Column<T> references(
    ColumnRef<T> Function() target, {
    ReferentialAction? onDelete,
    ReferentialAction? onUpdate,
  }) {
    _pendingReference = _PendingReference(target, onDelete, onUpdate);
    return this;
  }

  _PendingReference? _pendingReference;

  /// Adds `DEFAULT <value>` to the column DDL.
  Column<T> withDefault(Object value) {
    modifiers.add('DEFAULT $value');
    return this;
  }

  /// Adds `DEFAULT CURRENT_TIMESTAMP` to the column DDL.
  Column<T> defaultNow() {
    modifiers.add('DEFAULT CURRENT_TIMESTAMP');
    return this;
  }

  /// Returns true if this column has an `AUTOGENERATE` modifier (UUID).
  bool get isAutoGenerate => modifiers.contains('PRIMARY KEY AUTOGENERATE');

  /// Returns the column DDL fragment, e.g. `INTEGER NOT NULL PRIMARY KEY`.
  String toDdl() {
    var ddl = '$sqlType ${modifiers.join(' ')}'.trim();
    final ref = _pendingReference;
    if (ref != null) {
      final target = ref.target();
      var sql =
          'REFERENCES "${target.table}"("${target.column}")';
      if (ref.onDelete != null) sql += ' ON DELETE ${ref.onDelete!.sql}';
      if (ref.onUpdate != null) sql += ' ON UPDATE ${ref.onUpdate!.sql}';
      ddl = '$ddl $sql'.trim();
    }
    return ddl;
  }

  // ── Codec hooks (override in concrete classes) ──────────────────────────

  @override
  Object? encode(T? value);

  @override
  T? decode(Object? raw);

  /// Binds a typed value to this column. Used as the argument for
  /// `db.insert(table).values([...])` and `db.update(table).set([...])`.
  ColumnValue<T> value(T value) => ColumnValue<T>(this, value);
}

/// Foreign-key cascade behavior used by [Column.references] and [ForeignKey].
enum ReferentialAction { cascade, restrict, noAction, setNull, setDefault }

extension ReferentialActionSql on ReferentialAction {
  String get sql => switch (this) {
        ReferentialAction.cascade => 'CASCADE',
        ReferentialAction.restrict => 'RESTRICT',
        ReferentialAction.noAction => 'NO ACTION',
        ReferentialAction.setNull => 'SET NULL',
        ReferentialAction.setDefault => 'SET DEFAULT',
      };
}

/// Internal: stores a deferred FK target so the reference can be declared
/// before the target column exists (lazy via thunk).
class _PendingReference<T> {
  final ColumnRef<T> Function() target;
  final ReferentialAction? onDelete;
  final ReferentialAction? onUpdate;
  const _PendingReference(this.target, this.onDelete, this.onUpdate);
}

/// A typed value bound to a [Column]. Built via [Column.value].
class ColumnValue<T> {
  final Column<T> column;
  final T value;
  const ColumnValue(this.column, this.value);

  /// Encoded raw value the driver receives.
  Object? get encoded => column.encode(value);
}

// ── Concrete column types ─────────────────────────────────────────────────

class IntColumn extends Column<int> {
  IntColumn(String name, {String type = 'INTEGER'})
      : super(column: name, sqlType: type);

  @override
  Object? encode(int? value) => value;

  @override
  int? decode(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}

class DoubleColumn extends Column<double> {
  DoubleColumn(String name, {String type = 'REAL'})
      : super(column: name, sqlType: type);

  @override
  Object? encode(double? value) => value;

  @override
  double? decode(Object? raw) {
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.replaceAll(',', '.'));
    return null;
  }
}

class TextColumn extends Column<String> {
  TextColumn(String name, {String type = 'TEXT'})
      : super(column: name, sqlType: type);

  @override
  Object? encode(String? value) => value;

  @override
  String? decode(Object? raw) => raw?.toString();
}

class BoolColumn extends Column<bool> {
  BoolColumn(String name, {String type = 'INTEGER'})
      : super(column: name, sqlType: type);

  @override
  Object? encode(bool? value) {
    if (value == null) return null;
    return value ? 1 : 0;
  }

  @override
  bool? decode(Object? raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    if (raw is int) return raw != 0;
    if (raw is String) return raw == '1' || raw.toLowerCase() == 'true';
    return null;
  }
}

class DateTimeColumn extends Column<DateTime> {
  /// Storage strategy:
  /// - `string`: ISO-8601 text (the default for SQLite TIMESTAMP)
  /// - `epoch_ms`: integer milliseconds since epoch
  /// - `native`: pass through (Postgres returns native DateTime)
  final DateTimeStorage storage;

  DateTimeColumn(
    String name, {
    String type = 'DATETIME',
    this.storage = DateTimeStorage.string,
  }) : super(column: name, sqlType: type);

  @override
  Object? encode(DateTime? value) {
    if (value == null) return null;
    switch (storage) {
      case DateTimeStorage.epochMs:
        return value.toUtc().millisecondsSinceEpoch;
      case DateTimeStorage.native:
        return value;
      case DateTimeStorage.string:
        return value.toUtc().toIso8601String();
    }
  }

  @override
  DateTime? decode(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
    }
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

enum DateTimeStorage { string, epochMs, native }

class JsonColumn<T> extends Column<T> {
  final T Function(Object decoded) decoder;
  final Object Function(T value) encoder;

  JsonColumn(
    String name, {
    required this.decoder,
    required this.encoder,
    String type = 'TEXT',
  }) : super(column: name, sqlType: type);

  @override
  Object? encode(T? value) {
    if (value == null) return null;
    return jsonEncode(encoder(value));
  }

  @override
  T? decode(Object? raw) {
    if (raw == null) return null;
    final source = raw is String ? jsonDecode(raw) : raw;
    return decoder(source as Object);
  }
}

class UuidColumn extends Column<String> {
  UuidColumn(String name, {String type = 'UUID'})
      : super(column: name, sqlType: type);

  @override
  Object? encode(String? value) => value;

  @override
  String? decode(Object? raw) => raw?.toString();
}

class BlobColumn extends Column<Uint8List> {
  BlobColumn(String name, {String type = 'BLOB'})
      : super(column: name, sqlType: type);

  @override
  Object? encode(Uint8List? value) => value;

  @override
  Uint8List? decode(Object? raw) {
    if (raw == null) return null;
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    return null;
  }
}

// ── Top-level factories (typed, auto-registered) ──────────────────────────
//
// Each factory creates a typed [Column<T>] and registers it with the
// [Table] currently being constructed (see [Column.track]). You can call
// these inside any `final fieldName = …` initializer of a [Table] subclass.

C _r<C extends Column<Object?>>(C c) {
  Column.track(c);
  return c;
}

IntColumn integer(String name) => _r(IntColumn(name));
IntColumn serial(String name) => _r(IntColumn(name, type: 'SERIAL'));
IntColumn smallserial(String name) =>
    _r(IntColumn(name, type: 'SMALLSERIAL'));
IntColumn bigserial(String name) => _r(IntColumn(name, type: 'BIGSERIAL'));
IntColumn tinyint(String name) => _r(IntColumn(name, type: 'TINYINT'));
IntColumn smallint(String name) => _r(IntColumn(name, type: 'SMALLINT'));
IntColumn bigint(String name) => _r(IntColumn(name, type: 'BIGINT'));
IntColumn mediumint(String name) => _r(IntColumn(name, type: 'MEDIUMINT'));

TextColumn text(String name) => _r(TextColumn(name));
TextColumn varchar(String name, {int length = 255}) =>
    _r(TextColumn(name, type: 'VARCHAR($length)'));
TextColumn char(String name, {int length = 256}) =>
    _r(TextColumn(name, type: 'CHAR($length)'));

DoubleColumn real(String name, {int? precision, int? scale}) {
  var t = 'REAL';
  if (precision != null) t += '($precision${scale != null ? ',$scale' : ''})';
  return _r(DoubleColumn(name, type: t));
}

DoubleColumn decimal(String name, {int? precision, int? scale}) {
  var t = 'DECIMAL';
  if (precision != null) t += '($precision${scale != null ? ',$scale' : ''})';
  return _r(DoubleColumn(name, type: t));
}

DoubleColumn numeric(String name, {int? precision, int? scale}) {
  var t = 'NUMERIC';
  if (precision != null) t += '($precision${scale != null ? ',$scale' : ''})';
  return _r(DoubleColumn(name, type: t));
}

DoubleColumn doubleColumn(String name, {int? precision, int? scale}) {
  var t = 'DOUBLE';
  if (precision != null) t += '($precision${scale != null ? ',$scale' : ''})';
  return _r(DoubleColumn(name, type: t));
}

DoubleColumn doublePrecision(String name, {double? precision}) {
  var t = 'DOUBLE PRECISION';
  if (precision != null) t += ' $precision';
  return _r(DoubleColumn(name, type: t));
}

DoubleColumn floatColumn(String name) =>
    _r(DoubleColumn(name, type: 'DOUBLE'));

BoolColumn boolean(String name) => _r(BoolColumn(name));

DateTimeColumn datetime(
  String name, {
  int? fsp,
  DateTimeStorage storage = DateTimeStorage.string,
}) {
  var t = 'DATETIME';
  if (fsp != null) t += '($fsp)';
  return _r(DateTimeColumn(name, type: t, storage: storage));
}

DateTimeColumn date(String name) => _r(DateTimeColumn(name, type: 'DATE'));

DateTimeColumn timestamp(
  String name, {
  int? precision,
  bool withTimezone = false,
  DateTimeStorage storage = DateTimeStorage.string,
}) {
  var t = 'TIMESTAMP';
  if (precision != null) {
    t += withTimezone ? '($precision) WITH TIME ZONE' : '($precision)';
  } else if (withTimezone) {
    t += ' WITH TIME ZONE';
  }
  return _r(DateTimeColumn(name, type: t, storage: storage));
}

DateTimeColumn time(String name, {int? fsp, bool withTimezone = false}) {
  var t = 'TIME';
  if (fsp != null) t += '($fsp)';
  if (withTimezone) t += ' WITH TIMEZONE';
  return _r(DateTimeColumn(name, type: t));
}

UuidColumn uuid(String name) => _r(UuidColumn(name));

BlobColumn blob(String name) => _r(BlobColumn(name));
BlobColumn binary(String name) => _r(BlobColumn(name, type: 'BINARY'));
BlobColumn varbinary(String name, {int? length}) {
  var t = 'VARBINARY';
  if (length != null) t += '($length)';
  return _r(BlobColumn(name, type: t));
}

/// JSON column with explicit encoder/decoder.
JsonColumn<T> json<T>(
  String name, {
  required T Function(Object decoded) decoder,
  required Object Function(T value) encoder,
  bool binary = false,
}) =>
    _r(JsonColumn<T>(
      name,
      decoder: decoder,
      encoder: encoder,
      type: binary ? 'JSONB' : 'JSON',
    ));

/// Convenience for JSON columns that round-trip as Dart maps.
JsonColumn<Map<String, Object?>> jsonMap(String name, {bool binary = false}) =>
    _r(JsonColumn<Map<String, Object?>>(
      name,
      decoder: (raw) => (raw as Map).cast<String, Object?>(),
      encoder: (value) => value,
      type: binary ? 'JSONB' : 'JSON',
    ));

/// Raw SQL literal wrapper — appears as-is in DDL or expressions.
String sql(String value) => value;

// ── Postgres ENUM support ─────────────────────────────────────────────────

class PgEnumDefinition {
  final String name;
  final List<String> values;

  PgEnumDefinition(this.name, this.values);

  PgEnumColumn call(String columnName) =>
      _r(PgEnumColumn(columnName, this));

  String toSql() =>
      "CREATE TYPE $name AS ENUM (${values.map((v) => "'$v'").join(', ')});";

  String dropSql() => 'DROP TYPE IF EXISTS $name;';
}

class PgEnumColumn extends TextColumn {
  final PgEnumDefinition enumDefinition;

  PgEnumColumn(String name, this.enumDefinition)
      : super(name, type: enumDefinition.name);
}

PgEnumDefinition pgEnum(String name, List<String> values) =>
    PgEnumDefinition(name, values);
