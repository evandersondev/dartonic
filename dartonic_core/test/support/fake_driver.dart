import 'package:dartonic_core/dartonic_core.dart';

/// In-memory test double for [DatabaseDriver]. Records every SQL call and the
/// transaction lifecycle, and returns programmable rows from [execute].
class FakeDriver implements DatabaseDriver {
  /// Every raw()/execute() call, in order.
  final List<({String sql, List<Object?>? params})> calls = [];

  /// Transaction + lifecycle events: BEGIN / COMMIT / ROLLBACK / CLOSE.
  final List<String> txLog = [];

  /// FIFO queue of canned responses for the next [execute] calls.
  final List<RawQueryResult> responses = [];

  bool connected = false;
  bool closed = false;

  @override
  Future<void> connect() async => connected = true;

  @override
  Future<void> raw(String query, [List<Object?>? parameters]) async {
    calls.add((sql: query, params: parameters));
  }

  @override
  Future<RawQueryResult> execute(String query,
      [List<Object?>? parameters]) async {
    calls.add((sql: query, params: parameters));
    return responses.isNotEmpty
        ? responses.removeAt(0)
        : <Map<String, Object?>>[];
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    calls.add((sql: 'CREATE TABLE $table', params: null));
  }

  @override
  Future<void> beginTransaction() async => txLog.add('BEGIN');

  @override
  Future<void> commitTransaction() async => txLog.add('COMMIT');

  @override
  Future<void> rollbackTransaction() async => txLog.add('ROLLBACK');

  @override
  Future<void> close() async {
    txLog.add('CLOSE');
    closed = true;
  }
}
