@TestOn('vm')
library;

import 'dart:io';

import 'package:dartonic_core/dartonic_core.dart';
import 'package:dartonic_mysql/dartonic_mysql.dart';
import 'package:test/test.dart';

/// Set `DARTONIC_MYSQL_URI` to run these against a real database, e.g.:
///   mysql://user:pass@localhost:3306/dartonic_test
/// When unset, the whole group is skipped.
class Users extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final email = varchar('email', length: 191).notNull().unique();
  final name = text('name').notNull();
}

final users = Users();

void main() {
  final uri = Platform.environment['DARTONIC_MYSQL_URI'];
  final skip = uri == null || uri.isEmpty
      ? 'Set DARTONIC_MYSQL_URI to run MySQL integration tests'
      : null;

  group('mysql', () {
    late DartonicDb db;

    setUp(() async {
      db = await connectMysql(uri!, schemas: [users]);
      await db.rawQuery('DELETE FROM `users`');
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

    test('transaction commit persists', () async {
      await db.transaction((tx) async {
        await tx.insert(users).values([
          users.email.value('a@b.com'),
          users.name.value('Alice'),
        ]);
      });
      expect(await db.select().from(users), hasLength(1));
    });

    // KNOWN LIMITATION: the `mysql1` package (0.20.0, unmaintained) cannot
    // parse MySQL 8 error packets — it throws a RangeError and corrupts the
    // connection instead of producing a MySqlException. So constraint
    // violations cannot be classified (UniqueViolationError etc.) on MySQL 8.
    // Tracked for a future migration to a maintained driver (e.g.
    // `mysql_client`). On MySQL 5.7 the mapping works.
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
    }, skip: 'mysql1 0.20.0 cannot parse MySQL 8 error packets');
  }, skip: skip);

  group('mysql (pooled)', () {
    late DartonicDb db;

    setUp(() async {
      db = await connectMysql(uri!,
          schemas: [users], pool: const PoolConfig(max: 5, min: 1));
      await db.rawQuery('DELETE FROM `users`');
    });

    tearDown(() async => db.close());

    test('concurrent queries run through the internal pool', () async {
      await db.insert(users).values([
        users.email.value('a@b.com'),
        users.name.value('Alice'),
      ]);
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
  }, skip: skip);
}
