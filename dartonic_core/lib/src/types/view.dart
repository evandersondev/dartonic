import '../query_builder/query_builder.dart';

typedef ViewQueryCallback = QueryBuilder Function(QueryBuilder qb);

class ViewSchema {
  final String name;
  final ViewQueryCallback queryCallback;

  const ViewSchema(this.name, this.queryCallback);

  ViewSchema withQuery(ViewQueryCallback cb) => ViewSchema(name, cb);
}

ViewSchema pgView(String name) => ViewSchema(name, (qb) => qb);
ViewSchema sqliteView(String name) => ViewSchema(name, (qb) => qb);
ViewSchema mysqlView(String name) => ViewSchema(name, (qb) => qb);

extension ViewSchemaExtension on ViewSchema {
  ViewSchema as(ViewQueryCallback cb) => withQuery(cb);
}
