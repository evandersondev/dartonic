import 'dart:async';

import '../drivers/driver.dart';
import 'condition.dart';

class QueryBuilder implements Future<dynamic> {
  final DatabaseDriver _driver;
  String _table = '';
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

  // novo campo para armazenar a cláusula RETURNING
  String? _returningClause;

  QueryBuilder(this._driver);

  /// Método select atualizado para aceitar um Map ou List de colunas.
  /// Se passado um Map, a chave representa o alias e o valor a coluna a ser selecionada.
  QueryBuilder select([Map<String, String>? columns]) {
    _queryType = 'SELECT';
    if (columns == null) {
      _columns = ['*'];
    } else
      _columns = columns.entries.map((e) => "${e.value} AS ${e.key}").toList();

    return this;
  }

  QueryBuilder from(String table) {
    _table = table;
    return this;
  }

  // Aceita Condition ou (coluna, operador, valor) para WHERE
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
    _orderByClauses.add("$column $direction");
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

  // JOINs
  QueryBuilder innerJoin(String table, Condition condition) {
    _joinClauses.add("INNER JOIN $table ON ${condition.clause}");
    _parameters.addAll(condition.values);
    return this;
  }

  QueryBuilder leftJoin(String table, Condition condition) {
    _joinClauses.add("LEFT JOIN $table ON ${condition.clause}");
    _parameters.addAll(condition.values);
    return this;
  }

  QueryBuilder rightJoin(String table, Condition condition) {
    _joinClauses.add("RIGHT JOIN $table ON ${condition.clause}");
    _parameters.addAll(condition.values);
    return this;
  }

  QueryBuilder fullJoin(String table, Condition condition) {
    _joinClauses.add("FULL JOIN $table ON ${condition.clause}");
    _parameters.addAll(condition.values);
    return this;
  }

  QueryBuilder union(QueryBuilder otherQuery) {
    _unionQueries.add(otherQuery.toSql());
    return this;
  }

  QueryBuilder function(String function, String column, String alias) {
    _columns = ["$function($column) AS $alias"];
    return this;
  }

  QueryBuilder count() {
    _columns = ["COUNT(*) AS total"];
    return this;
  }

  // Métodos para INSERT
  QueryBuilder insert(String table) {
    _table = table;
    _queryType = 'INSERT';
    return this;
  }

  QueryBuilder values(Map<String, dynamic> data) {
    _insertData = Map<String, dynamic>.from(data);
    _parameters.addAll(_insertData.values);
    return this;
  }

  // Métodos para UPDATE
  QueryBuilder update(String table) {
    _table = table;
    _queryType = 'UPDATE';
    return this;
  }

  QueryBuilder set(Map<String, dynamic> data) {
    _updateData = Map<String, dynamic>.from(data);
    _parameters.addAll(_updateData.values);
    return this;
  }

  // Métodos para DELETE
  QueryBuilder delete(String table) {
    _table = table;
    _queryType = 'DELETE';
    return this;
  }

  // Método returning para inserir cláusula RETURNING em INSERT, UPDATE ou DELETE.
  QueryBuilder returning(
      {String? insertedId, String? updatedId, String? deletedId}) {
    if (insertedId != null) {
      _returningClause = "RETURNING $insertedId";
    } else if (updatedId != null) {
      _returningClause = "RETURNING $updatedId";
    } else if (deletedId != null) {
      _returningClause = "RETURNING $deletedId";
    } else {
      _returningClause = "RETURNING *";
    }
    return this;
  }

  // Métodos para criação e alteração de tabelas
  QueryBuilder createTable(String table, Map<String, String> columns) {
    _queryType = 'CREATE_TABLE';
    _createTableSQL =
        "CREATE TABLE IF NOT EXISTS $table (${columns.entries.map((e) => "${e.key} ${e.value}").join(', ')})";
    return this;
  }

  QueryBuilder dropTable(String table) {
    _queryType = 'DROP_TABLE';
    _table = table;
    return this;
  }

  QueryBuilder addColumn(String columnName, String columnType) {
    _alterTableCommands.add("ADD COLUMN $columnName $columnType");
    return this;
  }

  QueryBuilder dropColumn(String columnName) {
    _alterTableCommands.add("DROP COLUMN $columnName");
    return this;
  }

  /// Retorna a string SQL sem executar.
  String toSql() {
    if (_queryType == 'SELECT') return _buildSelect();
    if (_queryType == 'INSERT') return _buildInsert();
    if (_queryType == 'UPDATE') return _buildUpdate();
    if (_queryType == 'DELETE') return _buildDelete();
    if (_queryType == 'CREATE_TABLE') return "${_createTableSQL!};";
    if (_queryType == 'DROP_TABLE') return "DROP TABLE IF EXISTS $_table;";
    if (_alterTableCommands.isNotEmpty)
      return "ALTER TABLE $_table ${_alterTableCommands.join(", ")};";
    throw Exception('Nenhuma operação definida!');
  }

  List<dynamic> getParameters() => _parameters;

  String _buildSelect() {
    String sql = "SELECT ${_columns.join(', ')} FROM $_table";
    if (_joinClauses.isNotEmpty) sql += " ${_joinClauses.join(" ")}";
    if (_whereClauses.isNotEmpty)
      sql += " WHERE ${_whereClauses.join(" AND ")}";
    if (_orderByClauses.isNotEmpty)
      sql += " ORDER BY ${_orderByClauses.join(", ")}";
    if (_limit != null) sql += " LIMIT $_limit";
    if (_offset != null) sql += " OFFSET $_offset";
    if (_unionQueries.isNotEmpty)
      sql += " UNION ${_unionQueries.join(" UNION ")}";
    return "$sql;";
  }

  String _buildInsert() {
    final columns = _insertData.keys.join(', ');
    final placeholders = List.filled(_insertData.length, '?').join(', ');
    String sql = "INSERT INTO $_table ($columns) VALUES ($placeholders)";
    if (_returningClause != null) {
      sql += " $_returningClause";
    }
    return "$sql;";
  }

  String _buildUpdate() {
    final setClause = _updateData.keys.map((key) => "$key = ?").join(", ");
    String sql = "UPDATE $_table SET $setClause";
    if (_whereClauses.isNotEmpty)
      sql += " WHERE ${_whereClauses.join(" AND ")}";
    if (_returningClause != null) {
      sql += " $_returningClause";
    }
    return "$sql;";
  }

  String _buildDelete() {
    String sql = "DELETE FROM $_table";
    if (_whereClauses.isNotEmpty)
      sql += " WHERE ${_whereClauses.join(" AND ")}";
    if (_returningClause != null) {
      sql += " $_returningClause";
    }
    return "$sql;";
  }

  ///
  /// Executa a query utilizando o driver.
  /// Se houver uma cláusula RETURNING ou se for SELECT, usa execute() para retornar resultados.
  Future<dynamic> _internalExecute() async {
    final sql = toSql();
    final params = getParameters();
    if (_queryType == 'SELECT' || _returningClause != null) {
      return await _driver.execute(sql, params);
    } else {
      await _driver.raw(sql, params);
      return null;
    }
  }

  // Métodos da interface Future

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
