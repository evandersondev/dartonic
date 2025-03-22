import 'table.dart';

/// Define o tipo de relacionamento: "one" ou "many".
enum RelationType { one, many }

/// Classe que descreve uma definição de relacionamento.
class RelationDefinition {
  final String target; // Nome da tabela alvo
  final List<String>? fields; // Campos da tabela origem.
  final List<String>? references; // Campos de referência na tabela destino.
  final RelationType type;

  RelationDefinition(this.target,
      {this.fields, this.references, required this.type});
}

/// Construtor para facilitar a criação de relacionamentos.
class RelationBuilder {
  RelationDefinition one(String target,
      {List<String>? fields, List<String>? references}) {
    return RelationDefinition(target,
        fields: fields, references: references, type: RelationType.one);
  }

  RelationDefinition many(String target,
      {List<String>? fields, List<String>? references}) {
    return RelationDefinition(target,
        fields: fields, references: references, type: RelationType.many);
  }
}

/// Tipo de callback para configurar os relacionamentos.
typedef RelationCallback = Map<String, RelationDefinition> Function(
    RelationBuilder builder);

/// Representa uma tabela de relacionamentos.
/// Este objeto herda de [Table] mas indica que é apenas meta-informação para relacionamentos,
/// e não deve ser criada no banco de dados.
class RelationsTable extends Table {
  final Table baseTable;
  final Map<String, RelationDefinition> relations;

  RelationsTable(this.baseTable, this.relations)
      : super(baseTable.name, baseTable.columns);
}

/// Função para definir relacionamentos para uma tabela.
/// Se [tableOrName] for uma [Table], será utilizado; caso seja uma [String],
/// uma tabela base vazia será criada (os campos podem ser ignorados).
RelationsTable relations(dynamic tableOrName, RelationCallback callback) {
  Table base;
  if (tableOrName is String) {
    // Cria uma tabela base com colunas vazias se apenas o nome for fornecido.
    base = sqliteTable(tableOrName, {});
  } else if (tableOrName is Table) {
    base = tableOrName;
  } else {
    throw ArgumentError('tableOrName deve ser uma String ou uma Table.');
  }
  final builder = RelationBuilder();
  final rels = callback(builder);
  return RelationsTable(base, rels);
}
