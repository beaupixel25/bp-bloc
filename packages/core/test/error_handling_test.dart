// The tests deliberately throw raw objects to exercise error mapping.
// ignore_for_file: only_throw_errors

import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
// core exports a `test` environment const; hide it so flutter_test's `test`
// function is unambiguous.
import 'package:core/core.dart' hide test;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _TestRepository extends BaseRepository {
  AppException mapError(Object error) =>
      handleException(error, StackTrace.current);

  Future<void> failWith(Object error) => guard<void>(() async => throw error);
}

class _ThrowingUseCase extends UseCase<void, void> {
  _ThrowingUseCase(this.error);

  final Object error;

  @override
  Future<void> call({void input}) async => throw error;
}

/// Captures both lanes so a test can tell a breadcrumb from a crash.
class _RecordingReporter extends ErrorReporter {
  final List<Object> crashes = [];
  final List<AppException> handled = [];
  final List<StackTrace?> handledFrom = [];
  final List<StackTrace?> invokedFrom = [];
  final List<StackTrace> traces = [];

  // One override, which is the point: `reportHandled` funnels in here, so
  // this records the lane the funnel actually chose rather than asserting on
  // a second method that could drift from it.
  @override
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    bool handled = false,
    StackTrace? handledAt,
    StackTrace? invokedAt,
  }) async {
    traces.add(stackTrace);
    if (!handled) {
      crashes.add(error);
      return;
    }
    this.handled.add(error as AppException);
    handledFrom.add(handledAt);
    invokedFrom.add(invokedAt);
  }
}

class _FakeMessages implements ErrorMessages {
  @override
  String get errorGeneric => 'generic';
  @override
  String get errorNetwork => 'network';
  @override
  String get errorSessionExpired => 'session';
  @override
  String get errorForbidden => 'forbidden';
  @override
  String get errorNotFound => 'notFound';
  @override
  String get errorValidation => 'validation';
  // Declared, not inherited: `implements` takes the interface, never the
  // implementation, even when the interface supplies a body.
  @override
  String? forCode(String code) => switch (code) {
        'CODED' => 'coded',
        _ => null,
      };
}

class _TestBloc extends Bloc<Object, int> {
  _TestBloc() : super(0);

  /// Returns the action's future without awaiting it — the shape that falls
  /// off an async stack trace, and so the one that proves `handledAt` is
  /// captured on the way in rather than in the catch.
  Future<void> invoke(Future<void> Function() action) =>
      handleBlocAction(action, onFailure: (_) {});
}

void main() {
  group('BaseRepository.handleException (data layer)', () {
    final repo = _TestRepository();

    test('maps SocketException -> NetworkException', () {
      expect(
        repo.mapError(const SocketException('down')),
        isA<NetworkException>(),
      );
    });

    test('maps TimeoutException -> NetworkException', () {
      expect(repo.mapError(TimeoutException('slow')), isA<NetworkException>());
    });

    test('maps FormatException -> ServerException', () {
      // Not ValidationException, deliberately. A FormatException here came from
      // decoding a payload, so the copy the user reads must be the generic one
      // — telling them to "check your input" about a response they cannot
      // influence is the defect this asserts against.
      final mapped = repo.mapError(const FormatException('bad'));
      expect(mapped, isA<ServerException>());
      expect(mapped.toUserMessage(_FakeMessages()), 'generic');
    });

    test('maps HttpException -> ServerException', () {
      expect(repo.mapError(const HttpException('500')), isA<ServerException>());
    });

    test('passes an existing AppException through unchanged', () {
      const original = UnauthorizedException();
      expect(repo.mapError(original), same(original));
    });

    test('falls back to UnknownException', () {
      expect(repo.mapError(Exception('?')), isA<UnknownException>());
    });
  });

  group('BaseRepository.guard (data layer)', () {
    final repo = _TestRepository();

    test('rethrows the mapped exception with a preserved stack trace', () {
      expect(
        () => repo.failWith(const SocketException('down')),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.stackTrace,
            'stackTrace',
            isNotNull,
          ),
        ),
      );
    });

    // `ConsoleErrorReporter.reportHandled` logs `handled: $error`, so the
    // breadcrumb is worth exactly as much as this string. Collapse it back to
    // the bare runtime type and every handled failure logs the same
    // unactionable `UnknownException` line.
    test('the mapped exception names its cause, for the breadcrumb', () {
      final mapped = repo.mapError(UnimplementedError());
      expect('$mapped', contains('UnknownException'));
      expect('$mapped', contains('UnimplementedError'));
    });
  });

  group('ConsoleErrorReporter.formatHandled', () {
    // Asserted on the string rather than on the log, because
    // `dart:developer`'s sink is not observable from a test — and the string
    // is the whole point of the breadcrumb.
    test('names the handling block, frame 0 and unfiltered', () {
      // `handled at:` is the code that handled the failure — the
      // `on AppException` block — so it is frame 0 of the trace captured
      // there, kept whatever package it lives in. Filtering `core` out of it
      // would step past the handler and blame its caller.
      final line = const ConsoleErrorReporter().formatHandled(
        const ServerException(code: '500'),
        handledAt: StackTrace.fromString(
          '#0      BlocErrorHandling.handleBlocAction '
          '(package:core/src/presentation/bloc/bloc_error_handling.dart:29:9)\n'
          '<asynchronous suspension>\n'
          '#1      LoginPage._submit '
          '(package:hello/features/onboarding/login_page.dart:88:5)',
        ),
      );

      expect(line, contains('handled at: BlocErrorHandling.handleBlocAction'));
      expect(line, isNot(contains('LoginPage._submit')));
    });

    test('names the throw site verbatim, even inside core', () {
      // The origin is frame 0 unfiltered: `ApiClient` throws from inside
      // `core`, and filtering that out would blame the caller instead.
      final line = const ConsoleErrorReporter().formatHandled(
        const ServerException(code: '500'),
        thrownAt: StackTrace.fromString(
          '#0      ApiClient._decode '
          '(package:core/src/data/services/api_client.dart:88:7)',
        ),
      );

      expect(line, contains('thrown at:  ApiClient._decode'));
    });

    test('reportHandled funnels into report as the handled lane', () async {
      // The contract an implementation depends on: it writes `report` only,
      // and `handled` is what tells the two lanes apart. Asserted on a
      // reporter that overrides nothing else, so a `reportHandled` that
      // stopped delegating would fail here rather than silently bypass
      // whatever a vendor subclass does in `report`.
      final reporter = _RecordingReporter();
      final thrown =
          StackTrace.fromString('#0      Repo.get (package:hello/r.dart:1:1)');
      final at =
          StackTrace.fromString('#0      Vm.load (package:hello/v.dart:2:2)');

      await reporter.reportHandled(
        ServerException(code: '500', stackTrace: thrown),
        handledAt: at,
      );

      expect(reporter.handled.single.code, '500');
      expect(reporter.crashes, isEmpty);
      expect(reporter.handledFrom.single, same(at));
      // The throw site rides through as `report`'s positional stack trace.
      expect(reporter.traces.single, same(thrown));
    });

    test('an exception with no trace funnels through as StackTrace.empty',
        () async {
      final reporter = _RecordingReporter();

      await reporter.reportHandled(const ServerException(code: '500'));

      expect(reporter.traces.single, same(StackTrace.empty));
    });

    test('invoked at names the caller, skipping the plumbing', () {
      // The one filtered frame. Whoever captured `invokedAt` is itself the
      // top of that trace, so frame 0 is always the helper — the caller sits
      // under it, and under the framework that called the helper.
      final line = const ConsoleErrorReporter().formatHandled(
        const ServerException(code: '500'),
        invokedAt: StackTrace.fromString(
          '#0      Command.run '
          '(package:core/src/presentation/listenable/command.dart:47:29)\n'
          '#1      Command0.execute '
          '(package:core/src/presentation/listenable/command.dart:96:29)\n'
          '#2      SignupViewModel.submit '
          '(package:hello/features/onboarding/signup_view_model.dart:29:14)',
        ),
      );

      expect(line, contains('invoked at: SignupViewModel.submit'));
      expect(line, isNot(contains('Command0.execute')));
    });

    test('the frame lines are a tree under the header', () {
      // Markers rather than an indent: `dart:developer` hands the console one
      // multi-line string, a console may strip leading whitespace, and
      // anything else logging concurrently interleaves the lines.
      final line = const ConsoleErrorReporter(colored: false).formatHandled(
        const ServerException(code: '500'),
        thrownAt:
            StackTrace.fromString('#0      A.b (package:hello/a.dart:1:1)'),
        handledAt:
            StackTrace.fromString('#0      C.d (package:hello/c.dart:2:2)'),
        invokedAt:
            StackTrace.fromString('#0      E.f (package:hello/e.dart:3:3)'),
      );
      final lines = line.split('\n');

      expect(lines.first, startsWith('handled: '));
      expect(lines[1], startsWith('├─ thrown at:'));
      expect(lines[2], startsWith('├─ handled at:'));
      // The last row closes the group, whichever row that turns out to be.
      expect(lines[3], startsWith('└─ invoked at:'));
    });

    test('colour is opt-out and leaves no escape codes behind', () {
      // Release logs go to a file or a crash service, and a debug build on a
      // device logs to logcat — escape codes are noise in both, so the
      // switch has to actually work.
      const failure = ServerException(code: '500');
      final at = StackTrace.fromString('#0      C.d (package:hello/c.dart:2)');

      final plain = const ConsoleErrorReporter(colored: false)
          .formatHandled(failure, handledAt: at);
      final painted = const ConsoleErrorReporter()
          .formatHandled(failure, handledAt: at);

      expect(plain, isNot(contains('')));
      expect(painted, contains('[37m'));
      // Every painted line closes its colour run, so a truncated log cannot
      // bleed into whatever prints next.
      expect(painted, endsWith('[0m'));
    });

    test('degrades to the error alone when neither trace is available', () {
      final line = const ConsoleErrorReporter()
          .formatHandled(const ServerException(code: '500'));

      expect(line, startsWith('handled: ServerException'));
      expect(line, isNot(contains('thrown at')));
      expect(line, isNot(contains('handled at')));
    });
  });

  group('UseCase.execute (domain layer)', () {
    test('rethrows an AppException as-is', () {
      expect(
        _ThrowingUseCase(const ForbiddenException()).execute(),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('wraps a non-AppException in UnknownException', () {
      expect(
        _ThrowingUseCase(const FormatException('x')).execute(),
        throwsA(isA<UnknownException>()),
      );
    });
  });

  group('AppExceptionL10n.toUserMessage (presentation layer)', () {
    final messages = _FakeMessages();

    test('maps typed exceptions to their localized strings', () {
      expect(const NetworkException().toUserMessage(messages), 'network');
      expect(const UnauthorizedException().toUserMessage(messages), 'session');
      expect(const ForbiddenException().toUserMessage(messages), 'forbidden');
      expect(const NotFoundException().toUserMessage(messages), 'notFound');
      expect(const ValidationException().toUserMessage(messages), 'validation');
      expect(const ServerException().toUserMessage(messages), 'generic');
      expect(const UnknownException().toUserMessage(messages), 'generic');
    });

    test('shows a DisplayableException message directly', () {
      expect(
        const DisplayableException(message: 'hi').toUserMessage(messages),
        'hi',
      );
    });

    test('a recognised backend code beats the exception type', () {
      // The whole point of the code channel: a coded failure gets copy about
      // *that* failure, not the generic sentence for its type.
      expect(
        const ValidationException(code: 'CODED').toUserMessage(messages),
        'coded',
      );
    });

    test('an unknown or absent code falls back to the type', () {
      expect(
        const ValidationException(code: 'NOPE').toUserMessage(messages),
        'validation',
      );
      expect(const ValidationException().toUserMessage(messages), 'validation');
    });
  });

  group('BlocErrorHandling.handleBlocAction (presentation layer)', () {
    test('routes an AppException to onFailure', () async {
      final bloc = _TestBloc();
      AppException? captured;
      await bloc.handleBlocAction(
        () async => throw const UnauthorizedException(),
        onFailure: (failure) => captured = failure,
      );
      expect(captured, isA<UnauthorizedException>());
      await bloc.close();
    });

    test('breadcrumbs the handled failure to the registered sink', () async {
      // Handled is not the same as invisible: the user saw a sentence, and
      // the crash sink still has to know it happened. The sink is whatever
      // `bootstrap` registered — resolved, never held by the bloc.
      final reporter = _RecordingReporter();
      GetIt.instance.registerSingleton<ErrorReporter>(reporter);
      addTearDown(GetIt.instance.reset);

      final bloc = _TestBloc();
      await bloc.handleBlocAction(
        () async => throw const ServerException(code: '500'),
        onFailure: (_) {},
      );
      expect(reporter.handled.single.code, '500');
      expect(reporter.crashes, isEmpty);
      // The second half of the breadcrumb: where the failure was absorbed.
      // Without this the log says what broke but not what is already
      // catching it, which is the half that says whether to act.
      expect('${reporter.handledFrom.single}', contains('handleBlocAction'));
      await bloc.close();
    });

    test('handledAt points at the catch block, not the caller', () async {
      // The capture belongs in the `on AppException` block: frame 0 is then
      // the code that handled the failure. `_TestBloc.invoke` only starts
      // the action, so it must not be what the breadcrumb names.
      final reporter = _RecordingReporter();
      GetIt.instance.registerSingleton<ErrorReporter>(reporter);
      addTearDown(GetIt.instance.reset);

      final bloc = _TestBloc();
      await bloc.invoke(
        () async => throw const ServerException(code: '500'),
      );

      final handled =
          '${reporter.handledFrom.single}'.split('\n').first;
      expect(handled, contains('handleBlocAction'));
      expect(handled, isNot(contains('_TestBloc.invoke')));

      // `invoked at:` is the other question: what set the action off. It is
      // captured before the await, so the caller survives even though it
      // never awaited and is therefore absent from the catch-time trace.
      expect(
        '${reporter.invokedFrom.single}',
        contains('_TestBloc.invoke'),
      );
      await bloc.close();
    });

    test('still routes the failure with no reporter registered', () async {
      // `core`'s own tests and the component demo never run `bootstrap`. An
      // unguarded lookup would throw from inside the catch, turning a handled
      // failure into a crash.
      expect(GetIt.instance.isRegistered<ErrorReporter>(), isFalse);

      final bloc = _TestBloc();
      AppException? captured;
      await bloc.handleBlocAction(
        () async => throw const ServerException(code: '500'),
        onFailure: (failure) => captured = failure,
      );
      expect(captured?.code, '500');
      await bloc.close();
    });
  });
}
