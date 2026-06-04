import 'package:dartonic_core/dartonic_core.dart';
// Hide matcher names that collide with Dartonic's condition helpers.
import 'package:test/test.dart' hide isNull, isNotNull;

import 'support/schema.dart';

void main() {
  final users = UsersTable();

  test('eq builds clause and binds value', () {
    final c = eq(users.id, 5);
    expect(c.clause, '"users"."id" = ?');
    expect(c.values, [5]);
  });

  test('eqCol compares two columns without binds', () {
    final posts = PostsTable();
    final c = eqCol(posts.userId, users.id);
    expect(c.clause, '"posts"."user_id" = "users"."id"');
    expect(c.values, isEmpty);
  });

  test('gt / lte', () {
    expect(gt(users.id, 1).clause, '"users"."id" > ?');
    expect(lte(users.id, 9).clause, '"users"."id" <= ?');
  });

  test('inArray emits one placeholder per value', () {
    final c = inArray(users.id, [1, 2, 3]);
    expect(c.clause, '"users"."id" IN (?, ?, ?)');
    expect(c.values, [1, 2, 3]);
  });

  test('inArray with empty list is always-false', () {
    expect(inArray(users.id, <int>[]).clause, '1 = 0');
  });

  test('isNull / isNotNull', () {
    expect(isNull(users.active).clause, '"users"."active" IS NULL');
    expect(isNotNull(users.active).clause, '"users"."active" IS NOT NULL');
  });

  test('like binds the pattern verbatim', () {
    final c = like(users.email, '%@x.com');
    expect(c.clause, '"users"."email" LIKE ?');
    expect(c.values, ['%@x.com']);
  });

  test('and composes clauses and concatenates values', () {
    final c = and([eq(users.id, 1), like(users.email, '%@x.com')]);
    expect(c.clause, '("users"."id" = ? AND "users"."email" LIKE ?)');
    expect(c.values, [1, '%@x.com']);
  });

  test('or composes with OR', () {
    final c = or([eq(users.id, 1), eq(users.id, 2)]);
    expect(c.clause, '("users"."id" = ? OR "users"."id" = ?)');
    expect(c.values, [1, 2]);
  });
}
