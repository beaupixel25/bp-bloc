import 'package:core/core.dart' show Environment;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hello/app/bloc/app_bloc.dart';
import 'package:hello/app/view/app.dart';
import 'package:hello/app/view/settings_page.dart';
import 'package:hello/inject.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await configureInjection(Environment.test);
    await tester.pumpWidget(const HelloApp());
    await tester.pumpAndSettle();
  }

  /// Past the launch and the sign-in gate in one step: launch_page_test.dart
  /// pins both already, so this file starts at the settings tab.
  Future<void> goToSettings(WidgetTester tester) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/settings');
    await tester.pumpAndSettle();
  }
  AppState appState(WidgetTester tester) =>
      BlocProvider.of<AppBloc>(tester.element(find.byType(SettingsPage)))
          .state;

  ThemeMode themeMode(WidgetTester tester) => appState(tester).themeMode;

  Locale? locale(WidgetTester tester) => appState(tester).locale;

  // By value, not by label: "Follow device" captions both the `system` theme
  // mode and the null locale, so find.text matches two widgets and throws.
  Finder themeTile(ThemeMode mode) => find.byWidgetPredicate(
        (widget) => widget is RadioListTile<ThemeMode> && widget.value == mode,
      );

  Finder localeTile({required bool followDevice}) => find.byWidgetPredicate(
        (widget) =>
            widget is RadioListTile<Locale?> &&
            (widget.value == null) == followDevice,
      );

  group('SettingsPage reaches the app-wide state holder', () {
    testWidgets('the theme switch does', (tester) async {
      await pumpApp(tester);
      await goToSettings(tester);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(themeMode(tester), isNot(ThemeMode.dark));

      await tester.tap(themeTile(ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(themeMode(tester), ThemeMode.dark);
    });

    testWidgets('the locale switch does', (tester) async {
      await pumpApp(tester);
      await goToSettings(tester);

      // Whichever real locale the app supports first — the test does not
      // care which, only that picking one arrives at the holder.
      final finder = localeTile(followDevice: false).first;
      final chosen = tester.widget<RadioListTile<Locale?>>(finder).value;
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(locale(tester), chosen);
    });

    testWidgets('follow-device clears the explicit locale', (tester) async {
      // Why the locale is nullable at all: "follow the device" is the
      // ABSENCE of a choice, not another choice. Riverpod spells it
      // useDeviceLocale() beside setLocale; BLoC widens AppLocaleChanged to
      // carry a Locale?. Either way the holder must end up with null.
      await pumpApp(tester);
      await goToSettings(tester);

      await tester.tap(localeTile(followDevice: false).first);
      await tester.pumpAndSettle();
      expect(locale(tester), isNotNull);

      await tester.tap(localeTile(followDevice: true));
      await tester.pumpAndSettle();
      expect(locale(tester), isNull);
    });
  });
}
