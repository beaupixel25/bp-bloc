import 'package:core/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Root widget wrapping [BaseApp] with app-wide theming and overlays.
class App extends StatefulWidget {
  /// Creates the app root.
  const App({
    required this.router,
    required this.appTitle,
    this.theme,
    this.supportedLocales = const <Locale>[
      Locale('en', 'US'),
    ],
    this.locale,
    this.appLocalizationDelegate,
    super.key,
  });

  /// The router driving navigation.
  final GoRouter router;

  /// The app title.
  final String appTitle;

  /// Theme override; falls back to the inherited [AppTheme].
  final AppThemeData? theme;

  /// Locales the app supports.
  final List<Locale> supportedLocales;

  /// Explicit locale override, or `null` to follow the device.
  ///
  /// Driven by the app-level state holder so a settings screen can switch
  /// languages live.
  final Locale? locale;

  /// The app's generated localizations delegate, if any.
  final LocalizationsDelegate<dynamic>? appLocalizationDelegate;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late AppThemeData _theme;

  @override
  Widget build(BuildContext context) {
    // The theme fallback reads MediaQuery, which doesn't exist when this
    // widget is the root passed to runApp — provide one from the view.
    if (MediaQuery.maybeOf(context) == null) {
      return MediaQuery.fromView(
        view: View.of(context),
        child: Builder(builder: _buildApp),
      );
    }

    return _buildApp(context);
  }

  Widget _buildApp(BuildContext context) {
    _theme = widget.theme ?? AppTheme.of(context);

    return AppTheme(
      data: _theme,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: _theme.textScaler,
            ),
            child: BaseApp(
              goRouter: widget.router,
              appTitle: widget.appTitle,
              supportedLocales: widget.supportedLocales,
              locale: widget.locale,
              appLocalizationDelegate: widget.appLocalizationDelegate,
            ),
          ),
          // Add app-wide overlay components here (alerts, toasts, ...) as
          // siblings of the MaterialApp, each wrapped in its own
          // MediaQuery/Theme so they can respond to platform brightness
          // and metrics changes independently.
        ],
      ),
    );
  }
}

/// The root [MaterialApp] configured with routing, theming, localization,
/// and responsive breakpoints.
class BaseApp extends StatelessWidget {
  /// Creates the base app.
  const BaseApp({
    required this.goRouter,
    required this.appTitle,
    super.key,
    this.theme,
    this.supportedLocales = const <Locale>[
      Locale('en', 'US'),
    ],
    this.locale,
    this.appLocalizationDelegate,
  });

  /// The router driving navigation.
  final GoRouter goRouter;

  /// The app title.
  final String appTitle;

  /// Locales the app supports.
  final List<Locale> supportedLocales;

  /// Explicit locale override, or `null` to follow the device.
  final Locale? locale;

  /// Theme override; falls back to [AppTheme.of].
  final AppThemeData? theme;

  /// The app's generated localizations delegate, if any.
  final LocalizationsDelegate<dynamic>? appLocalizationDelegate;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? AppTheme.of(context);

    return MaterialApp.router(
      routerDelegate: goRouter.routerDelegate,
      routeInformationProvider: goRouter.routeInformationProvider,
      routeInformationParser: goRouter.routeInformationParser,
      title: appTitle,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.themeMode,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        ?appLocalizationDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}
