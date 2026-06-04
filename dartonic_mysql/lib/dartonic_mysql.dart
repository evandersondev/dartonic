/// MySQL driver plugin for Dartonic.
///
/// This package only exposes [connectMysql]. Schema, query builder and types
/// live in `package:dartonic_core/dartonic_core.dart` — import that
/// alongside this driver:
///
/// ```dart
/// import 'package:dartonic_core/dartonic_core.dart';
/// import 'package:dartonic_mysql/dartonic_mysql.dart';
///
/// final db = await connectMysql('mysql://…', schemas: [users]);
/// ```
library;

export 'src/connect.dart';
