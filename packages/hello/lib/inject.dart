import 'package:core/core.dart' as core;
import 'package:get_it/get_it.dart';
import 'package:hello/inject.config.dart';
import 'package:injectable/injectable.dart' as injectable;

/// The app's service locator.
final GetIt injector = GetIt.instance;

/// Registers dependencies for the given [environment].
@injectable.InjectableInit()
Future<void> configureInjection(core.Environment environment) async {
  await injector.reset();

  injector.registerLazySingleton<core.BuildConfiguration>(
    () => switch (environment) {
      core.Environment.production => const core.BuildConfiguration(
        appTitle: 'hello',
        baseEndpointUrl: 'https://api.example.com',
      ),
      core.Environment.staging => const core.BuildConfiguration(
        appTitle: 'hello Staging',
        baseEndpointUrl: 'https://staging-api.example.com',
      ),
      _ => const core.BuildConfiguration(
        appTitle: 'hello Dev',
        baseEndpointUrl: 'https://dev-api.example.com',
      ),
    },
  );

  final injectableEnvironment = switch (environment) {
    core.Environment.development => injectable.Environment.dev,
    core.Environment.production => injectable.Environment.prod,
    core.Environment.staging => 'staging',
    core.Environment.local => injectable.Environment.dev,
    core.Environment.test => injectable.Environment.test,
  };

  injector.init(environment: injectableEnvironment);
}

/// Supplies dependencies injectable cannot construct on its own.
@injectable.module
abstract class NetworkModule {
  /// The app's HTTP client, pointed at the running flavor's endpoint.
  ///
  /// Deliberately parameterless: see the note on `configureInjection`.
  ///
  /// Pass `onUnauthorized:` here to route an expired session to sign-in from
  /// one place instead of from every caller.
  @injectable.lazySingleton
  core.ApiClient apiClient() => core.ApiClient(
        baseUrl: injector<core.BuildConfiguration>().baseEndpointUrl,
      );
}
