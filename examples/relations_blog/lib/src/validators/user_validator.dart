import 'package:zard/zard.dart';

/// Request-body validators (zard = Zod-style validation for Dart).
/// `.safeParse(map)` returns a result with `.success` / `.data` / `.error`.
final createUserSchema = z.map({
  'name': z.string().min(1),
  'email': z.string().email(),
});
