import 'package:dartonic/dartonic.dart';
import 'package:example/models/todo.dart';

final dartonic = Dartonic("sqlite:database/database.db", [todoSchema]);
