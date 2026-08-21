import 'package:core/core.dart' show App, AppThemeData, BuildConfiguration;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hello/app/bloc/app_bloc.dart';
import 'package:hello/features/onboarding/presentation/state/credential_draft_cubit.dart';
import 'package:hello/inject.dart';
import 'package:hello/l10n/l10n.dart' show AppLocalizations;
import 'package:hello/routing/routes.dart';

/// Root widget for the hello app, wiring its routes into core's [App].
class HelloApp extends StatefulWidget {
  /// Creates the app.
  const HelloApp({super.key});

  @override
  State<HelloApp> createState() => _HelloAppState();
}

class _HelloAppState extends State<HelloApp> {
  late final GoRouter _router;
  late final GlobalKey<NavigatorState> _navigatorKey;

  @override
  void initState() {
    _navigatorKey = GlobalKey<NavigatorState>();
    _router = GoRouter(
      initialLocation: '/',
      routes: appRoutes,
      navigatorKey: _navigatorKey,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<AppBloc>(
        create: (_) => injector<AppBloc>()..start(),
        // The credential draft is provided here too, above the router, so
        // both onboarding forms see the same instance rather than a fresh
        // one on every visit — see CredentialDraftCubit for why.
        //
        // `.value`, not `create:`, and the difference is not cosmetic:
        // `create:` makes BlocProvider the owner and closes the cubit when
        // this widget unmounts. AppBloc above is `@injectable`, so `create:`
        // is right there — the injector hands out a fresh one each time. The
        // draft is `@lazySingleton`: the injector keeps handing out the same
        // instance, so closing it here leaves every later resolution holding
        // a closed cubit that throws on its first emit. get_it owns it;
        // `injector.reset()` is what disposes it.
        child: BlocProvider<CredentialDraftCubit>.value(
          value: injector<CredentialDraftCubit>(),
          // AppThemeData.fallback reads MediaQuery, which doesn't exist at
          // the root passed to runApp — provide one from the view before
          // building the theme.
          child: MediaQuery.fromView(
            view: View.of(context),
            child: Builder(
              builder: (context) => BlocBuilder<AppBloc, AppState>(
                builder: (context, state) => App(
                  // Theme mode and locale come from the app-wide state
                  // holder, so a settings screen can switch both live.
                  // Layer app branding on the design-system defaults by
                  // passing `extensions:` here.
                  theme: AppThemeData.fallback(
                    context,
                    themeMode: state.themeMode,
                  ),
                  locale: state.locale,
                  router: _router,
                  appTitle: injector<BuildConfiguration>().appTitle,
                  appLocalizationDelegate: AppLocalizations.delegate,
                  supportedLocales: AppLocalizations.supportedLocales,
                ),
              ),
            ),
          ),
        ),
      );
}
