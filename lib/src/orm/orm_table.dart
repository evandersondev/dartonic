import 'package:dartonic/src/query_builder/condition.dart';

import '../query_builder/database_facade.dart';

class OrmTable {
  final String tableName;
  final DatabaseFacade database;

  OrmTable(this.tableName, this.database);

  Future<List<Map<String, dynamic>>> findAll({
    List<String>? attributes,
    Map<String, dynamic>? where,
    int? offset,
    int? limit,
    List<List<String>>? order,
  }) async {
    dynamic selectAttributes;

    if (attributes != null) {
      selectAttributes = {
        for (var attribute in attributes) attribute: attribute,
      };
    }

    final query = database.select(selectAttributes).from(tableName);

    if (where != null) {
      where.forEach((column, value) {
        if (value is List && value.length == 2) {
          query.where(column, value[0].toString(), value[1]);
        } else {
          query.where(column, '=', value);
        }
      });
    }

    if (order != null) {
      for (var column in order) {
        if (column.length == 2) {
          query.orderBy(column[0], column[1]);
        } else {
          throw ArgumentError(
            'Invalid order format, must be [column, direction]',
          );
        }
      }
    }

    if (offset != null) query.offset(offset);
    if (limit != null) query.limit(limit);

    final results = await query;

    return _convertToMapList(results);
  }

  Future<Map<String, dynamic>?> findById(dynamic id) async {
    final results = await database.select().from(tableName).where({'id': id});

    return results.isNotEmpty ? _convertToMapList(results).first : null;
  }

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

  Future<void> deleteById(dynamic id) async {
    return await database.delete(tableName).where(eq('$tableName.id', id));
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> values) async {
    final results = await database.insert(tableName).values(values).returning();
    return _convertToMapList(results).first;
  }

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
