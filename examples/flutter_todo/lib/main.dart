// `Column` and `Table` are also Flutter widget names, so hide the dartonic
// schema classes from this Flutter file. The schema declaration lives in
// schema.dart, which is a pure-Dart file with no Flutter imports.
import 'package:dartonic_core/dartonic_core.dart' hide Column, Table;
import 'package:flutter/material.dart';

import 'database.dart';
import 'schema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();
  runApp(TodoApp(db: db));
}

class TodoApp extends StatelessWidget {
  final DartonicDb db;
  const TodoApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dartonic TODO',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: TodoListScreen(db: db),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  final DartonicDb db;
  const TodoListScreen({super.key, required this.db});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _titleController = TextEditingController();
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await widget.db
        .select()
        .from(todos)
        .orderBy(todos.createdAt, Order.desc)
        .rows(Todo.fromRow);
    setState(() => _todos = list);
  }

  Future<void> _add() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    await widget.db.insert(todos).values([
      todos.title.value(title),
      todos.completed.value(false),
    ]);
    _titleController.clear();
    await _reload();
  }

  Future<void> _toggle(Todo todo) async {
    await widget.db
        .update(todos)
        .set([todos.completed.value(!todo.completed)])
        .where(eq(todos.id, todo.id));
    await _reload();
  }

  Future<void> _delete(Todo todo) async {
    await widget.db.delete(todos).where(eq(todos.id, todo.id));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dartonic TODO')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'New task…'),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _add, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _todos.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = _todos[i];
                return CheckboxListTile(
                  value: t.completed,
                  title: Text(
                    t.title,
                    style: t.completed
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough)
                        : null,
                  ),
                  subtitle: Text(t.createdAt.toLocal().toString()),
                  onChanged: (_) => _toggle(t),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(t),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
