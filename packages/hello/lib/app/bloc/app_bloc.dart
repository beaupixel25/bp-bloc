import 'package:core/core.dart' hide Environment;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'app_bloc.freezed.dart';

/// {@template app_event}
/// Base type for all events consumed by the [AppBloc].
/// {@endtemplate}
@immutable
sealed class AppEvent {
  /// {@macro app_event}
  const AppEvent();
}

/// Dispatched once when the app starts, to load app-wide startup data.
@immutable
final class AppStarted extends AppEvent {
  /// Creates an [AppStarted] event.
  const AppStarted();
}

/// Dispatched to switch the app between light and dark themes.
@immutable
final class AppThemeChanged extends AppEvent {
  /// Creates an [AppThemeChanged] event.
  const AppThemeChanged(this.themeMode);

  /// The requested theme mode.
  final ThemeMode themeMode;
}

/// Dispatched to switch the app's active locale, or to revert to the
/// device's own locale when [locale] is `null`.
@immutable
final class AppLocaleChanged extends AppEvent {
  /// Creates an [AppLocaleChanged] event.
  const AppLocaleChanged(this.locale);

  /// The requested locale, or `null` to follow the device.
  final Locale? locale;
}

/// {@template app_state}
/// Global app state: the outcome of the startup load, plus the app-wide UI
/// preferences the app root feeds into core's `App`.
/// {@endtemplate}
@freezed
sealed class AppState with _$AppState {
  /// {@macro app_state}
  const factory AppState({
    /// Lifecycle of the startup load.
    @Default(BlocStatus.initial) BlocStatus status,

    /// The active theme mode. Follows the device until a settings screen
    /// overrides it.
    @Default(ThemeMode.system) ThemeMode themeMode,

    /// The active locale override, or `null` to follow the device.
    Locale? locale,

    /// The typed error from the last failed startup load, if any.
    AppException? failure,

    /// Whether a previous session can be restored. Set once by `start()`;
    /// the cold-start launch reads it to choose where to land.
    @Default(false) bool isSignedIn,
  }) = _AppState;

  const AppState._();
}

/// {@template app_bloc}
/// Global BLoC owning app-wide state.
///
/// Created once by the app root (`BlocProvider<AppBloc>`), so it outlives
/// every route. Page-level state belongs in that page's own bloc — put
/// something here only when more than one screen reads it.
/// {@endtemplate}
@injectable
class AppBloc extends Bloc<AppEvent, AppState> {
  /// {@macro app_bloc}
  AppBloc() : super(const AppState()) {
    on<AppStarted>(_onStarted);
    on<AppThemeChanged>(
      (event, emit) => emit(state.copyWith(themeMode: event.themeMode)),
    );
    on<AppLocaleChanged>(
      (event, emit) => emit(state.copyWith(locale: event.locale)),
    );
  }

  /// Convenience helper so callers can invoke `bloc.start()`.
  void start() => add(const AppStarted());

  /// Switches the app theme (called from a settings screen).
  void setThemeMode(ThemeMode mode) => add(AppThemeChanged(mode));

  /// Switches the app locale (called from a settings screen).
  void setLocale(Locale locale) => add(AppLocaleChanged(locale));

  Future<void> _onStarted(AppStarted event, Emitter<AppState> emit) async {
    emit(state.copyWith(status: BlocStatus.loading));

    await handleBlocAction(
      () async {
        // App-wide startup work goes here: inject the use cases this app
        // needs before its first frame (feature flags, session restore,
        // remote config), await them, and widen [AppState] with what they
        // return. Only an AppException lands in `onFailure`; anything else
        // escapes to the AppBlocObserver.
        final isSignedIn = await _restoreSession();
        emit(
          state.copyWith(status: BlocStatus.success, isSignedIn: isSignedIn),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(status: BlocStatus.failure, failure: failure),
      ),
    );
  }

  /// Whether a previous session can be restored.
  ///
  /// Always false today: the generated account store is in memory and does not
  /// survive a restart, so there is nothing to read. Replace this with your
  /// token store's check — the launch already branches on the result, and
  /// `test/app/view/launch_page_test.dart` covers both destinations.
  Future<bool> _restoreSession() async => false;
}
