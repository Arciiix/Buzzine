class APIException implements Exception {
  String cause;
  APIException(this.cause);
}
