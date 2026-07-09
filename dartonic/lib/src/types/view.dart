import '../query_builder/query_builder.dart';

typedef QueryBuilderCallback = QueryBuilder Function(QueryBuilder qb);

class ViewSchema {
  final String name;
  final QueryBuilderCallback queryCallback;

  ViewSchema(this.name, this.queryCallback);
}

ViewSchema pgView(String name) => ViewSchema(name, (qb) => qb);
ViewSchema sqliteView(String name) => ViewSchema(name, (qb) => qb);
ViewSchema mysqlView(String name) => ViewSchema(name, (qb) => qb);

extension ViewSchemaExtension on ViewSchema {
  ViewSchema as(QueryBuilderCallback queryCallback) {
    return ViewSchema(name, queryCallback);
  }
}
