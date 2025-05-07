import 'package:dartonic/dartonic.dart';

import '../models/user.dart';

final dartonic = Dartonic("sqlite::memory:", schemas: [users]);

extension QueryExtension on Query {
  OrmTable get users => dartonic.table('users');
}
