import 'dart:core';

class ColumnType {
  final String? columnName;
  final String baseType;
  // The mode property allows conversion for types:
  // For INTEGER: 'number' (default), 'boolean', 'timestamp'.
  // For TEXT: 'string' (default), 'json'.
  final String? mode;
  final List<String> modifiers = [];
  final bool isEnum;

  // Constructor accepts an optional mode.
  ColumnType(this.baseType, [this.columnName, this.mode, this.isEnum = false]);

  ColumnType notNull() {
    modifiers.add("NOT NULL");
    return this;
  }

  ColumnType unique() {
    modifiers.add("UNIQUE");
    return this;
  }

  // ColumnType primaryKey({bool autoIncrement = false}) {
  //   if (autoIncrement) {
  //     modifiers.add("PRIMARY KEY AUTOINCREMENT");
  //   } else {
  //     modifiers.add("PRIMARY KEY NOT NULL");
  //   }
  //   return this;
  // }
  ColumnType primaryKey(
      {bool autoIncrement = false, bool autoGenerate = false}) {
    if (autoIncrement && autoGenerate) {
      throw ArgumentError(
          'autoIncrement and autoGenerate cannot be used together');
    }

    if (autoGenerate && baseType != 'UUID') {
      throw ArgumentError('autoGenerate can only be used with uuid type');
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

  // Transforms "table.column" into "table(column)" for SQLite.
  ColumnType references(String Function() ref) {
    String rawRef = ref();
    if (rawRef.contains('.')) {
      final parts = rawRef.split('.');
      if (parts.length == 2) {
        rawRef = "${parts[0]}(${parts[1]})";
      }
    }
    modifiers.add("REFERENCES $rawRef");
    return this;
  }

  /// Define a default value using a raw SQL expression.
  ColumnType $default(dynamic value) {
    modifiers.add("DEFAULT $value");
    return this;
  }

  /// Define the default as the current timestamp.
  ColumnType defaultNow() {
    modifiers.add("DEFAULT CURRENT_TIMESTAMP");
    return this;
  }

  @override
  String toString() {
    return "$baseType ${modifiers.join(' ')}".trim();
  }
}

ColumnType serial({String? columnName}) => ColumnType("SERIAL", columnName);

ColumnType smallserial({String? columnName}) =>
    ColumnType("SMALLSERIAL", columnName);

ColumnType bigserial({String? columnName}) =>
    ColumnType("BIGSERIAL", columnName);

ColumnType varchar(
        {String? columnName, List<String>? enumerate, int length = 255}) =>
    ColumnType("VARCHAR($length)", columnName);

ColumnType char({String? columnName, int length = 256}) =>
    ColumnType("CHAR($length)", columnName);

// For INTEGER, mode defaults to 'number', but supports 'boolean' and 'timestamp'.
ColumnType integer({String? columnName, String mode = 'number'}) =>
    ColumnType("INTEGER", columnName, mode);

// For TEXT, mode defaults to 'string', but 'json' is also supported.
ColumnType text(
        {String? columnName,
        String mode = 'string',
        List<String>? enumerate}) =>
    ColumnType("TEXT", columnName, mode);

ColumnType uuid({String? columnName}) => ColumnType("UUID", columnName);

ColumnType real({String? columnName, int? precision, int? scale}) {
  String typeStr = "REAL";

  if (precision != null) {
    typeStr += "($precision${scale != null ? ",$scale" : ""})";
  }
  return ColumnType(typeStr, columnName);
}

ColumnType blob({String? columnName}) => ColumnType("BLOB", columnName);

ColumnType tinyint({String? columnName}) => ColumnType("TINYINT", columnName);

ColumnType smallint({String? columnName}) => ColumnType("SMALLINT", columnName);

ColumnType bigint({String? columnName, bool? unsigned = false}) =>
    ColumnType("BIGINT", columnName);

ColumnType mediumint({String? columnName}) =>
    ColumnType("MEDIUMINT", columnName);

ColumnType decimal({String? columnName, int? precision, int? scale}) {
  String typeStr = "DECIMAL";

  if (precision != null) {
    typeStr += "($precision${scale != null ? ",$scale" : ""})";
  }
  return ColumnType(typeStr, columnName);
}

ColumnType numeric({String? columnName, int? precision, int? scale}) {
  String typeStr = "NUMERIC";

  if (precision != null) {
    typeStr += "($precision${scale != null ? ",$scale" : ""})";
  }
  return ColumnType(typeStr, columnName);
}

ColumnType $double({String? columnName, int? precision, int? scale}) {
  String typeStr = "DOUBLE";

  if (precision != null) {
    typeStr += "($precision${scale != null ? ",$scale" : ""})";
  }
  return ColumnType(typeStr, columnName);
}

ColumnType doublePrecision({String? columnName, double? precision}) {
  String typeStr = "DOUBLE PRECISION";

  if (precision != null) {
    typeStr += " $precision";
  }
  return ColumnType(typeStr, columnName);
}

ColumnType json({String? columnName, Map? map}) {
  String typeStr = "JSON";

  if (map != null) {
    typeStr += '$map';
  }
  return ColumnType(typeStr, columnName);
}

ColumnType jsonb({String? columnName, Map? map}) {
  String typeStr = "JSONB";

  if (map != null) {
    typeStr += '$map';
  }
  return ColumnType(typeStr, columnName);
}

ColumnType $float({String? columnName}) => ColumnType("DOUBLE", columnName);

ColumnType binary({String? columnName}) => ColumnType("BINARY", columnName);

ColumnType varbinary({String? columnName, int? length}) {
  String typeStr = "VARBINARY";

  if (length != null) {
    typeStr += "($length)";
  }
  return ColumnType(typeStr, columnName);
}

ColumnType boolean({String? columnName}) => ColumnType("BOOLEAN", columnName);

ColumnType date({String? columnName}) => ColumnType("DATE", columnName);

ColumnType datetime({String? columnName, int? fsp}) {
  String typeStr = "DATETIME";

  if (fsp != null) {
    typeStr += "($fsp)";
  }
  return ColumnType(typeStr, columnName);
}

ColumnType time({String? columnName, int? fsp, bool? withTimezone = false}) {
  String typeStr = "TIME";
  if (fsp != null) {
    typeStr += "($fsp)";
  }

  if (withTimezone == true) {
    typeStr += " WITH TIMEZONE";
  }

  return ColumnType(typeStr, columnName);
}

ColumnType interval({
  String? columnName,
  String?
      fields, // microsecond, millisecond, second, minute, hour, day, week, month, year, decade, century, millennium
  int? precision,
}) {
  String typeStr = "INTERVAL";

  if (precision != null) {
    typeStr += "($precision)";
  }

  if (fields != null) {
    typeStr += " $fields";
  }

  return ColumnType(typeStr, columnName);
}

/// Creates a point column. The default mode is 'xy', which uses POINT.
/// Use 'tuple' to store as a tuple of numbers.
/// Use 'geography' to store as a geography point.
///
/// example:
/// point: {'x': 1, 'y': 2} or tuple: [1, 2]
ColumnType point({
  String? columnName,
  String mode = 'xy', // xy: {'x': 1, 'y': 2} or tuple: [1, 2]
}) {
  String typeStr = "POINT";

  return ColumnType(typeStr, columnName);
}

ColumnType line({
  String? columnName,
  String mode = 'abc', // abc: { a: 1, b: 2, c: 3 } or tuple: [1, 2, 3]
}) {
  String typeStr = "LINE";

  return ColumnType(typeStr, columnName);
}

ColumnType year({String? columnName, int? fsp}) {
  String typeStr = "YEAR";
  if (fsp != null) {
    typeStr += "($fsp)";
  }
  return ColumnType(typeStr, columnName);
}

ColumnType mysqlEnum(List<String> enumerate, {String? columnName, int? fsp}) =>
    ColumnType("ENUM", columnName);

/// Creates a timestamp column. The default mode is 'date', which uses DATETIME.
/// Use 'string' to store as TEXT and 'number' to store as NUMERIC.
ColumnType timestamp({
  String? columnName,
  int? precision,
  withTimezone = false,
  String mode = 'timestamp', // 'string', 'number', 'date' or 'timestamp'
}) {
  String base;

  switch (mode) {
    case 'string':
      base = 'TEXT';
      break;
    case 'number':
      base = 'NUMERIC';
      break;
    case 'date':
      base = 'DATETIME';
      break;
    case 'timestamp':
      base = 'TIMESTAMP';
      break;
    default:
      base = 'TIMESTAMP';
      break;
  }

  if (precision != null) {
    if (withTimezone) {
      base += "($precision) WITH TIME ZONE";
    } else {
      base += "($precision)";
    }
  }

  return ColumnType(base, columnName);
}

String sql(String value) => value;

PgEnumDefinition pgEnum(String name, List<String> values) {
  return PgEnumDefinition(name, values);
}

typedef PgEnumColumnBuilder = PgEnumColumn Function();

class PgEnumDefinition {
  final String name;
  final List<String> values;
  final PgEnumColumnBuilder builder;

  PgEnumDefinition(this.name, this.values)
      : builder = (() => PgEnumColumn(name));

  PgEnumColumn call() => builder();

  String dropSql() => 'DROP TYPE IF EXISTS $name;';
  String toSql() =>
      'CREATE TYPE $name AS ENUM (${values.map((v) => "'$v'").join(', ')});';
}

class PgEnumColumn extends ColumnType {
  final String enumType;

  PgEnumColumn(this.enumType) : super(enumType, null, null, true);

  @override
  String toString() {
    return '$baseType${modifiers.contains("NOT NULL") ? ' NOT NULL' : ''}';
  }
}
