import 'package:darto/darto.dart';
import 'package:darto/logger.dart';
import 'package:darto_inject/darto_inject.dart';

import 'controllers/meta_controller.dart';
import 'controllers/post_controller.dart';
import 'controllers/user_controller.dart';
import 'di.dart';

/// Composition root: builds the DI container, eagerly opens/seeds the database
/// via `warmup()`, attaches the request-scope middleware, and registers the
/// controllers. Controllers resolve their repositories from the request
/// context (`c.readAsync(...)`).
Future<Darto> bootstrap() async {
  final di = Di(asyncProviders: appProviders);
  await di.warmup();

  final app = Darto();
  app.use(logger());
  app.use(di.middleware());

  registerMetaRoutes(app);
  registerUserRoutes(app);
  registerPostRoutes(app);

  final meta = await di.readAsync(metaRepositoryProvider);
  print('Tables created: ${await meta.listTables()}');
  return app;
}
