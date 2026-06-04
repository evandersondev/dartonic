import 'package:darto_inject/darto_inject.dart';
import 'package:dartonic_core/dartonic_core.dart';

import 'config/database.dart';
import 'database/seed.dart';
import 'repositories/meta_repository.dart';
import 'repositories/post_repository.dart';
import 'repositories/user_repository.dart';

// ════════════════════════════════════════════════════════════════════════
//  DEPENDENCY INJECTION (darto_inject)
//
//  Each provider is a typed factory + identity key. They're app-scoped, so the
//  container builds each once at `warmup()` and caches it. The database is an
//  AsyncProvider because connecting/seeding is async; repositories depend on it
//  via `di.readAsync(dbProvider)`.
// ════════════════════════════════════════════════════════════════════════

/// The shared connection — opened and seeded once at warmup.
///
/// (For a real file/Postgres database, close it on shutdown with
/// `await db.close()`. We don't wire `onDispose` here because in-memory SQLite
/// is released on exit anyway.)
final dbProvider = AsyncProvider<DartonicDb>(
  (di) async {
    final db = await openDatabase();
    await seedDatabase(db);
    return db;
  },
  name: 'database',
);

final userRepositoryProvider = AsyncProvider<UserRepository>(
  (di) async => UserRepository(await di.readAsync(dbProvider)),
  name: 'UserRepository',
);

final postRepositoryProvider = AsyncProvider<PostRepository>(
  (di) async => PostRepository(await di.readAsync(dbProvider)),
  name: 'PostRepository',
);

final metaRepositoryProvider = AsyncProvider<MetaRepository>(
  (di) async => MetaRepository(await di.readAsync(dbProvider)),
  name: 'MetaRepository',
);

/// Registered with the container so `warmup()` builds them eagerly.
final appProviders = <AsyncProvider>[
  dbProvider,
  userRepositoryProvider,
  postRepositoryProvider,
  metaRepositoryProvider,
];
