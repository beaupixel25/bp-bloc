// Compiles the core design-system theme through the Flutter front-end and
// verifies its ThemeExtensions are registered on both brightnesses.
//
// `core` exports a `test` environment const; hide it so flutter_test's `test`
// is unambiguous.
import 'package:core/core.dart' hide test;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('core theme builds and registers design-system extensions',
      (tester) async {
    late final ThemeData light;
    late final ThemeData dark;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            // AppThemeData.fallback reads MediaQuery, so build it under one.
            final theme = AppThemeData.fallback(context);
            light = theme.lightTheme;
            dark = theme.darkTheme;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // The design-system ThemeExtensions must be registered on both themes —
    // this exercises the themeExtensions list that app_theme.dart builds.
    expect(light.extension<ColorExtension>(), isNotNull);
    expect(light.extension<DimensionExtension>(), isNotNull);
    expect(dark.extension<ColorExtension>(), isNotNull);
    expect(dark.extension<DimensionExtension>(), isNotNull);

    // Each declared family must survive into the textTheme.
    expect(light.textTheme.displayLarge?.fontFamily, 'packages/core/Basis Grotesque');
    expect(light.textTheme.titleLarge?.fontFamily, 'packages/core/Neue Haas Grotesk Display');
    expect(light.textTheme.labelSmall?.fontFamily, 'packages/core/Basis Grotesque Mono');
  });
}
