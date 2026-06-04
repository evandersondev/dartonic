import 'package:test/test.dart';

import 'support/schema.dart';

void main() {
  test('strips the Table suffix', () {
    expect(UsersTable().tableName, 'users');
  });

  test('CamelCase becomes snake_case', () {
    expect(BlogPostsTable().tableName, 'blog_posts');
  });

  test('strips the Schema suffix too', () {
    expect(OrderItemSchema().tableName, 'order_item');
  });

  test('explicit tableName override wins', () {
    expect(LegacyAccount().tableName, 'tb_legacy');
  });
}
