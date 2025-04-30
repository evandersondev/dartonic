import 'package:dartonic/src/drivers/driver.dart';

abstract class RawDriver {
  Future<void> raw(String query, [List<dynamic>? parameters]);
}

class RawDriverWrapper implements RawDriver {
  final DatabaseDriver _driver;

  RawDriverWrapper(this._driver);

  @override
  Future<void> raw(String query, [List<dynamic>? parameters]) {
    return _driver.raw(query, parameters);
  }
}
