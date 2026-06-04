import 'package:dartonic_core/dartonic_core.dart';

/// Inspection helpers — handy to *see* what the schema produced.
class MetaRepository {
  final DartonicDb _db;
  MetaRepository(this._db);

  /// Lists the tables SQLite actually created from the schema.
  Future<List<String>> listTables() async {
    final rows = await _db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
      "ORDER BY name",
    );
    return rows.map((r) => r['name'] as String).toList();
  }
}
