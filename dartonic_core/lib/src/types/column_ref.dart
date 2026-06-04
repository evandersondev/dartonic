/// Typed reference to a column. Carries the Dart type [T] so query builders
/// and condition helpers can be checked at compile time.
///
/// In normal usage you never instantiate [ColumnRef] directly — declare a
/// [Column] on a [Table] subclass and the framework hands you back a fully
/// bound [ColumnRef].
abstract class ColumnRef<T> {
  const ColumnRef();

  /// Table the column belongs to. Empty string if the column has not been
  /// bound to a table yet.
  String get table;

  /// Raw SQL column name (the underlying SQL identifier, not the Dart field
  /// name).
  String get column;

  /// Encodes a Dart value of type [T] to the raw representation the driver
  /// expects. Used by INSERT / UPDATE / WHERE binders.
  Object? encode(T? value);

  /// Decodes a raw value returned by the driver into [T].
  T? decode(Object? raw);

  /// Returns `"table"."column"` quoted for use in SQL fragments. If the
  /// column has not been bound to a table the table prefix is omitted.
  String toSqlIdentifier() {
    if (table.isEmpty) return '"$column"';
    return '"$table"."$column"';
  }

  @override
  String toString() => toSqlIdentifier();
}
