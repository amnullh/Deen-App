/// Machine-readable error categories shown to the user as plain messages.
enum ErrorCode {
  /// A value was outside its allowed range.
  invalidArgument,

  /// A required record (for example the location) has not been saved yet.
  notFound,

  /// The platform refused or does not support the operation.
  platform,

  /// A permission is missing.
  permissionDenied,

  /// Anything else; the message explains.
  unknown,
}

/// A failure with a code and a message that is safe to show or log (it never
/// contains coordinates or other personal data).
class AppError {
  const AppError(this.code, this.message);

  final ErrorCode code;
  final String message;

  @override
  String toString() => 'AppError($code: $message)';
}

/// Success or failure of an operation, without exceptions crossing layers.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  /// The value, or null on failure.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The error, or null on success.
  AppError? get errorOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final error) => error,
  };
}

class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.error);

  final AppError error;
}
