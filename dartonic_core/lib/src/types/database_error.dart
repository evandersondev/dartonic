abstract class DatabaseError implements Exception {
  final String message;
  final dynamic originalError;

  DatabaseError(this.message, [this.originalError]);

  @override
  String toString() =>
      'DatabaseError: $message${originalError != null ? '\nCaused by: $originalError' : ''}';
}

class QueryBuildError extends DatabaseError {
  QueryBuildError(super.message, [super.originalError]);
}

class ValidationError extends DatabaseError {
  ValidationError(super.message, [super.originalError]);
}

class ConnectionError extends DatabaseError {
  ConnectionError(super.message, [super.originalError]);
}

class ExecutionError extends DatabaseError {
  ExecutionError(super.message, [super.originalError]);
}

class SchemaError extends DatabaseError {
  SchemaError(super.message, [super.originalError]);
}

class TypeValidationError extends DatabaseError {
  TypeValidationError(super.message, [super.originalError]);
}

/// A database constraint was violated. Base type for [UniqueViolationError],
/// [ForeignKeyError] and [NotNullViolationError] — catch this to handle any
/// constraint failure generically.
class ConstraintViolationError extends DatabaseError {
  ConstraintViolationError(super.message, [super.originalError]);
}

/// A UNIQUE or PRIMARY KEY constraint was violated.
class UniqueViolationError extends ConstraintViolationError {
  UniqueViolationError(super.message, [super.originalError]);
}

/// A NOT NULL constraint was violated.
class NotNullViolationError extends ConstraintViolationError {
  NotNullViolationError(super.message, [super.originalError]);
}

/// A FOREIGN KEY constraint was violated.
class ForeignKeyError extends ConstraintViolationError {
  ForeignKeyError(super.message, [super.originalError]);
}
