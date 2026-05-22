import 'package:book_api_crud/database/db.dart';
import 'package:book_api_crud/database/schemas.dart';
import 'package:darto/darto.dart';

void main() async {
  await initDatabase(); // opens the shared connection once

  final app = Darto(logger: true);

  app.get("/", (Request req, Response res) async {
    final rows = await db.select().from(books);
    return res.json(rows.map((r) => r.raw).toList());
  });

  app.post('/', (Request req, Response res) async {
    await db.insert(books).values([
      books.title.value('Harry Potter'),
      books.author.value('J.K. Rowling'),
      books.isbn.value('1234567890'),
    ]);

    return res.status(201).end();
  });

  app.listen(3000);
}
