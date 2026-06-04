import 'package:darto/darto.dart';
import 'package:manual_test/modules/database/db.dart';

Future<Darto> createApp() async {
  final db = await openDatebase();
  final app = Darto(logger: true);

  app.get("/", (Request req, Response res) async {
    final rows = await db.select().from(users);
    final json = rows
        .map((r) => {
              'id': r.read(users.id),
              'name': r.read(users.name),
            })
        .toList();
    return res.json(json);
  });

  return app;
}
