import 'dart:convert';

import 'package:darto/darto.dart';
import 'package:example/config/database.dart';

Router todoRouter() {
  final router = Router();
  final db = dartonic.I;

  router.post('/todos', (Request req, Response res) async {
    final body = jsonDecode(await req.body);

    final todoCreated = await db.insert('todos').values(body).returning();
    print(todoCreated);

    res.status(CREATED).json(todoCreated);
  });

  router.get('/todos', (Request req, Response res) async {
    final todos = await db.select().from('todos');

    res.json(todos);
  });

  // router.put('/tasks/:id', (Request req, Response res) async {
  //   final id = req.params['id'];

  //   final taskExists = await Task.findByPk(id);
  //   if (taskExists == null) {
  //     res.status(NOT_FOUND).end();
  //     return;
  //   }

  //   final taskSchema = z.map({
  //     'title': z.string().min(3).max(100).optional(),
  //     'description': z.string().min(3).optional(),
  //   });

  //   final task = taskSchema.parse(jsonDecode(await req.body));

  //   await Task.update(task, where: {'id': id});

  //   res.status(OK).end();
  // });

  return router;
}
