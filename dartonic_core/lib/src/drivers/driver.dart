import '../types/query_types.dart';

export '../types/query_types.dart';

/// Driver interface implemented by each database backend (SQLite, Postgres,
/// MySQL, …). Drivers handle the SQL transport layer; they don't know about
/// schemas or typed columns.
abstract class DatabaseDriver {
  Future<void> connect();
  Future<void> raw(String query, [List<Object?>? parameters]);
  Future<RawQueryResult> execute(String query, [List<Object?>? parameters]);
  Future<void> createTable(String table, Map<String, String> columns);
  Future<void> beginTransaction();
  Future<void> commitTransaction();
  Future<void> rollbackTransaction();

  /// Closes the underlying connection and releases its resources. After this
  /// the driver must not be used again.
  Future<void> close();
}
