/// Base exception class for all app-specific exceptions.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when the API server returns an error.
class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred']);
}

/// Exception thrown when there is no network connectivity.
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// Exception thrown when cached/local data cannot be loaded.
class CacheException extends AppException {
  const CacheException([super.message = 'Failed to load cached data']);
}

/// Exception thrown when no data is available from any source.
class NoDataException extends AppException {
  const NoDataException([super.message = 'No data available']);
}
