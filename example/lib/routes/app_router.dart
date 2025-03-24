// import 'dart:convert';

// import 'package:darto/darto.dart';
// import 'package:example/config/database.dart';

// Router appRouter() {
//   final router = Router();
//   final db = dartonic.I;

//   router.post('/users', (Request req, Response res) async {
//     final body = jsonDecode(await req.body);

//     final userCreated = await db.insert('users').values(body).returning();
//     print(userCreated);

//     res.status(CREATED).json(userCreated);
//   });

//   router.get('/users', (Request req, Response res) async {
//     final users = await db
//         .select({'name': 'users.fullname', 'age': 'users.birthday'})
//         .from('users');

//     res.json(users);
//   });

//   // router.put('/tasks/:id', (Request req, Response res) async {
//   //   final id = req.params['id'];

//   //   final taskExists = await Task.findByPk(id);
//   //   if (taskExists == null) {
//   //     res.status(NOT_FOUND).end();
//   //     return;
//   //   }

//   //   final taskSchema = z.map({
//   //     'title': z.string().min(3).max(100).optional(),
//   //     'description': z.string().min(3).optional(),
//   //   });

//   //   final task = taskSchema.parse(jsonDecode(await req.body));

//   //   await Task.update(task, where: {'id': id});

//   //   res.status(OK).end();
//   // });

//   return router;
// }
