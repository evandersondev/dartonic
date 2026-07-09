import 'dart:async';

import 'package:dartonic_core/dartonic_core.dart';
import 'package:postgres/postgres.dart';

/// PostgreSQL driver.
///
/// When a [PoolConfig] is supplied the driver runs every statement through a
/// `postgres` [Pool], so concurrent requests no longer serialize on a single
/// socket. Without one it keeps a single [Connection] (backwards compatible).
///
/// **Transactions** pin one connection for their whole duration. A pinned
/// connection is checked out on [beginTransaction] and released on
/// [commitTransaction] / [rollbackTransaction], so every statement issued
/// between them runs on the same backend session.
///
/// **Prepared-statement caching**: this driver does not maintain its own
/// statement cache. The `postgres` package prepares statements internally for
/// `execute(...)` and reuses them per connection, so repeated queries already
/// benefit from client-side statement reuse without extra work here.
class PostgresDriver implements DatabaseDriver {
  final String uri;
  final PoolConfig? poolConfig;

  // Non-pooled mode: a single long-lived connection.
  Connection? _conn;

  // Pooled mode: the pool plus, when a transaction is active, the connection
  // checked out for it (and a completer used to hold it until commit/rollback).
  Pool? _pool;

  // The session currently serving statements: either a pinned transaction
  // connection or, when null, statements go through the pool / single conn.
  Session? _txSession;
  // Releases the pinned pool connection back to the pool. Non-null only while
  // a pooled transaction is in flight.
  void Function()? _releaseTxConnection;

  PostgresDriver(this.uri, {this.poolConfig});

  bool get _pooled => poolConfig != null;

  @override
  Future<void> connect() async {
    try {
      final parsed = Uri.parse(uri);
      final parts = parsed.userInfo.split(':');
      final endpoint = Endpoint(
        host: parsed.host,
        port: parsed.port,
        database: parsed.path.substring(1),
        username: parts.first,
        password: parts.length > 1 ? parts.last : null,
      );
      final sslMode = switch (parsed.queryParameters['sslmode']) {
        'require' => SslMode.require,
        'verify-full' => SslMode.verifyFull,
        _ => SslMode.disable,
      };

      if (_pooled) {
        _pool = Pool.withEndpoints(
          [endpoint],
          settings: PoolSettings(
            maxConnectionCount: poolConfig!.max,
            sslMode: sslMode,
          ),
        );
      } else {
        _conn = await Connection.open(
          endpoint,
          settings: ConnectionSettings(sslMode: sslMode),
        );
      }
    } catch (e) {
      throw ConnectionError('Failed to connect to PostgreSQL', e);
    }
  }

  /// The session statements should run on right now.
  ///
  /// - inside a transaction → the pinned session,
  /// - pooled, no transaction → the pool (checks out a connection per call),
  /// - single connection → that connection.
  Session get _session {
    if (_txSession != null) return _txSession!;
    if (_pool != null) return _pool!;
    final c = _conn;
    if (c == null) {
      throw ConnectionError('PostgreSQL driver is not connected');
    }
    return c;
  }

  @override
  Future<void> raw(String query, [List<Object?>? parameters]) async {
    try {
      if (parameters == null) {
        await _session.execute(query);
      } else {
        await _session.execute(_toPositional(query, parameters),
            parameters: parameters);
      }
    } catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<RawQueryResult> execute(String query,
      [List<Object?>? parameters]) async {
    try {
      final result = parameters == null
          ? await _session.execute(query)
          : await _session.execute(_toPositional(query, parameters),
              parameters: parameters);
      return result.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    final defs = columns.entries
        .map((e) =>
            '"${e.key}" ${e.value.replaceAll('AUTOINCREMENT', '').replaceAll('AUTOGENERATE', '')}')
        .join(', ');
    await _session.execute('CREATE TABLE IF NOT EXISTS "$table" ($defs)');
  }

  // ── Transactions ─────────────────────────────────────────────────────────
  //
  // We can't use pool.runTx here because DatabaseFacade drives transactions
  // imperatively (begin → run statements on the driver → commit). Instead we
  // check out one connection, issue BEGIN on it, and route subsequent
  // statements to it via [_txSession] until COMMIT/ROLLBACK releases it.

  @override
  Future<void> beginTransaction() async {
    if (_txSession != null) {
      throw ExecutionError(
          'A transaction is already active on this PostgreSQL driver');
    }
    if (_pool != null) {
      // Check out a dedicated connection and hold it open until commit/rollback.
      final ready = Completer<void>();
      final done = Completer<void>();
      // ignore: unawaited_futures
      _pool!.withConnection((conn) async {
        _txSession = conn;
        ready.complete();
        await done.future;
      }).catchError((Object e) {
        if (!ready.isCompleted) ready.completeError(e);
      });
      _releaseTxConnection = () => done.complete();
      await ready.future;
    } else {
      _txSession = _conn;
    }
    await _session.execute('BEGIN');
  }

  @override
  Future<void> commitTransaction() => _endTransaction('COMMIT');

  @override
  Future<void> rollbackTransaction() => _endTransaction('ROLLBACK');

  Future<void> _endTransaction(String verb) async {
    try {
      await _session.execute(verb);
    } catch (e) {
      _mapAndThrow(e);
    } finally {
      _txSession = null;
      _releaseTxConnection?.call();
      _releaseTxConnection = null;
    }
  }

  @override
  Future<void> close() async {
    await _pool?.close();
    await _conn?.close();
    _pool = null;
    _conn = null;
  }

  String _toPositional(String sql, List<Object?> params) {
    var i = 0;
    return sql.replaceAllMapped(RegExp(r'\?'), (_) => '\$${++i}');
  }

  /// Translates a native [ServerException] into a typed [DatabaseError] using
  /// the SQLSTATE code; non-constraint errors become [ExecutionError].
  Never _mapAndThrow(Object e) {
    if (e is DatabaseError) throw e;
    if (e is ServerException) {
      switch (e.code) {
        case '23505': // unique_violation
          throw UniqueViolationError(e.message, e);
        case '23503': // foreign_key_violation
          throw ForeignKeyError(e.message, e);
        case '23502': // not_null_violation
          throw NotNullViolationError(e.message, e);
      }
    }
    throw ExecutionError('PostgreSQL query failed', e);
  }
}
