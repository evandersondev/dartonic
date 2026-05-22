import 'package:dartonic_core/dartonic_core.dart';

import '../database/db.dart';
import '../database/schemas.dart';

/// Demonstrates accessing the shared [db] from another file — no new
/// connection is opened here.
class BookService {
  const BookService();

  Future<List<RowMap>> all() => db.select().from(books).orderBy(books.id);

  Future<int> count() async {
    final rows = await db.select([countAll()]).from(books);
    return rows.first.raw.values.first as int;
  }

  Future<void> add({
    required String title,
    required String author,
    required String isbn,
  }) =>
      db.insert(books).values([
        books.title.value(title),
        books.author.value(author),
        books.isbn.value(isbn),
      ]);
}
