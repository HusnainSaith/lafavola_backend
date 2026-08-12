import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_favola/core/session/customer_session_controller.dart';

const customerApiBaseUrl = String.fromEnvironment('LA_FAVOLA_API_BASE_URL');

final customerApiClientProvider = Provider<CustomerApiClient>((ref) {
  final session = ref.read(customerSessionProvider.notifier);
  return CustomerApiClient(
    baseUri: CustomerApiClient.environmentBaseUri(),
    accessToken: () => session.accessToken,
    refreshSession: session.refreshSingleFlight,
  );
});

final class CustomerApiException implements Exception {
  const CustomerApiException({
    required this.kind,
    required this.message,
    this.retryable = false,
    this.correlationId,
  });
  final String kind;
  final String message;
  final bool retryable;
  final String? correlationId;
}

class CustomerApiClient {
  CustomerApiClient({
    required this.baseUri,
    required this.accessToken,
    required this.refreshSession,
    HttpClient? httpClient,
  }) : _http = httpClient ?? HttpClient();

  final Uri baseUri;
  final String? Function() accessToken;
  final Future<Object?> Function() refreshSession;
  final HttpClient _http;

  static Uri environmentBaseUri() {
    final configured = customerApiBaseUrl.trim();
    if (configured.isEmpty && !kDebugMode) {
      throw StateError(
        'LA_FAVOLA_API_BASE_URL is required for release builds.',
      );
    }
    final value = configured.isNotEmpty ? configured : 'http://10.0.2.2:3001';
    final uri = Uri.parse(value);
    if (!uri.hasAuthority ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        (!kDebugMode && uri.scheme != 'https') ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw StateError('LA_FAVOLA_API_BASE_URL is not an approved API origin.');
    }
    return uri;
  }

  Future<Object?> get(String path, {Map<String, Object?> query = const {}}) =>
      _send('GET', path, query: query);
  Future<Object?> post(String path, {Object? body}) =>
      _send('POST', path, body: body);
  Future<Object?> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);
  Future<Object?> delete(
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
  }) => _send('DELETE', path, query: query, body: body);

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
    bool retried = false,
  }) async {
    final uri = baseUri
        .resolve(path)
        .replace(
          queryParameters:
              query.isEmpty
                  ? null
                  : query.map((key, value) => MapEntry(key, value.toString())),
        );
    try {
      final request = await _http
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 12));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final token = accessToken();
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final text = await utf8.decoder.bind(response).join();
      final decoded = text.trim().isEmpty ? null : jsonDecode(text);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return unwrapCustomerApiResponse(decoded);
      }
      if (response.statusCode == 401 && !retried) {
        final refreshed = await refreshSession();
        if (refreshed != null) {
          return _send(method, path, query: query, body: body, retried: true);
        }
      }
      throw _error(response.statusCode, decoded, response.headers);
    } on CustomerApiException {
      rethrow;
    } on TimeoutException {
      throw const CustomerApiException(
        kind: 'timeout',
        message: 'The request timed out. Try again safely.',
        retryable: true,
      );
    } on SocketException {
      throw const CustomerApiException(
        kind: 'offline',
        message: 'The service is unreachable. Check your connection.',
        retryable: true,
      );
    } on FormatException {
      throw const CustomerApiException(
        kind: 'malformed',
        message: 'The service returned an unexpected response.',
        retryable: true,
      );
    }
  }

  CustomerApiException _error(
    int status,
    Object? decoded,
    HttpHeaders headers,
  ) {
    final root = decoded is Map ? decoded : const {};
    final error = root['error'] is Map ? root['error'] as Map : root;
    final code = error['code']?.toString() ?? 'HTTP_$status';
    final message = error['message']?.toString();
    final minimum = RegExp(
      r'Minimum order amount is (\d+) minor units',
    ).firstMatch(message ?? '');
    final safe = switch (status) {
      401 => 'Sign in to continue.',
      403 => 'You do not have access to this action.',
      404 => 'This content is no longer available.',
      409 => 'This changed elsewhere. Refresh and try again.',
      429 => 'Too many requests. Please wait and try again.',
      >= 500 => 'The service is temporarily unavailable.',
      _ when minimum != null =>
        'Ordine minimo €${(int.parse(minimum.group(1)!) / 100).toStringAsFixed(2).replaceAll('.', ',')}. Aggiungi altri articoli e riprova.',
      _ => message ?? 'The request could not be completed.',
    };
    return CustomerApiException(
      kind: code,
      message: safe,
      retryable: status == 408 || status == 429 || status >= 500,
      correlationId:
          error['correlationId']?.toString() ??
          headers.value('x-correlation-id'),
    );
  }
}

Object? unwrapCustomerApiResponse(Object? value) {
  final root = objectMap(value);
  if (root['success'] == true && root.containsKey('data')) {
    return root['data'];
  }
  return value;
}

Map<String, Object?> objectMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return const {};
}

List<Object?> objectItems(Object? value) {
  if (value is List) return value.cast<Object?>();
  final map = objectMap(value);
  for (final key in const [
    'items',
    'data',
    'results',
    'notifications',
    'tickets',
  ]) {
    final candidate = map[key];
    if (candidate is List) return candidate.cast<Object?>();
  }
  return const [];
}
