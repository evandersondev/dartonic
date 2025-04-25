import 'dart:convert';

import '../types/column.dart';

dynamic convertValueForInsert(dynamic value, ColumnType columnType) {
  // Conversão para boolean em campos INTEGER com mode "boolean"
  if (columnType.baseType == "INTEGER" && columnType.mode == "boolean") {
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value == null) {
      return null;
    }
  }

  // Conversão de String para timestamp em campos INTEGER com mode "timestamp"
  if (columnType.baseType == "INTEGER" && columnType.mode == "timestamp") {
    if (value is String) {
      return DateTime.parse(value).millisecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }
  }

  // Conversão para JSON em campos TEXT com mode "json"
  if (columnType.baseType == "TEXT" && columnType.mode == "json") {
    if (value is List || value is Map) {
      return jsonEncode(value);
    }
    if (value is String) {
      return value;
    }
  }

  // Conversão de REAL para double
  if (columnType.baseType == "REAL") {
    return convertReal(value);
  }

  return value;
}

dynamic convertValueForSelect(dynamic value, ColumnType colType) {
  // Converte de INTEGER para bool quando mode for "boolean"
  if (colType.baseType == "INTEGER" && colType.mode == "boolean") {
    if (value is int) {
      return value == 1;
    }
  }

  // Converte de TEXT para JSON quando mode for "json"
  if (colType.baseType == "TEXT" && colType.mode == "json") {
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return value; // Retorna o valor original se não for um JSON válido
      }
    }
  }

  // Converte de INTEGER para DateTime quando mode for "timestamp"
  if (colType.baseType == "INTEGER" && colType.mode == "timestamp") {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
  }

  // Converte valores do tipo REAL para double
  if (colType.baseType == "REAL") {
    return convertReal(value);
  }

  return value;
}

double convertReal(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    final normalized = value.replaceAll(",", ".");
    final parsed = double.tryParse(normalized);
    if (parsed != null) return parsed;
    return 0.0; // Valor padrão para casos inválidos
  }

  return 0.0; // Valor padrão para tipos incompatíveis
}
