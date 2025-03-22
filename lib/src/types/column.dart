class ColumnType {
  final String? columnName;
  final String baseType;
  final List<String> modifiers = [];

  // Aceita um parâmetro opcional columnName.
  ColumnType(this.baseType, [this.columnName]);

  ColumnType notNull() {
    modifiers.add("NOT NULL");
    return this;
  }

  ColumnType unique() {
    modifiers.add("UNIQUE");
    return this;
  }

  ColumnType primaryKey({bool autoIncrement = true}) {
    if (autoIncrement) {
      modifiers.add("PRIMARY KEY AUTOINCREMENT");
    } else {
      modifiers.add("PRIMARY KEY");
    }
    return this;
  }

  // Atualizado para transformar "users.id" em "users(id)" para SQLite.
  ColumnType references(String Function() ref) {
    String rawRef = ref();
    // Se a referência estiver no formato "table.column", converte para "table(column)"
    if (rawRef.contains('.')) {
      final parts = rawRef.split('.');
      if (parts.length == 2) {
        rawRef = "${parts[0]}(${parts[1]})";
      }
    }
    modifiers.add("REFERENCES $rawRef");
    return this;
  }

  /// Define um valor default para a coluna utilizando um valor ou expressão SQL.
  ColumnType defaultVal(String value) {
    modifiers.add("DEFAULT $value");
    return this;
  }

  /// Define o valor default como a data/hora atual.
  ColumnType defaultNow() {
    modifiers.add("DEFAULT CURRENT_TIMESTAMP");
    return this;
  }

  @override
  String toString() {
    // Retorna a definição completa da coluna, sem o nome, pois o nome é definido pela chave do mapa
    return "$baseType ${modifiers.join(' ')}".trim();
  }
}

/// Funções para tipos de colunas com sintaxe inspirada no Drizzle.
/// Agora as funções utilizam parâmetros nomeados para permitir fornecer o nome da coluna.
ColumnType serial({String? columnName}) => ColumnType("SERIAL", columnName);
ColumnType varchar({String? columnName, int length = 255}) =>
    ColumnType("VARCHAR($length)", columnName);
ColumnType integer({String? columnName}) => ColumnType("INTEGER", columnName);
ColumnType text({String? columnName}) => ColumnType("TEXT", columnName);
ColumnType uuid({String? columnName}) => ColumnType("UUID", columnName);

/// Cria uma coluna do tipo timestamp, permitindo salvar a data de acordo com o modo.
/// Por padrão, o mode é 'date', que utiliza o formato DATETIME.
/// Se o mode for 'string', utiliza TEXT. Se for 'number', utiliza NUMERIC.
ColumnType timestamp({String? columnName, String mode = 'date'}) {
  String base;
  switch (mode) {
    case 'string':
      base = 'TEXT';
      break;
    case 'number':
      base = 'NUMERIC';
      break;
    case 'date':
    default:
      base = 'DATETIME';
      break;
  }
  return ColumnType(base, columnName);
}

/// Função helper para injetar expressões SQL brutas.
/// Pode ser utilizada, por exemplo, para definir um valor default via SQL.
String sql(String value) => value;
