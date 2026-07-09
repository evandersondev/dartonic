/// Connection-pool configuration shared by the network drivers
/// (Postgres, MySQL). Passed to `connectPostgres(pool: ...)` /
/// `connectMysql(pool: ...)`.
///
/// SQLite ignores this (a single embedded file handle has no pool), but
/// `connectSqlite` still accepts it for API symmetry.
///
/// ```dart
/// final db = await connectPostgres(
///   uri,
///   schemas: [...],
///   pool: const PoolConfig(max: 20),
/// );
/// ```
class PoolConfig {
  /// Maximum number of concurrent connections the pool may hold open.
  final int max;

  /// Minimum number of connections to keep warm. Drivers that create
  /// connections lazily (MySQL) may treat this as an eager pre-warm count.
  final int min;

  /// How long an idle pooled connection may live before it is eligible to be
  /// closed. Not every backend honours this precisely; see each driver's docs.
  final Duration idleTimeout;

  const PoolConfig({
    this.max = 10,
    this.min = 0,
    this.idleTimeout = const Duration(minutes: 5),
  })  : assert(max > 0, 'PoolConfig.max must be > 0'),
        assert(min >= 0, 'PoolConfig.min must be >= 0'),
        assert(min <= max, 'PoolConfig.min must be <= max');
}
