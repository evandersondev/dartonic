import 'package:dartonic_core/dartonic_core.dart';
import 'package:dartonic_zard/dartonic_zard.dart';
import 'package:test/test.dart';

class UserSchema extends Table {
  final id = integer('id').primaryKey(autoIncrement: true);
  final name = text('name').notNull();
  final email = text('email').notNull().unique();
  final age = integer('age'); // nullable
  final createdAt = timestamp('created_at').defaultNow();
}

final users = UserSchema();

void main() {
  group('createInsertSchema', () {
    final insert = createInsertSchema(users);

    test('omits auto-increment primary key', () {
      final r = insert.safeParse({
        'name': 'Alice',
        'email': 'a@b.com',
      });
      expect(r.success, isTrue);
      // id is not part of the shape → ignored / not required.
      expect((r.data as Map).containsKey('id'), isFalse);
    });

    test('NOT NULL columns without default are required', () {
      final r = insert.safeParse({'email': 'a@b.com'}); // missing name
      expect(r.success, isFalse);
    });

    test('columns with a DEFAULT are optional (created_at)', () {
      final r = insert.safeParse({'name': 'Bob', 'email': 'b@c.com'});
      expect(r.success, isTrue);
    });

    test('nullable columns are optional (age)', () {
      final r = insert.safeParse({'name': 'Bob', 'email': 'b@c.com'});
      expect(r.success, isTrue);
    });

    test('refine tightens a column without restating presence', () {
      final refined = createInsertSchema(users, refine: {
        'email': z.string().email(),
      });
      expect(refined.safeParse({'name': 'A', 'email': 'not-an-email'}).success,
          isFalse);
      expect(refined.safeParse({'name': 'A', 'email': 'a@b.com'}).success,
          isTrue);
    });
  });

  group('createSelectSchema', () {
    final select = createSelectSchema(users);

    test('includes every column', () {
      final r = select.safeParse({
        'id': 1,
        'name': 'Alice',
        'email': 'a@b.com',
        'age': null,
        'created_at': DateTime.now(),
      });
      expect(r.success, isTrue);
    });

    test('nullable column accepts null', () {
      final r = select.safeParse({
        'id': 1,
        'name': 'Alice',
        'email': 'a@b.com',
        'age': null,
        'created_at': DateTime.now(),
      });
      expect(r.success, isTrue);
    });
  });

  group('createUpdateSchema', () {
    final update = createUpdateSchema(users);

    test('all fields optional (partial)', () {
      expect(update.safeParse(<String, dynamic>{}).success, isTrue);
      expect(update.safeParse({'name': 'New name'}).success, isTrue);
    });

    test('still validates provided fields', () {
      final refined = createUpdateSchema(users, refine: {
        'email': z.string().email(),
      });
      expect(refined.safeParse({'email': 'bad'}).success, isFalse);
    });
  });
}
