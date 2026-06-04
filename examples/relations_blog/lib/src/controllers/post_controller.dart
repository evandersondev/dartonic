import 'package:darto/darto.dart';
import 'package:darto_inject/darto_inject.dart';

import '../di.dart';

void registerPostRoutes(Darto app) {
  // MANY-TO-ONE: a post and its single author.
  app.get('/posts/:id', [], (c) async {
    final id = c.req.paramInt('id');
    if (id == null) return c.badRequest({'error': 'invalid id'});
    final repo = await c.readAsync(postRepositoryProvider);
    final result = await repo.withAuthor(id);
    if (result == null) return c.notFound({'error': 'post not found'});
    return c.json({
      'id': result.post.id,
      'title': result.post.title,
      'author': result.author.toJson(),
    });
  });
}
