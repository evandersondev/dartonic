import 'package:darto/darto.dart';
import 'package:darto_inject/darto_inject.dart';

import '../di.dart';
import '../validators/user_validator.dart';

/// HTTP layer for users. Resolves the repository from the DI request scope
/// (`c.readAsync`), validates input, and maps results to JSON.
void registerUserRoutes(Darto app) {
  // Create a user (body validated with zard).
  app.post('/users', [], (c) async {
    final body = await c.req.json();
    final parsed = createUserSchema.safeParse(body);
    if (!parsed.success) {
      return c.badRequest({'errors': parsed.error?.format()});
    }
    final data = parsed.data!;
    final repo = await c.readAsync(userRepositoryProvider);
    final user = await repo.create(
      data['name'] as String,
      data['email'] as String,
    );
    return c.created(user.toJson());
  });

  // ONE-TO-MANY: a user and their posts.
  app.get('/users/:id/posts', [], (c) async {
    final id = c.req.paramInt('id');
    if (id == null) return c.badRequest({'error': 'invalid id'});
    final repo = await c.readAsync(userRepositoryProvider);
    final result = await repo.postsOf(id);
    if (result == null) return c.notFound({'error': 'user not found'});
    return c.json({
      'user': result.user.toJson(),
      'posts': result.posts.map((p) => p.toJson()).toList(),
    });
  });

  // ONE-TO-ONE: a user and their profile.
  app.get('/users/:id/profile', [], (c) async {
    final id = c.req.paramInt('id');
    if (id == null) return c.badRequest({'error': 'invalid id'});
    final repo = await c.readAsync(userRepositoryProvider);
    final result = await repo.profileOf(id);
    if (result == null) return c.notFound({'error': 'user not found'});
    return c.json({
      'user': result.user.toJson(),
      'profile': result.profile?.toJson(),
    });
  });

  // MANY-TO-MANY: a user and their groups.
  app.get('/users/:id/groups', [], (c) async {
    final id = c.req.paramInt('id');
    if (id == null) return c.badRequest({'error': 'invalid id'});
    final repo = await c.readAsync(userRepositoryProvider);
    final result = await repo.groupsOf(id);
    if (result == null) return c.notFound({'error': 'user not found'});
    return c.json({
      'user': result.user.toJson(),
      'groups': result.groups.map((g) => g.toJson()).toList(),
    });
  });
}
