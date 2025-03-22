import 'package:dartonic/dartonic.dart';

import '../models/order.dart';
import '../models/user.dart';

final dartlize = Dartonic("sqlite::memory:", [usersTable, ordersTable]);
