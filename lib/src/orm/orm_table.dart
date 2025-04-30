import 'package:dartonic/src/query_builder/condition.dart';

import '../query_builder/database_facade.dart';

class OrmTable {
  final String tableName;
  final DatabaseFacade database;

  OrmTable(this.tableName, this.database);

  // Método para buscar todos os registros
  Future<List<Map<String, dynamic>>> findAll() async {
    final results = await database.select().from(tableName);

    return _convertToMapList(results);
  }

  // Método para buscar um registro por ID
  Future<Map<String, dynamic>?> findById(dynamic id) async {
    final results = await database.select().from(tableName).where({'id': id});

    return results.isNotEmpty ? _convertToMapList(results).first : null;
  }

  // FindOne
  Future<Map<String, dynamic>?> findOne(
    dynamic columnOrCondition, [
    String? operator,
    dynamic value,
  ]) async {
    final results = await database
        .select()
        .from(tableName)
        .where(columnOrCondition, operator, value);
    return results.isNotEmpty ? _convertToMapList(results).first : null;
  }

  // Método para deletar um registro por ID
  Future<void> deleteById(dynamic id) async {
    return await database.delete(tableName).where(eq('$tableName.id', id));
  }

  // Método para criar um registro
  Future<Map<String, dynamic>> create(Map<String, dynamic> values) async {
    final results = await database.insert(tableName).values(values).returning();
    return _convertToMapList(results).first;
  }

  // Método para atualizar um registro por ID
  Future<Map<String, dynamic>> updateById(
      dynamic id, Map<String, dynamic> values) async {
    final results = await database
        .update(tableName)
        .set(values)
        .where(eq('$tableName.id', id))
        .returning();

    return _convertToMapList(results).first;
  }

  List<Map<String, dynamic>> _convertToMapList(List<dynamic> results) {
    return results.map<Map<String, dynamic>>((item) {
      if (item is Map<String, dynamic>) {
        return item;
      } else {
        return Map<String, dynamic>.from(item as Map);
      }
    }).toList();
  }
}
