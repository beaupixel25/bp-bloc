import 'dart:async';
import 'dart:convert';

// core exports a `test` environment const; hide it so flutter_test's
// `test` is unambiguous.
import 'package:core/core.dart' hide test;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Builds a client whose every request answers with [body] and [status].
ApiClient _client(
  String body,
  int status, {
  String? reason,
  void Function()? onUnauthorized,
}) =>
    ApiClient(
      baseUrl: 'https://api.example.com',
      onUnauthorized: onUnauthorized,
      client: MockClient(
        (_) async => http.Response(body, status, reasonPhrase: reason),
      ),
    );

Future<AppException> _failure(ApiClient client) async {
  try {
    await client.get('/thing');
  } on AppException catch (error) {
    return error;
  }
  fail('expected an AppException');
}

void main() {
  group('the backend code reaches AppException.code', () {
    test('nested error.code wins', () async {
      final error =
          await _failure(_client('{"error":{"code":"EMAIL_TAKEN"}}', 409));
      expect(error.code, 'EMAIL_TAKEN');
    });

    test('a flat code is read', () async {
      final error = await _failure(_client('{"code":"BAD_CREDS"}', 401));
      expect(error, isA<UnauthorizedException>());
      expect(error.code, 'BAD_CREDS');
    });

    test('error_code is the last key tried', () async {
      final error = await _failure(_client('{"error_code":"X1"}', 422));
      expect(error, isA<ValidationException>());
      expect(error.code, 'X1');
    });

    test('a numeric code is coerced to a String', () async {
      expect((await _failure(_client('{"code":4091}', 409))).code, '4091');
    });

    test('an empty or non-scalar code is treated as absent', () async {
      expect((await _failure(_client('{"code":""}', 404))).code, '404');
      expect((await _failure(_client('{"code":{"a":1}}', 404))).code, '404');
    });
  });

  group('an untrustworthy error body falls back to the status', () {
    test('an HTML 500 page stays a ServerException', () async {
      // The trap this guards: a bare jsonDecode throws FormatException here,
      // taking the status and any code the backend sent with it. `guard` would
      // still type the escape as a ServerException, so the user reads the right
      // sentence either way — the `code: '500'` asserted below is what dies.
      final error = await _failure(_client('<html>Bad Gateway</html>', 500));
      expect(error, isA<ServerException>());
      expect(error.code, '500');
    });

    test('an empty body falls back', () async {
      expect((await _failure(_client('', 401))).code, '401');
    });

    test('a JSON array falls back', () async {
      expect((await _failure(_client('[1,2,3]', 403))).code, '403');
    });
  });

  group('the message is developer-facing and bounded', () {
    test('it carries the status alongside the backend message', () async {
      final error =
          await _failure(_client('{"code":"X","message":"nope"}', 422));
      expect(error.message, 'HTTP 422: nope');
    });

    test('it falls back to the status and reason phrase', () async {
      final error = await _failure(_client('', 503, reason: 'Unavailable'));
      expect(error.message, 'HTTP 503 Unavailable');
    });

    test('detail and a string error field are both read', () async {
      expect(
        (await _failure(_client('{"detail":"d"}', 400))).message,
        'HTTP 400: d',
      );
      expect(
        (await _failure(_client('{"error":"plain"}', 400))).message,
        'HTTP 400: plain',
      );
    });

    test('a non-ASCII message survives a missing charset', () async {
      // package:http falls back to latin1 when the server omits a charset,
      // so reading `response.body` would hand the crash reporter mojibake.
      final client = ApiClient(
        baseUrl: 'https://api.example.com',
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode('{"message":"contraseña inválida"}'),
            422,
          ),
        ),
      );
      expect((await _failure(client)).message, 'HTTP 422: contraseña inválida');
    });

    test('an over-long message is capped', () async {
      final error = await _failure(
        _client('{"message":"${'x' * 5000}"}', 500),
      );
      expect(error.message!.length, lessThan(260));
    });
  });

  group('the rest of the contract is unchanged', () {
    test('onUnauthorized fires on 401 and nothing else', () async {
      var fired = 0;
      await _failure(_client('', 401, onUnauthorized: () => fired++));
      expect(fired, 1);
      await _failure(_client('', 403, onUnauthorized: () => fired++));
      expect(fired, 1);
    });

    test('a 2xx body that will not parse still throws FormatException',
        () async {
      // Left for BaseRepository.guard, deliberately: mapping it here as well
      // would put the translation in two places that could disagree.
      await expectLater(
        _client('<html>', 200).get('/thing'),
        throwsA(isA<FormatException>()),
      );
    });

    test('an empty 2xx body decodes to an empty map', () async {
      expect(await _client('', 204).get('/thing'), <String, dynamic>{});
    });

    test('a request that outruns the deadline throws TimeoutException',
        () async {
      // The deadline is what makes handleException's TimeoutException branch
      // reachable at all: package:http imposes none of its own, so without it a
      // hung socket never resolves and the loading state stays on screen.
      // Left to propagate here on purpose — `guard` is the only place that
      // turns it into a NetworkException.
      final slow = ApiClient(
        baseUrl: 'https://api.example.com',
        timeout: const Duration(milliseconds: 20),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        slow.get('/thing'),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
