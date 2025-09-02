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

class ForeignKeyError extends DatabaseError {
  ForeignKeyError(super.message, [super.originalError]);
}
