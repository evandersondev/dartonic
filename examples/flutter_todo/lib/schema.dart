import 'package:dartonic_core/dartonic_core.dart';

/// `todos` — one row per todo item.
class TodosTable extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final title = text('title').notNull();
  final completed = boolean('completed').notNull().withDefault(0);
  final createdAt = datetime('created_at').defaultNow();

  @override
  String get tableName => 'todos';
}

final todos = TodosTable();

class Todo {
  final int id;
  final String title;
  final bool completed;
  final DateTime createdAt;

  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
  });

  factory Todo.fromRow(RowMap row) => Todo(
        id: row.readNotNull(todos.id),
        title: row.readNotNull(todos.title),
        completed: row.readNotNull(todos.completed),
        createdAt: row.readNotNull(todos.createdAt),
      );
}
