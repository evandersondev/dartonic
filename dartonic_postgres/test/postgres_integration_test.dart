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

  group('postgres (pooled)', () {
    late DartonicDb db;

    setUp(() async {
      db = await connectPostgres(uri!,
          schemas: [users], pool: const PoolConfig(max: 5));
      await db.rawQuery('TRUNCATE TABLE "users" RESTART IDENTITY CASCADE');
    });

    tearDown(() async => db.close());

    test('concurrent queries run through the pool', () async {
      await db.insert(users).values([
        users.email.value('a@b.com'),
        users.name.value('Alice'),
      ]);
      // Fire several selects concurrently — with a single connection these
      // would serialize; with a pool they can overlap. Correctness is what we
      // assert here.
      final results = await Future.wait([
        for (var i = 0; i < 10; i++) db.select().from(users),
      ]);
      for (final rows in results) {
        expect(rows, hasLength(1));
      }
    });

    test('transaction pins one connection and commits', () async {
      await db.transaction((tx) async {
        await tx.insert(users).values([
          users.email.value('tx@b.com'),
          users.name.value('Tx'),
        ]);
      });
      final rows = await db.select().from(users);
      expect(rows, hasLength(1));
      expect(rows.first.readNotNull(users.email), 'tx@b.com');
    });

    test('transaction rollback reverts', () async {
      await db.transaction((tx) async {
        await tx.insert(users).values([
          users.email.value('rb@b.com'),
          users.name.value('Rb'),
        ]);
        tx.rollback();
      });
      expect(await db.select().from(users), isEmpty);
    });
  }, skip: skip);
}
