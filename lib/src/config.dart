/// Central configuration for the app.
///
/// To use your own backend, build with:
/// flutter run --dart-define=API_BASE_URL=https://your-api-gateway-url/stage
/// or for release: flutter build apk --dart-define=API_BASE_URL=...
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://atq65hnu62.execute-api.us-east-1.amazonaws.com/first',
);
