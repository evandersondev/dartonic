import 'dart:async';

import 'package:uuid/uuid.dart';

import '../drivers/driver.dart';
import '../types/cte.dart';
import '../types/table.dart';
import '../utils/convertion_helper.dart';
import 'condition.dart';

// Alterações feitas para manter o nome original da tabela para lookup em _schemas.
// Será criado um atributo _tableName para armazenar o nome original, e _table escapado será utilizado somente na geração da SQL.
class QueryBuilder implements Future<dynamic> {
  final DatabaseDriver _driver;
  String _tableName = '';
  List<String> _columns = ['*'];
  final List<String> _whereClauses = [];
  final List<String> _orderByClauses = [];
  final List<String> _joinClauses = [];
  final List<String> _unionQueries = [];
  int? _limit;
  int? _offset;
  Map<String, dynamic> _insertData = {};
  Map<String, dynamic> _updateData = {};
  String? _queryType;
  final List<dynamic> _parameters = [];
  String? _createTableSQL;
  final List<String> _alterTableCommands = [];
  final Map<String, TableSchema> _schemas;
  final List<String> _groupByClauses = [];
  final List<String> _havingClauses = [];
  final CommonTableExpression? _cte;

  String? _returningClause;

  QueryBuilder(this._driver, this._schemas, this._cte);

  String _escapeIdentifier(String identifier) {
    if (identifier.toLowerCase().contains('count')) {
      return identifier;
    }
    if (identifier.contains('.')) {
      return identifier.split('.').map((part) => '"$part"').join('.');
    }
    return '"$identifier"';
  }

  QueryBuilder select([Map<String, String>? columns]) {
    _queryType = 'SELECT';
    if (columns == null) {
      _columns = ['*'];
    } else {
      _columns = columns.entries
          .map((e) =>
              "${_escapeIdentifier(e.value)} AS ${_escapeIdentifier(e.key)}")
          .toList();
    }
    return this;
  }

  QueryBuilder from(String table) {
    _tableName = table;
    return this;
  }

  QueryBuilder groupBy(List<String> columns) {
    _groupByClauses.addAll(columns.map(_escapeIdentifier));
    return this;
  }

  QueryBuilder having(dynamic columnOrCondition,
      [String? operator, dynamic value]) {
    if (columnOrCondition is Condition) {
      _havingClauses.add(columnOrCondition.clause);
      _parameters.addAll(columnOrCondition.values);
    } else {
      _havingClauses.add("$columnOrCondition $operator ?");
      _parameters.add(value);
    }
    return this;
  }

  QueryBuilder where(dynamic columnOrCondition,
      [String? operator, dynamic value]) {
    if (columnOrCondition is Condition) {
      _whereClauses.add(columnOrCondition.clause);
      _parameters.addAll(columnOrCondition.values);
    } else {
      _whereClauses.add("$columnOrCondition $operator ?");
      _parameters.add(value);
    }
    return this;
  }

  QueryBuilder orderBy(String column, [String direction = 'ASC']) {
    _orderByClauses.add("${_escapeIdentifier(column)} $direction");
    return this;
  }

  QueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  QueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  QueryBuilder innerJoin(String table, Condition condition) {
    _joinClauses
        .add("INNER JOIN ${_escapeIdentifier(table)} ON ${condition.clause}");
    _parameters.addAll(condition.values);
    return this;
  }

  QueryBuilder leftJoin(String table, Condition condition) {
    _joinClauses
        .add("LEFT JOIN ${_escapeIdentifier(table)} ON ${condition.clause}");
    _parameters.addAll(condition.values);
    return this;
  }

  QueryBuilder rightJoin(String table, Condition condition) {
    _joinClauses
        .add("RIGHT JOIN ${_escapeIdentifier(table)} ON ${condition.clause}");
    _parameters.addAll(condition.values);
    return this;
  }

  QueryBuilder fullJoin(String table, Condition condition) {
    _joinClauses
        .add("FULL JOIN ${_escapeIdentifier(table)} ON ${condition.clause}");
    _parameters.addAll(condition.values);
    return this;
  }

  QueryBuilder union(QueryBuilder otherQuery) {
    _unionQueries.add(otherQuery.toSql());
    return this;
  }

  QueryBuilder function(String function, String column, String alias) {
    _columns = [
      "$function(${_escapeIdentifier(column)}) AS ${_escapeIdentifier(alias)}"
    ];
    return this;
  }

  QueryBuilder count([Condition? condition]) {
    _columns = ["COUNT(*)"];
    if (condition != null) {
      _whereClauses.add(condition.clause);
      _parameters.addAll(condition.values);
    }
    return this;
  }

  QueryBuilder insert(String table) {
    _tableName = table;
    _queryType = 'INSERT';
    return this;
  }

  // QueryBuilder values(Map<String, dynamic> data) {
  //   _parameters.clear();
  //   final tableSchema = _schemas[_tableName];
  //   _insertData = {};
  //   data.forEach((key, value) {
  //     if (tableSchema != null && tableSchema.columns.containsKey(key)) {
  //       final colType = tableSchema.columns[key]!;
  //       _insertData[key] = convertValueForInsert(value, colType);
  //     } else {
  //       _insertData[key] = value;
  //     }
  //   });
  //   _parameters.addAll(_insertData.values);
  //   return this;
  // }
  QueryBuilder values(Map<String, dynamic> data) {
    _parameters.clear();
    final tableSchema = _schemas[_tableName];
    _insertData = {};

    // First, process auto-generated UUIDs for primary keys
    if (tableSchema != null) {
      tableSchema.columns.forEach((key, column) {
        if (column.baseType == 'UUID' &&
            column.modifiers.contains('PRIMARY KEY AUTOGENERATE') &&
            !data.containsKey(key)) {
          data[key] = Uuid().v4();
        }
      });
    }

    // Then process all data including the auto-generated values
    data.forEach((key, value) {
      if (tableSchema != null && tableSchema.columns.containsKey(key)) {
        final colType = tableSchema.columns[key]!;
        _insertData[key] = convertValueForInsert(value, colType);
      } else {
        _insertData[key] = value;
      }
    });

    _parameters.addAll(_insertData.values);
    return this;
  }

  QueryBuilder update(String table) {
    _tableName = table;
    _queryType = 'UPDATE';
    return this;
  }

  QueryBuilder set(Map<String, dynamic> data) {
    final tableSchema = _schemas[_tableName];
    _updateData = {};
    data.forEach((key, value) {
      if (tableSchema != null && tableSchema.columns.containsKey(key)) {
        final colType = tableSchema.columns[key]!;
        _updateData[key] = convertValueForInsert(value, colType);
      } else {
        _updateData[key] = value;
      }
    });
    _parameters.addAll(_updateData.values);
    return this;
  }

  QueryBuilder delete(String table) {
    _tableName = table;
    _queryType = 'DELETE';
    return this;
  }

  QueryBuilder returning([List<String>? columns]) {
    if (columns == null || columns.isEmpty) {
      _returningClause = "RETURNING *";
    } else {
      if (columns.length == 1 && columns.first == '*') {
        _returningClause = "RETURNING *";
        return this;
      }
      final escapedColumns =
          columns.map((col) => _escapeIdentifier(col)).join(', ');
      _returningClause = "RETURNING $escapedColumns";
    }
    return this;
  }

  QueryBuilder returningId() {
    _returningClause = "RETURNING id";
    return this;
  }

  QueryBuilder createTable(String table, Map<String, String> columns) {
    _queryType = 'CREATE_TABLE';
    _createTableSQL =
        "CREATE TABLE IF NOT EXISTS ${_escapeIdentifier(table)} (${columns.entries.map((e) => "${e.key} ${e.value}").join(', ')})";
    return this;
  }

  QueryBuilder dropTable(String table) {
    _queryType = 'DROP_TABLE';
    _tableName = table;
    return this;
  }

  QueryBuilder addColumn(String columnName, String columnType) {
    _alterTableCommands
        .add("ADD COLUMN ${_escapeIdentifier(columnName)} $columnType");
    return this;
  }

  QueryBuilder dropColumn(String columnName) {
    _alterTableCommands.add("DROP COLUMN ${_escapeIdentifier(columnName)}");
    return this;
  }

  String toSql() {
    final tableEscaped = _escapeIdentifier(_tableName);
    String sql = '';

    if (_cte != null) {
      final cteSql = _cte!.query.toSql().trim().replaceAll(';', '');
      sql += 'WITH "${_cte!.name}" AS ($cteSql) ';
    }

    if (_queryType == 'SELECT') {
      sql += "SELECT ${_columns.join(', ')} FROM $tableEscaped";

      if (_joinClauses.isNotEmpty) {
        sql += " ${_joinClauses.join(" ")}";
      }
      if (_whereClauses.isNotEmpty) {
        sql += " WHERE ${_whereClauses.join(" AND ")}";
      }
      if (_groupByClauses.isNotEmpty) {
        sql += " GROUP BY ${_groupByClauses.join(", ")}";
      }
      if (_havingClauses.isNotEmpty) {
        sql += " HAVING ${_havingClauses.join(" AND ")}";
      }
      if (_orderByClauses.isNotEmpty) {
        sql += " ORDER BY ${_orderByClauses.join(", ")}";
      }
      if (_limit != null) {
        sql += " LIMIT $_limit";
      }
      if (_offset != null) {
        sql += " OFFSET $_offset";
      }
      if (_unionQueries.isNotEmpty) {
        sql += " UNION ${_unionQueries.join(" UNION ")}";
      }
      return "$sql;";
    }
    if (_queryType == 'INSERT') {
      final columns =
          _insertData.keys.map((col) => _escapeIdentifier(col)).join(', ');
      final placeholders = List.filled(_insertData.length, '?').join(', ');
      String sql =
          "INSERT INTO $tableEscaped ($columns) VALUES ($placeholders)";
      if (_returningClause != null) {
        sql += " $_returningClause";
      }
      return sql;
    }
    if (_queryType == 'UPDATE') {
      final setClause = _updateData.keys
          .map((key) => "${_escapeIdentifier(key)} = ?")
          .join(", ");
      String sql = "UPDATE $tableEscaped SET $setClause";
      if (_whereClauses.isNotEmpty) {
        sql += " WHERE ${_whereClauses.join(" AND ")}";
      }
      if (_returningClause != null) {
        sql += " $_returningClause";
      }
      return "$sql;";
    }
    if (_queryType == 'DELETE') {
      String sql = "DELETE FROM $tableEscaped";
      if (_whereClauses.isNotEmpty) {
        sql += " WHERE ${_whereClauses.join(" AND ")}";
      }
      if (_returningClause != null) {
        sql += " $_returningClause";
      }
      return "$sql;";
    }
    if (_queryType == 'CREATE_TABLE') {
      return "${_createTableSQL!};";
    }
    if (_queryType == 'DROP_TABLE') {
      return "DROP TABLE IF EXISTS $tableEscaped;";
    }
    if (_alterTableCommands.isNotEmpty) {
      return "ALTER TABLE $tableEscaped ${_alterTableCommands.join(", ")};";
    }
    throw Exception('No operation was defined');
  }

  List<dynamic> getParameters() => _parameters;

  Future<dynamic> _internalExecute() async {
    final sql = toSql();
    final params = getParameters();
    dynamic result;
    if (_queryType == 'SELECT' || _returningClause != null) {
      result = await _driver.execute(sql, params);
      if (_queryType == 'SELECT' &&
          _columns.length == 1 &&
          _columns[0].toLowerCase().startsWith("count(") &&
          result is List &&
          result.isNotEmpty &&
          result[0] is Map) {
        final row = result[0] as Map;
        if (row.length == 1) {
          result = row.values.first;
        }
      } else if (result is List) {
        result = result.map((row) {
          if (row is Map<String, dynamic>) {
            row.forEach((key, value) {
              final colType = _schemas[_tableName]?.columns[key];
              if (colType != null) {
                row[key] = convertValueForSelect(value, colType);
              }
            });
          }
          return row;
        }).toList();
      }
    } else {
      await _driver.raw(sql, params);
      result = null;
    }
    _reset();
    return result;
  }

  void _reset() {
    _tableName = '';
    _columns = ['*'];
    _whereClauses.clear();
    _orderByClauses.clear();
    _joinClauses.clear();
    _unionQueries.clear();
    _limit = null;
    _offset = null;
    _insertData.clear();
    _updateData.clear();
    _queryType = null;
    _parameters.clear();
    _createTableSQL = null;
    _alterTableCommands.clear();
    _returningClause = null;
    _groupByClauses.clear();
    _havingClauses.clear();
  }

  @override
  Future<S> then<S>(FutureOr<S> Function(dynamic value) onValue,
      {Function? onError}) {
    return _internalExecute().then<S>(onValue, onError: onError);
  }

  @override
  Future<dynamic> catchError(Function onError,
      {bool Function(Object error)? test}) {
    return _internalExecute().catchError(onError, test: test);
  }

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) {
    return _internalExecute().whenComplete(action);
  }

  @override
  Stream<dynamic> asStream() => Stream.fromFuture(_internalExecute());

  @override
  Future<dynamic> timeout(Duration timeLimit,
      {FutureOr<dynamic> Function()? onTimeout}) {
    return _internalExecute().timeout(timeLimit, onTimeout: onTimeout);
  }
}
