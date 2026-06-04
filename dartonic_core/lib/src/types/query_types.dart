/// Raw driver result — kept for legacy/raw query paths. New code should use
/// [RowMap] from `row.dart`.
typedef RawQueryResult = List<Map<String, Object?>>;

/// A single raw row keyed by SQL column name. Values are NOT decoded — use
/// [RowMap] from `row.dart` for typed access.
typedef RawRow = Map<String, Object?>;
