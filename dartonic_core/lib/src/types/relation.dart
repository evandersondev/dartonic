import 'column.dart';
import 'table.dart';

enum RelationType { one, many }

class RelationDefinition {
  final String target;
  final List<String>? fields;
  final List<String>? references;
  final RelationType type;

  const RelationDefinition(
    this.target, {
    this.fields,
    this.references,
    required this.type,
  });
}

class RelationBuilder {
  RelationDefinition one(String target,
          {List<String>? fields, List<String>? references}) =>
      RelationDefinition(target,
          fields: fields, references: references, type: RelationType.one);

  RelationDefinition many(String target,
          {List<String>? fields, List<String>? references}) =>
      RelationDefinition(target,
          fields: fields, references: references, type: RelationType.many);
}

typedef RelationCallback = Map<String, RelationDefinition> Function(
    RelationBuilder builder);

/// Wraps a [Table] with declarative relations to other tables. The columns
/// are inherited from the [baseTable] — relations don't introduce new
/// columns of their own.
class RelationsTable extends Table {
  final Table baseTable;
  final Map<String, RelationDefinition> relations;

  RelationsTable(this.baseTable, this.relations);

  @override
  String get tableName => baseTable.tableName;

  @override
  List<Column<Object?>> get columns => baseTable.columns;

  @override
  Column<Object?>? columnByName(String name) => baseTable.columnByName(name);
}

RelationsTable relations(Object tableOrName, RelationCallback callback) {
  Table base;
  if (tableOrName is String) {
    base = rawTable(tableOrName);
  } else if (tableOrName is Table) {
    base = tableOrName;
  } else {
    throw ArgumentError('tableOrName must be a String or a Table.');
  }
  return RelationsTable(base, callback(RelationBuilder()));
}
