import 'package:dartonic_core/dartonic_core.dart';

class BookSchema extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final title = text('title').notNull();
  final author = text('author').notNull();
  final isbn = text('isbn').notNull();
}

final books = BookSchema();
