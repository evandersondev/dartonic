import 'dart:core';

class ColumnType {
  final String? columnName;
  final String baseType;
  // The mode property allows conversion for types:
  // For INTEGER: 'number' (default), 'boolean', 'timestamp'.
  // For TEXT: 'string' (default), 'json'.
  final String? mode;
  final List<String> modifiers = [];

  // Constructor accepts an optional mode.
  ColumnType(this.baseType, [this.columnName, this.mode]);

  ColumnType notNull() {
    modifiers.add("NOT NULL");
    return this;
  }

  ColumnType unique() {
    modifiers.add("UNIQUE");
    return this;
  }

  ColumnType primaryKey({bool autoIncrement = false}) {
    if (autoIncrement) {
      modifiers.add("PRIMARY KEY AUTOINCREMENT");
    } else {
      modifiers.add("PRIMARY KEY");
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
  ColumnType defaultVal(dynamic value) {
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

// Exported column helper functions adapted from Drizzle syntax.
ColumnType serial({String? columnName}) =>
    ColumnType("SERIAL AUTO_INCREMENT", columnName);

ColumnType varchar(
        {String? columnName, List<String>? enumerate, int length = 255}) =>
    ColumnType("VARCHAR($length)", columnName);

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

ColumnType $double({String? columnName, int? precision, int? scale}) {
  String typeStr = "DOUBLE";
  if (precision != null) {
    typeStr += "($precision${scale != null ? ",$scale" : ""})";
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

ColumnType char({String? columnName}) => ColumnType("CHAR", columnName);

ColumnType boolean({String? columnName}) => ColumnType("BOOLEAN", columnName);

ColumnType date({String? columnName}) => ColumnType("DATE", columnName);

ColumnType datetime({String? columnName, int? fsp}) {
  String typeStr = "DATETIME";
  if (fsp != null) {
    typeStr += "($fsp)";
  }
  return ColumnType(typeStr, columnName);
}

ColumnType time({String? columnName, int? fsp}) {
  String typeStr = "DATETIME";
  if (fsp != null) {
    typeStr += "($fsp)";
  }
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
ColumnType timestamp({String? columnName, String mode = 'date'}) {
  String base;
  switch (mode) {
    case 'string':
      base = 'TEXT';
      break;
    case 'number':
      base = 'NUMERIC';
      break;
    case 'date':
    default:
      base = 'DATETIME';
      break;
  }
  return ColumnType(base, columnName);
}

/// Helper to inject raw SQL expressions.
String sql(String value) => value;
