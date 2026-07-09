import '../query_builder/builder.dart';

class CommonTableExpression {
  final String name;
  final QueryBuilder query;

  CommonTableExpression(this.name, this.query);
}

class CteBuilder {
  final String name;
  CteBuilder(this.name);

  CommonTableExpression as(QueryBuilder query) {
    return CommonTableExpression(name, query);
  }
}
