import 'package:injectable/injectable.dart' as di;

/// Dependency-injection environments the app can run in.
enum Environment {
  /// Local development against local services.
  local,

  /// Development flavor.
  development,

  /// Staging flavor.
  staging,

  /// Production flavor.
  production,

  /// Test environment for unit and widget tests.
  test,
}

/// Injectable annotation for local-only dependencies.
const di.Environment local = di.Environment('local');

/// Injectable annotation for development-flavor dependencies.
const di.Environment development = di.Environment('development');

/// Injectable annotation for staging-flavor dependencies.
const di.Environment staging = di.Environment('staging');

/// Injectable annotation for production-flavor dependencies.
const di.Environment production = di.Environment('production');

/// Injectable annotation for test-only dependencies.
const di.Environment test = di.Environment('test');
