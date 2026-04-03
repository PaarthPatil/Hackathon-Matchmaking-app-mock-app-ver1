class ApiConstants {
  static const String pythonBaseUrl = String.fromEnvironment(
    'PYTHON_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8001/api/v1',
  );
}
