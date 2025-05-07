import 'package:dartonic/src/drivers/driver.dart';

abstract class RawDriver {
  Future<List<Map<String, dynamic>>> raw(String query,
      [List<dynamic>? parameters]);
}

class RawDriverWrapper implements RawDriver {
  final DatabaseDriver _driver;

  RawDriverWrapper(this._driver);

  @override
  Future<List<Map<String, dynamic>>> raw(String query,
      [List<dynamic>? parameters]) async {
    return await _driver.execute(query, parameters);
  }
}
