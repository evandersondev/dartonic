import 'dart:async';
import 'dart:collection';

import 'package:dartonic_core/dartonic_core.dart';
import 'package:mysql1/mysql1.dart' as mysql;

/// MySQL driver.
///
/// `mysql1` has no built-in connection pool, so when a [PoolConfig] is
/// supplied this driver runs a small internal pool ([_MysqlPool]): connections
/// are created on demand up to [PoolConfig.max], returned to a free queue
/// after use, and reused. Without a [PoolConfig] it keeps a single connection
/// (backwards compatible).
///
/// Every pooled connection has `ANSI_QUOTES` enabled at creation time, because
/// Dartonic quotes identifiers with double quotes.
///
/// **Transactions** pin one connection for their whole duration: it is checked
/// out on [beginTransaction] and returned on commit/rollback, so all
/// statements in between run on the same connection.
///
/// **Prepared-statement caching**: this driver does not maintain its own
/// statement cache. `mysql1` prepares each `query(...)` on the wire; it has no
/// stable client-side statement cache we can safely reuse, so repeated queries
/// are re-prepared by the client. A future migration to a maintained driver
/// (e.g. `mysql_client`) could add real statement reuse.
class MysqlDriver implements DatabaseDriver {
  final String uri;
  final PoolConfig? poolConfig;

  mysql.ConnectionSettings? _settings;

  // Non-pooled mode.
  mysql.MySqlConnection? _conn;

  // Pooled mode.
  _MysqlPool? _pool;

  // Connection pinned for the current transaction (either mode).
  mysql.MySqlConnection? _txConn;

  MysqlDriver(this.uri, {this.poolConfig});

  bool get _pooled => poolConfig != null;

  @override
  Future<void> connect() async {
    try {
      final parsed = Uri.parse(uri);
      final parts = parsed.userInfo.split(':');
      _settings = mysql.ConnectionSettings(
        host: parsed.host,
        port: parsed.port,
        user: parts.first,
        password: parts.length > 1 ? parts.last : null,
        db: parsed.path.substring(1),
      );

      if (_pooled) {
        _pool = _MysqlPool(_settings!, poolConfig!);
        await _pool!.prewarm();
      } else {
        _conn = await _open(_settings!);
      }
    } catch (e) {
      throw ConnectionError('Failed to connect to MySQL', e);
    }
  }

  /// Opens one connection and enables ANSI_QUOTES on it. Dartonic's query
  /// builder quotes identifiers with double quotes (`"table"."column"`), which
  /// MySQL only accepts in ANSI_QUOTES mode. Appended so STRICT/other modes
  /// survive.
  static Future<mysql.MySqlConnection> _open(
      mysql.ConnectionSettings settings) async {
    final conn = await mysql.MySqlConnection.connect(settings);
    await conn.query(
        "SET SESSION sql_mode = CONCAT(@@SESSION.sql_mode, ',ANSI_QUOTES')");
    return conn;
  }

  /// Runs [fn] with a connection, honouring transaction pinning and pooling.
  Future<T> _withConnection<T>(
      Future<T> Function(mysql.MySqlConnection conn) fn) async {
    if (_txConn != null) return fn(_txConn!);
    if (_pool != null) {
      final conn = await _pool!.acquire();
      try {
        return await fn(conn);
      } finally {
        _pool!.release(conn);
      }
    }
    final c = _conn;
    if (c == null) throw ConnectionError('MySQL driver is not connected');
    return fn(c);
  }

  @override
  Future<void> raw(String query, [List<Object?>? parameters]) async {
    try {
      await _withConnection((c) =>
          parameters == null ? c.query(query) : c.query(query, parameters));
    } catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<RawQueryResult> execute(String query,
      [List<Object?>? parameters]) async {
    try {
      final result = await _withConnection((c) =>
          parameters == null ? c.query(query) : c.query(query, parameters));
      return result
          .map((row) => Map<String, Object?>.from(row.fields))
          .toList();
    } catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<void> createTable(String table, Map<String, String> columns) async {
    final defs = columns.entries
        .map((e) =>
            '`${e.key}` ${e.value.replaceAll('AUTOINCREMENT', 'AUTO_INCREMENT').replaceAll('AUTOGENERATE', '')}')
        .join(', ');
    await _withConnection(
        (c) => c.query('CREATE TABLE IF NOT EXISTS `$table` ($defs)'));
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  @override
  Future<void> beginTransaction() async {
    if (_txConn != null) {
      throw ExecutionError('A transaction is already active on this MySQL driver');
    }
    _txConn = _pool != null ? await _pool!.acquire() : _conn;
    await _txConn!.query('BEGIN');
  }

  @override
  Future<void> commitTransaction() => _endTransaction('COMMIT');

  @override
  Future<void> rollbackTransaction() => _endTransaction('ROLLBACK');

  Future<void> _endTransaction(String verb) async {
    final conn = _txConn;
    if (conn == null) return;
    try {
      await conn.query(verb);
    } catch (e) {
      _mapAndThrow(e);
    } finally {
      _txConn = null;
      if (_pool != null) _pool!.release(conn);
    }
  }

  @override
  Future<void> close() async {
    await _pool?.close();
    await _conn?.close();
    _pool = null;
    _conn = null;
  }

  /// Translates a native [mysql.MySqlException] into a typed [DatabaseError]
  /// using the MySQL error number; non-constraint errors become
  /// [ExecutionError].
  Never _mapAndThrow(Object e) {
    if (e is DatabaseError) throw e;
    if (e is mysql.MySqlException) {
      switch (e.errorNumber) {
        case 1062: // ER_DUP_ENTRY
          throw UniqueViolationError(e.message, e);
        case 1452: // ER_NO_REFERENCED_ROW_2
          throw ForeignKeyError(e.message, e);
        case 1048: // ER_BAD_NULL_ERROR
          throw NotNullViolationError(e.message, e);
      }
    }
    throw ExecutionError('MySQL query failed', e);
  }
}

/// A minimal FIFO connection pool for `mysql1`.
///
/// Connections are created lazily up to [PoolConfig.max] and reused via a free
/// queue. When the pool is exhausted, [acquire] waits (FIFO) until a connection
/// is released. Idle connections older than [PoolConfig.idleTimeout] are closed
/// on release rather than being returned to the queue.
class _MysqlPool {
  final mysql.ConnectionSettings _settings;
  final PoolConfig _config;

  final Queue<_PooledConn> _free = Queue();
  final Queue<Completer<mysql.MySqlConnection>> _waiters = Queue();
  int _open = 0; // total live connections (free + checked out)
  bool _closed = false;

  _MysqlPool(this._settings, this._config);

  /// Eagerly opens [PoolConfig.min] connections.
  Future<void> prewarm() async {
    for (var i = 0; i < _config.min; i++) {
      final conn = await MysqlDriver._open(_settings);
      _open++;
      _free.add(_PooledConn(conn));
    }
  }

  Future<mysql.MySqlConnection> acquire() async {
    if (_closed) throw ConnectionError('MySQL pool is closed');

    // Reuse a fresh idle connection if available.
    while (_free.isNotEmpty) {
      final pooled = _free.removeFirst();
      if (_isExpired(pooled)) {
        _open--;
        // Fire-and-forget close of the stale connection.
        unawaited(pooled.conn.close());
        continue;
      }
      return pooled.conn;
    }

    if (_open < _config.max) {
      _open++;
      try {
        return await MysqlDriver._open(_settings);
      } catch (e) {
        _open--;
        rethrow;
      }
    }

    // Pool exhausted — wait for a release.
    final completer = Completer<mysql.MySqlConnection>();
    _waiters.add(completer);
    return completer.future;
  }

  void release(mysql.MySqlConnection conn) {
    if (_closed) {
      unawaited(conn.close());
      return;
    }
    // Hand directly to the next waiter if any.
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete(conn);
      return;
    }
    _free.add(_PooledConn(conn));
  }

  bool _isExpired(_PooledConn pooled) =>
      DateTime.now().difference(pooled.idleSince) > _config.idleTimeout;

  Future<void> close() async {
    _closed = true;
    for (final w in _waiters) {
      w.completeError(ConnectionError('MySQL pool closed while waiting'));
    }
    _waiters.clear();
    final toClose = _free.map((p) => p.conn).toList();
    _free.clear();
    for (final c in toClose) {
      await c.close();
    }
  }
}

class _PooledConn {
  final mysql.MySqlConnection conn;
  final DateTime idleSince;
  _PooledConn(this.conn) : idleSince = DateTime.now();
}
