import 'package:freezed_annotation/freezed_annotation.dart';

part 'build_configuration.freezed.dart';

/// Environment-specific build configuration for an app flavor.
@freezed
sealed class BuildConfiguration with _$BuildConfiguration {
  /// Creates a build configuration.
  const factory BuildConfiguration({
    required String appTitle,
    required String baseEndpointUrl,
    @Default('en') String defaultLanguageCode,
  }) = _BuildConfiguration;
}
