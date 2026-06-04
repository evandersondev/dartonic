import 'package:darto/darto.dart';
import 'package:darto_inject/darto_inject.dart';

import '../di.dart';

void registerMetaRoutes(Darto app) {
  // Which tables did the schema create?
  app.get('/_tables', [], (c) async {
    final repo = await c.readAsync(metaRepositoryProvider);
    return c.json({'tables': await repo.listTables()});
  });
}
