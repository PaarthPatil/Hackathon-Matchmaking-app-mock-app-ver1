class CatalystException implements Exception {
  final String message;
  final dynamic originalError;

  CatalystException(this.message, {this.originalError});

  @override
  String toString() => 'CatalystException: $message';
}

class AuthException extends CatalystException {
  AuthException(String message) : super(message);
}

class NetworkException extends CatalystException {
  NetworkException(String message) : super(message);
}
