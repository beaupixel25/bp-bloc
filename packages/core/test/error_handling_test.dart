// The tests deliberately throw raw objects to exercise error mapping.
// ignore_for_file: only_throw_errors

import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
// core exports a `test` environment const; hide it so flutter_test's `test`
// function is unambiguous.
import 'package:core/core.dart' hide test;
import 'package:flutter_test/flutter_test.dart';

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
class _RecordingReporter implements ErrorReporter {
  final List<Object> crashes = [];
  final List<AppException> handled = [];

  @override
  Future<void> report(Object error, StackTrace stackTrace) async =>
      crashes.add(error);

  @override
  Future<void> reportHandled(AppException error) async => handled.add(error);
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

    test('breadcrumbs the handled failure to the sink', () async {
      // Handled is not the same as invisible: the user saw a sentence, and
      // the crash sink still has to know it happened.
      final reporter = _RecordingReporter();
      appErrorReporter = reporter;
      addTearDown(() => appErrorReporter = const NoopErrorReporter());

      final bloc = _TestBloc();
      await bloc.handleBlocAction(
        () async => throw const ServerException(code: '500'),
        onFailure: (_) {},
      );
      expect(reporter.handled.single.code, '500');
      expect(reporter.crashes, isEmpty);
      await bloc.close();
    });
  });
}
