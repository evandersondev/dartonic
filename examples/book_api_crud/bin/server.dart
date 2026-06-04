import 'package:book_api_crud/database/db.dart';
import 'package:book_api_crud/database/schemas.dart';
import 'package:darto/darto.dart';
import 'package:darto/logger.dart';

void main() async {
  await initDatabase();

  final app = Darto();
  app.use(logger());

  app.get("/", [], (c) async {
    final rows = await db.select().from(books);
    return c.json(rows.map((r) => r.raw).toList());
  });

  app.post('/', [], (c) async {
    await db.insert(books).values([
      books.title.value('Harry Potter'),
      books.author.value('J.K. Rowling'),
      books.isbn.value('1234567890'),
    ]);

    return c.created();
  });

  app.listen(3000);
}
