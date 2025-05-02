import 'package:dartonic/dartonic.dart';

import '../models/user.dart';

final dartonic = Dartonic("sqlite::memory:", schemas: [usersSchemas]);
