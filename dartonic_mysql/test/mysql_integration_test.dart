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
}
