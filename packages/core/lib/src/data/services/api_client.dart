import 'dart:convert';

import 'package:core/src/domain/exceptions/app_exception.dart';
import 'package:http/http.dart' as http;

/// The `code`/`message` pair lifted out of a non-2xx response body.
///
/// Read defensively on purpose: an error response is the least trustworthy
/// thing a server sends — HTML error pages, empty bodies and proxy output all
/// arrive here. Anything that does not parse falls back to the status, so a
/// malformed error body can never be *more* fatal than the error it describes.
class _ApiError {
  const _ApiError({required this.code, this.message});

  /// Reads [response]'s body, falling back to the status at every step.
  factory _ApiError.from(http.Response response) {
    final status = response.statusCode;
    final fallback = 'HTTP $status ${response.reasonPhrase ?? ''}'.trim();
    Object? body;
    try {
      // Decoded from bodyBytes rather than `body`: package:http falls back to
      // latin1 when the server omits a charset, so a non-ASCII backend message
      // would reach the crash reporter as mojibake.
      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (text.isEmpty) return _ApiError(code: '$status', message: fallback);
      body = jsonDecode(text);
    } on FormatException {
      // The whole reason this is wrapped: a bare jsonDecode on an HTML 500 page
      // throws, and the status — plus any code the backend did send — dies with
      // it. `guard` would still type the escape as a ServerException, so the
      // sentence survives; `code: '500'` does not, and with it goes every way
      // of telling one outage from another in the crash reporter.
      return _ApiError(code: '$status', message: fallback);
    }
    if (body is! Map<String, dynamic>) {
      return _ApiError(code: '$status', message: fallback);
    }
    final nested = body['error'];
    final nestedMap = nested is Map<String, dynamic> ? nested : null;
    final code = _string(nestedMap?['code']) ??
        _string(body['code']) ??
        _string(body['error_code']) ??
        '$status';
    final detail = _string(nestedMap?['message']) ??
        _string(body['message']) ??
        _string(body['detail']) ??
        (nested is String ? _string(nested) : null);
    return _ApiError(
      code: code,
      message: detail == null ? fallback : 'HTTP $status: ${_cap(detail)}',
    );
  }

  /// The backend's machine-readable code, or the HTTP status as a fallback.
  final String code;

  /// Developer-facing detail for logs. Never rendered to a user verbatim.
  final String? message;

  /// Accepts a String or a num; anything else, or an empty string, is absent.
  static String? _string(Object? value) {
    if (value is String) return value.isEmpty ? null : value;
    if (value is num) return value.toString();
    return null;
  }

  /// Caps a backend message: an HTML error page is a valid non-2xx body, and
  /// uncapped it would become the crash reporter's issue title.
  static String _cap(String value) =>
      value.length <= 200 ? value : '${value.substring(0, 199)}…';
}

/// Thin wrapper over `package:http` that speaks JSON and throws `core`'s
/// typed exceptions.
///
/// It maps **status codes** to the exception vocabulary and lifts the
/// backend's own error code into `AppException.code`, which is what lets a
/// 409 "email already registered" read differently from a 422 "password too
/// weak" even though both are a `ValidationException`.
///
/// Transport failures (`SocketException`, `TimeoutException`) and a malformed
/// *success* body (`FormatException`) are left to propagate, because
/// `BaseRepository.guard` already maps exactly those — mapping them twice
/// would put the translation in two places that could disagree.
///
/// The injectable variants register it from a `@module` in `inject.dart`
/// rather than by annotation, because its base URL comes from
/// `BuildConfiguration`, which is registered by hand before `injector.init()`
/// and so is invisible to injectable's codegen. The Riverpod variant supplies
/// it from `apiClientProvider`.
class ApiClient {
  /// Creates a client for [baseUrl].
  ///
  /// [client] is the test seam: pass a `MockClient` to drive a repository
  /// test without a socket.
  ///
  /// [onUnauthorized] fires when the server answers 401, so an app can route
  /// to sign-in from one place rather than from every caller. It runs before
  /// the exception is thrown.
  ///
  /// [timeout] bounds every request. `package:http` imposes none of its own, so
  /// without this a hung socket never resolves: the loading state stays on
  /// screen forever and `BaseRepository.handleException`'s `TimeoutException`
  /// branch is unreachable code. Override it per flavor where the client is
  /// built — `apiClientProvider` in the Riverpod variant, the `@module` in
  /// `inject.dart` in the injectable ones.
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  /// Root of every request this client makes, e.g. `https://api.example.com`.
  final String baseUrl;

  /// Called when a response comes back 401, before the exception is thrown.
  final void Function()? onUnauthorized;

  /// How long a single request may take before it throws a `TimeoutException`.
  final Duration timeout;

  final http.Client _client;

  /// GETs [path] and decodes a JSON object.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? query,
  }) async =>
      _send(_client.get(_uri(path, query), headers: _headers(headers)));

  /// POSTs [body] as JSON to [path] and decodes a JSON object.
  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async =>
      _send(
        _client.post(
          _uri(path, null),
          headers: _headers(headers),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  /// PUTs [body] as JSON to [path] and decodes a JSON object.
  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async =>
      _send(
        _client.put(
          _uri(path, null),
          headers: _headers(headers),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  /// DELETEs [path] and decodes a JSON object.
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
  }) async =>
      _send(_client.delete(_uri(path, null), headers: _headers(headers)));

  /// Releases the underlying connection pool.
  void close() => _client.close();

  /// Awaits [request] under [timeout], then decodes it.
  ///
  /// The deadline lives here rather than on each verb, so there is a single
  /// place it can be wrong. Note what it does *not* do: `Future.timeout`
  /// abandons the await, it does not abort the socket — the request runs on
  /// until the OS gives up, so this bounds how long a caller waits, not what
  /// the process holds. Real cancellation needs a client that supports it.
  ///
  /// The `TimeoutException` is left to propagate, like every other transport
  /// failure, so `BaseRepository.guard` stays the only place that names it.
  Future<Map<String, dynamic>> _send(Future<http.Response> request) async =>
      _decode(await request.timeout(timeout));

  Uri _uri(String path, Map<String, String>? query) {
    final base = Uri.parse(baseUrl);
    final joined = path.startsWith('/') ? path : '/$path';
    return base.replace(
      path: '${base.path}$joined'.replaceAll('//', '/'),
      queryParameters: query,
    );
  }

  Map<String, String> _headers(Map<String, String>? extra) => {
        'content-type': 'application/json',
        'accept': 'application/json',
        ...?extra,
      };

  /// Turns a response into a decoded body or a typed exception.
  ///
  /// A non-2xx status is an *expected* failure, so it becomes an
  /// [AppException] here, carrying the backend's own code when the body
  /// declares one. A *success* body that will not parse is left to
  /// `FormatException`, which `BaseRepository.guard` maps for us.
  Map<String, dynamic> _decode(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return const <String, dynamic>{};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final error = _ApiError.from(response);
    if (status == 401) onUnauthorized?.call();
    throw switch (status) {
      401 => UnauthorizedException(message: error.message, code: error.code),
      403 => ForbiddenException(message: error.message, code: error.code),
      404 => NotFoundException(message: error.message, code: error.code),
      400 || 422 =>
        ValidationException(message: error.message, code: error.code),
      _ when status >= 500 =>
        ServerException(message: error.message, code: error.code),
      _ => UnknownException(message: error.message, code: error.code),
    };
  }
}
