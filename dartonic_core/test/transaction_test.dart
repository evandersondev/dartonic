import 'package:dartonic_core/dartonic_core.dart';
import 'package:test/test.dart';

import 'support/fake_driver.dart';
import 'support/schema.dart';

void main() {
  final users = UsersTable();
  late FakeDriver driver;
  late DatabaseFacade db;

  setUp(() {
    driver = FakeDriver();
    db = DatabaseFacade(driver, dialect: Dialect.sqlite);
  });

  test('commits on success', () async {
    await db.transaction((tx) async {
      await tx.insert(users).values([
        users.email.value('a@b.com'),
        users.name.value('x'),
      ]);
    });
    expect(driver.txLog, ['BEGIN', 'COMMIT']);
  });

  test('rollback() rolls back without bubbling', () async {
    await db.transaction((tx) async {
      tx.rollback();
    });
    expect(driver.txLog, ['BEGIN', 'ROLLBACK']);
  });

  test('an error rolls back and rethrows', () async {
    await expectLater(
      db.transaction((tx) async => throw StateError('boom')),
      throwsA(isA<StateError>()),
    );
    expect(driver.txLog, ['BEGIN', 'ROLLBACK']);
  });
}
