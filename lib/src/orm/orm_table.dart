import '../query_builder/builder.dart';

class OrmTable {
  final String tableName;
  final DatabaseFacade database;

  OrmTable(this.tableName, this.database);

  Future<List<Map<String, dynamic>>> findMany({
    Map<String, bool>? $with,
    Map<String, bool>? includes,
    Condition? where,
    int? offset,
    int? limit,
    List<String?>? orderBy,
  }) async {
    dynamic selectAttributes;

    if ($with != null) {
      selectAttributes = {
        for (var attribute in $with.entries)
          if (attribute.value == true)
            attribute.key: '$tableName.${attribute.key}'
      };
    }

    final query = database.select(selectAttributes).from(tableName);

    if (includes != null) {
      for (var include in includes.entries) {
        query.innerJoin(tableName, eq(include.key, 'includes.id'));
      }
    }

    if (where != null) {
      query.where(where);
    }

    if (orderBy != null) {
      if (orderBy.isEmpty || orderBy.length > 2) {
        throw ArgumentError(
          'Invalid order format, must be [column, direction]',
        );
      } else {
        if (orderBy.length == 1) {
          query.orderBy('$tableName.${orderBy[0]!}', 'asc');
        } else {
          query.orderBy('$tableName.${orderBy[0]!}', orderBy[1]!);
        }
      }
    }

    if (offset != null) query.offset(offset);
    if (limit != null) query.limit(limit);

    final results = await query;

    return _convertToMapList(results);
  }

  Future<Map<String, dynamic>?> findFirst() async {
    final results = await database.select().from(tableName).limit(1);

    return results.isNotEmpty ? _convertToMapList(results).first : null;
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
