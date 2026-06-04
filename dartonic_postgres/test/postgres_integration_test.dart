@TestOn('vm')
library;

import 'dart:io';

import 'package:dartonic_core/dartonic_core.dart';
import 'package:dartonic_postgres/dartonic_postgres.dart';
import 'package:test/test.dart';

/// Set `DARTONIC_POSTGRES_URI` to run these against a real database, e.g.:
///   postgres://user:pass@localhost:5432/dartonic_test
/// When unset, the whole group is skipped.
class Users extends Table {
  final id = serial('id').primaryKey();
  final email = text('email').notNull().unique();
  final name = text('name').notNull();
}

final users = Users();

void main() {
  final uri = Platform.environment['DARTONIC_POSTGRES_URI'];
  final skip = uri == null || uri.isEmpty
      ? 'Set DARTONIC_POSTGRES_URI to run Postgres integration tests'
      : null;

  group('postgres', () {
    late DartonicDb db;

    setUp(() async {
      db = await connectPostgres(uri!, schemas: [users]);
      await db.rawQuery('TRUNCATE TABLE "users" RESTART IDENTITY CASCADE');
    });

    tearDown(() async => db.close());

    test('insert + select round-trips', () async {
      await db.insert(users).values([
        users.email.value('a@b.com'),
        users.name.value('Alice'),
      ]);
      final rows = await db.select().from(users);
      expect(rows, hasLength(1));
      expect(rows.first.readNotNull(users.email), 'a@b.com');
    });

    test('UNIQUE violation maps to UniqueViolationError', () async {
      await db.insert(users).values([
        users.email.value('a@b.com'),
        users.name.value('Alice'),
      ]);
      expect(
        () => db.insert(users).values([
          users.email.value('a@b.com'),
          users.name.value('Other'),
        ]),
        throwsA(isA<UniqueViolationError>()),
      );
    });
  }, skip: skip);
}
