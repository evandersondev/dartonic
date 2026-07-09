/// Bridge between **Dartonic** and **Zard**.
///
/// Define a table once with Dartonic and derive zard validation schemas from
/// it — the drizzle-zod pattern, in Dart:
///
/// ```dart
/// import 'package:dartonic_zard/dartonic_zard.dart';
///
/// class UserSchema extends Table {
///   final id    = integer('id').primaryKey(autoIncrement: true);
///   final name  = text('name').notNull();
///   final email = text('email').notNull().unique();
///   final age   = integer('age'); // nullable
/// }
/// final users = UserSchema();
///
/// final insertUser = createInsertSchema(users, refine: {
///   'email': z.string().email(),
/// });
/// // insertUser omits `id`, keeps `name`/`email` required, `age` optional.
/// ```
library;

export 'package:zard/zard.dart';
export 'src/schema_builder.dart';
