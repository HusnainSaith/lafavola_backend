import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:la_favola/week2/week2_models.dart';
import 'package:la_favola_generated_api/la_favola_api.dart' as generated;

const String week2ApiBaseUrl = String.fromEnvironment('LA_FAVOLA_API_BASE_URL');
const String debugWeek2ApiBaseUrl = 'http://10.0.2.2:3001';
const bool googleAuthenticationConfigured = bool.fromEnvironment(
  'LA_FAVOLA_GOOGLE_AUTH_ENABLED',
);
const bool appleAuthenticationConfigured = bool.fromEnvironment(
  'LA_FAVOLA_APPLE_AUTH_ENABLED',
);

final class Week2HttpResponse {
  const Week2HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final String body;
}

final class _PendingCheckout {
  const _PendingCheckout({
    required this.restaurantId,
    required this.lines,
    required this.fulfilment,
    required this.couponCode,
  });

  final String restaurantId;
  final List<QuoteLineInput> lines;
  final FulfillmentContext fulfilment;
  final String? couponCode;
}

abstract interface class Week2HttpTransport {
  Future<Week2HttpResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String? body,
    required Duration timeout,
  });
}

final class IoWeek2HttpTransport implements Week2HttpTransport {
  IoWeek2HttpTransport({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<Week2HttpResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String? body,
    required Duration timeout,
  }) async {
    final request = await _client.openUrl(method, uri).timeout(timeout);
    headers.forEach(request.headers.set);
    if (body != null) request.write(body);
    final response = await request.close().timeout(timeout);
    const maximumResponseBytes = 1024 * 1024;
    var byteCount = 0;
    final bytes = <int>[];
    await for (final chunk in response.timeout(timeout)) {
      byteCount += chunk.length;
      if (byteCount > maximumResponseBytes) {
        throw const FormatException('Response exceeds one MiB.');
      }
      bytes.addAll(chunk);
    }
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name.toLowerCase()] = values.join(',');
    });
    return Week2HttpResponse(
      statusCode: response.statusCode,
      headers: Map.unmodifiable(responseHeaders),
      body: utf8.decode(bytes),
    );
  }
}

final class HttpWeek2Gateway implements Week2Gateway {
  HttpWeek2Gateway({
    required Uri baseUri,
    Week2HttpTransport? transport,
    this.timeout = const Duration(seconds: 12),
    Set<String> configuredFederatedProviders = const {},
  }) : _baseUri = _validatedBaseUri(baseUri),
       _transport = transport ?? IoWeek2HttpTransport(),
       configuredFederatedProviders = Set.unmodifiable(
         configuredFederatedProviders,
       );

  factory HttpWeek2Gateway.fromEnvironment({
    Week2HttpTransport? transport,
    Duration timeout = const Duration(seconds: 12),
  }) {
    final providers = <String>{
      if (googleAuthenticationConfigured) 'google',
      if (appleAuthenticationConfigured) 'apple',
    };
    final configuredBase = week2ApiBaseUrl.trim();
    if (configuredBase.isEmpty && !kDebugMode) {
      throw StateError(
        'LA_FAVOLA_API_BASE_URL is required for release builds.',
      );
    }
    final effectiveBase =
        configuredBase.isNotEmpty ? configuredBase : debugWeek2ApiBaseUrl;
    return HttpWeek2Gateway(
      baseUri: Uri.parse(effectiveBase),
      transport: transport,
      timeout: timeout,
      configuredFederatedProviders: providers,
    );
  }

  final Uri? _baseUri;
  final Week2HttpTransport _transport;
  final Duration timeout;
  @override
  final Set<String> configuredFederatedProviders;
  final Map<String, String> _pendingIdempotencyKeys = {};
  final Map<String, _PendingCheckout> _pendingCheckouts = {};
  final Set<String> _knownSizeIds = {};
  String? _accessToken;
  String? _refreshToken;
  Future<CustomerSession?> Function()? _sessionRefresh;

  void configureSessionCoordinator(
    Future<CustomerSession?> Function() refresh,
  ) {
    _sessionRefresh = refresh;
  }

  int _sequence = 0;

  static Uri _validatedBaseUri(Uri value) {
    if (!value.hasScheme ||
        !value.hasAuthority ||
        (!kDebugMode && value.scheme != 'https') ||
        !const {'http', 'https'}.contains(value.scheme) ||
        value.userInfo.isNotEmpty ||
        value.query.isNotEmpty ||
        value.fragment.isNotEmpty) {
      throw ArgumentError.value(value, 'baseUri', 'Unsupported API base URL.');
    }
    return value;
  }

  @override
  Map<String, generated.JsonOperationContract> get generatedOperations =>
      generated.kPublicCustomerOperations;

  @override
  bool get supportsCustomerReauthentication => false;

  generated.JsonOperationRequest _request({
    Map<String, Object?> path = const {},
    Map<String, Object?> query = const {},
    Map<String, Object?> headers = const {},
    Object? body,
  }) {
    return generated.JsonOperationRequest(
      path: path,
      query: query,
      headers: headers,
      body: body,
    );
  }

  String _correlationId() {
    _sequence += 1;
    return 'mobile-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$_sequence';
  }

  String _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return '{${keys.map((key) => '${jsonEncode(key)}:${_canonical(value[key])}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_canonical).join(',')}]';
    }
    return jsonEncode(value);
  }

  String _idempotencyKey(String scope, generated.JsonOperationRequest request) {
    final fingerprint =
        '$scope:${_canonical(request.path)}:'
        '${_canonical(request.query)}:${_canonical(request.body)}';
    return _pendingIdempotencyKeys.putIfAbsent(fingerprint, () {
      _sequence += 1;
      final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      return 'lf-client-$time-${_sequence.toRadixString(36)}';
    });
  }

  String _fingerprint(String scope, generated.JsonOperationRequest request) =>
      '$scope:${_canonical(request.path)}:${_canonical(request.query)}:'
      '${_canonical(request.body)}';

  Future<Object?> _mutation({
    required generated.JsonOperationContract contract,
    required String scope,
    required generated.JsonOperationRequest Function(String key) request,
  }) async {
    final draft = request('');
    final key = _idempotencyKey(scope, draft);
    final value = request(key);
    final fingerprint = _fingerprint(scope, draft);
    try {
      final result = await _execute(contract, value);
      _pendingIdempotencyKeys.remove(fingerprint);
      return result;
    } on Week2Failure catch (failure) {
      if (!failure.retryable) _pendingIdempotencyKeys.remove(fingerprint);
      rethrow;
    }
  }

  Uri _uriFor(
    generated.JsonOperationContract contract,
    generated.JsonOperationRequest request,
  ) {
    final expanded = contract.path.replaceAllMapped(RegExp(r'\{([^}]+)\}'), (
      match,
    ) {
      final name = match.group(1)!;
      final value = request.path[name];
      if (value == null) {
        throw FormatException('Missing generated path value: $name');
      }
      return Uri.encodeComponent(value.toString());
    });
    final uri = _baseUri!.resolve(expanded);
    if (request.query.isEmpty) return uri;
    return uri.replace(
      queryParameters: request.query.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Future<Object?> _execute(
    generated.JsonOperationContract contract,
    generated.JsonOperationRequest request,
  ) async {
    try {
      if (_baseUri == null) {
        throw Week2Failure(
          kind: Week2FailureKind.dependencyUnavailable,
          message:
              'Il servizio non è configurato. Imposta LA_FAVOLA_API_BASE_URL con un endpoint HTTPS.',
          correlationId: _correlationId(),
        );
      }
      contract.validateRequest(request);
    } on generated.JsonContractException catch (error) {
      final field = RegExp(
        r'(?:body|path|query|headers)\.([A-Za-z0-9_]+)',
      ).firstMatch(error.message)?.group(1);
      throw Week2Failure(
        kind: Week2FailureKind.validation,
        message: 'Controlla i campi indicati.',
        correlationId: _correlationId(),
        field: field,
        fieldErrors: {if (field != null) field: 'Valore non valido.'},
      );
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      if (request.body != null)
        'Content-Type': 'application/json; charset=utf-8',
      for (final entry in request.headers.entries)
        entry.key: entry.value.toString(),
      if (contract.security.isNotEmpty && _accessToken != null)
        'Authorization': 'Bearer $_accessToken',
    };

    try {
      final response = await _transport.send(
        method: contract.method,
        uri: _uriFor(contract, request),
        headers: headers,
        body: request.body == null ? null : jsonEncode(request.body),
        timeout: timeout,
      );
      final Object? decoded =
          response.body.trim().isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          contract.validateSuccess(decoded);
        } on generated.JsonContractException {
          throw Week2Failure(
            kind: Week2FailureKind.malformedResponse,
            message: 'La risposta del servizio non rispetta il contratto.',
            correlationId:
                response.headers['x-correlation-id'] ?? _correlationId(),
            retryable: true,
          );
        }
        return decoded;
      }

      try {
        contract.validateError(decoded);
        final envelope = _map(decoded, 'error envelope');
        final error = generated.StableApiError.fromJson(envelope['error']);
        throw _stableFailure(error, contract.operationId);
      } on generated.JsonContractException {
        throw Week2Failure(
          kind: Week2FailureKind.malformedResponse,
          message: 'Errore del servizio non riconosciuto.',
          correlationId:
              response.headers['x-correlation-id'] ?? _correlationId(),
          retryable: response.statusCode >= 500,
        );
      }
    } on Week2Failure {
      rethrow;
    } on TimeoutException {
      throw Week2Failure(
        kind: Week2FailureKind.timeout,
        message: 'Tempo di attesa superato. Riprova in sicurezza.',
        correlationId: _correlationId(),
        retryable: true,
      );
    } on SocketException {
      throw Week2Failure(
        kind: Week2FailureKind.dependencyUnavailable,
        message: 'Servizio non raggiungibile. Controlla la connessione.',
        correlationId: _correlationId(),
        retryable: true,
      );
    } on FormatException {
      throw Week2Failure(
        kind: Week2FailureKind.malformedResponse,
        message: 'Risposta del servizio non valida.',
        correlationId: _correlationId(),
        retryable: true,
      );
    } on HttpException {
      throw Week2Failure(
        kind: Week2FailureKind.dependencyUnavailable,
        message: 'Servizio temporaneamente non disponibile.',
        correlationId: _correlationId(),
        retryable: true,
      );
    }
  }

  Week2Failure _stableFailure(
    generated.StableApiError error,
    String operationId,
  ) {
    final code = error.code.wireValue;
    final fields = <String, String>{
      for (final item in error.fieldErrors ?? const <generated.FieldError>[])
        item.path.split('.').last: 'Valore non valido.',
    };
    final kind = switch (code) {
      'VALIDATION_FAILED' || 'VALIDATION_ERROR' => Week2FailureKind.validation,
      'UNAUTHENTICATED' ||
      'AUTH_INVALID_CREDENTIALS' => Week2FailureKind.unauthenticated,
      'FORBIDDEN' || 'ACCESS_DENIED' => Week2FailureKind.forbidden,
      'NOT_FOUND' => Week2FailureKind.notFound,
      'RATE_LIMITED' || 'AUTH_RATE_LIMITED' => Week2FailureKind.rateLimited,
      'DEPENDENCY_UNAVAILABLE' => Week2FailureKind.dependencyUnavailable,
      'AUTH_SESSION_EXPIRED' => Week2FailureKind.sessionExpired,
      'AUTH_SESSION_REVOKED' => Week2FailureKind.sessionRevoked,
      'AUTH_SESSION_REUSE_DETECTED' => Week2FailureKind.sessionReuseDetected,
      'AUTH_PROVIDER_CANCELLED' => Week2FailureKind.providerCancelled,
      'CAPABILITY_NOT_READY' || 'CAPABILITY_NOT_AVAILABLE'
          when operationId.contains('Federated') =>
        Week2FailureKind.providerUnavailable,
      'CAPABILITY_NOT_READY' ||
      'CAPABILITY_NOT_AVAILABLE' => Week2FailureKind.dependencyUnavailable,
      'VERSION_CONFLICT' ||
      'IDEMPOTENCY_CONFLICT' ||
      'AUTH_CONFLICT' ||
      'AUTH_LINK_CONFLICT' => Week2FailureKind.conflict,
      'AUTH_VERIFICATION_REQUIRED' ||
      'AUTH_EMAIL_UNVERIFIED' => Week2FailureKind.verificationRequired,
      _ => Week2FailureKind.dependencyUnavailable,
    };
    return Week2Failure(
      kind: kind,
      message: error.message,
      correlationId: error.correlationId,
      retryable: error.retryable,
      field: fields.keys.firstOrNull,
      fieldErrors: Map.unmodifiable(fields),
      currentVersion: error.versionConflict?.currentVersion,
    );
  }

  Map<String, Object?> _map(Object? value, String name) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    throw FormatException('Expected object for $name.');
  }

  Object? _unwrap(Object? value) {
    var current = value;
    for (var index = 0; index < 3; index++) {
      if (current is Map && current.containsKey('data')) {
        current = current['data'];
      } else {
        break;
      }
    }
    return current;
  }

  Future<Object?> _api(
    String method,
    String path, {
    Object? body,
    bool authenticated = false,
    bool retriedAfterRefresh = false,
  }) async {
    if (_baseUri == null || (authenticated && _accessToken == null)) {
      throw Week2Failure(
        kind:
            authenticated
                ? Week2FailureKind.unauthenticated
                : Week2FailureKind.dependencyUnavailable,
        message:
            authenticated
                ? 'Sign in is required.'
                : 'The service is not configured.',
        correlationId: _correlationId(),
      );
    }
    try {
      final correlationId = _correlationId();
      final response = await _transport.send(
        method: method,
        uri: _baseUri.resolve(path),
        headers: {
          'Accept': 'application/json',
          'X-Correlation-Id': correlationId,
          if (body != null) 'Content-Type': 'application/json; charset=utf-8',
          if (authenticated) 'Authorization': 'Bearer $_accessToken',
        },
        body: body == null ? null : jsonEncode(body),
        timeout: timeout,
      );
      final decoded =
          response.body.trim().isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _unwrap(decoded);
      }
      if (response.statusCode == 401 &&
          authenticated &&
          !retriedAfterRefresh &&
          _sessionRefresh != null) {
        final refreshed = await _sessionRefresh!();
        if (refreshed != null) {
          _accessToken = refreshed.accessToken;
          _refreshToken = refreshed.refreshToken;
          return _api(
            method,
            path,
            body: body,
            authenticated: authenticated,
            retriedAfterRefresh: true,
          );
        }
      }
      final error = decoded is Map ? decoded : const <String, Object?>{};
      final rawMessage =
          error['message']?.toString() ?? 'The request could not be completed.';
      final minimum = RegExp(
        r'Minimum order amount is (\d+) minor units',
      ).firstMatch(rawMessage);
      final message =
          minimum == null
              ? rawMessage
              : 'Ordine minimo €${(int.parse(minimum.group(1)!) / 100).toStringAsFixed(2).replaceAll('.', ',')}. Aggiungi altri articoli e riprova.';
      throw Week2Failure(
        kind: switch (response.statusCode) {
          400 || 422 => Week2FailureKind.validation,
          401 => Week2FailureKind.unauthenticated,
          403 => Week2FailureKind.forbidden,
          404 => Week2FailureKind.notFound,
          409 => Week2FailureKind.conflict,
          429 => Week2FailureKind.rateLimited,
          _ => Week2FailureKind.dependencyUnavailable,
        },
        message: message,
        correlationId: response.headers['x-correlation-id'] ?? correlationId,
        retryable: response.statusCode >= 500,
      );
    } on Week2Failure {
      rethrow;
    } on TimeoutException {
      throw Week2Failure(
        kind: Week2FailureKind.timeout,
        message: 'The request timed out. Please try again.',
        correlationId: _correlationId(),
        retryable: true,
      );
    } on SocketException {
      throw Week2Failure(
        kind: Week2FailureKind.dependencyUnavailable,
        message: 'The service cannot be reached. Check your connection.',
        correlationId: _correlationId(),
        retryable: true,
      );
    } on FormatException {
      throw Week2Failure(
        kind: Week2FailureKind.malformedResponse,
        message: 'The service returned an invalid response.',
        correlationId: _correlationId(),
        retryable: true,
      );
    }
  }

  String _string(Map<String, Object?> value, String key) =>
      value[key] as String;
  String? _nullableString(Map<String, Object?> value, String key) =>
      value[key] as String?;

  CustomerSession _session(Object? value) {
    final json = _map(value, 'customer session');
    return CustomerSession(
      accessToken: _string(json, 'accessToken'),
      refreshToken: _string(json, 'refreshToken'),
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
      sessionId:
          json['sessionId']?.toString() ??
          'current-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  CustomerSession _activateSession(Object? value) {
    final session = _session(value);
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    return session;
  }

  CustomerProfile _profile(Object? value) {
    final json = _map(value, 'customer profile');
    return CustomerProfile(
      version: _string(json, 'version'),
      displayName: _string(json, 'displayName'),
      email: _string(json, 'email'),
      emailVerified: json['emailVerified'] as bool,
      phone: _nullableString(json, 'phone'),
      locale: _string(json, 'locale'),
    );
  }

  CustomerAddress _address(Object? value) {
    final json = _map(value, 'customer address');
    return CustomerAddress(
      id: _string(json, 'id'),
      version:
          json['version']?.toString() ?? json['updatedAt']?.toString() ?? '1',
      label: json['label']?.toString() ?? 'Address',
      recipientName: json['recipientName']?.toString() ?? '',
      addressLine:
          json['addressLine']?.toString() ??
          json['addressLine1']?.toString() ??
          '',
      city: _string(json, 'city'),
      province: json['province']?.toString() ?? '',
      postalCode: _string(json, 'postalCode'),
      countryCode: _string(json, 'countryCode'),
      deliveryNotes:
          json['deliveryNotes']?.toString() ??
          json['deliveryInstructions']?.toString(),
      isDefault: json['isDefault'] as bool? ?? false,
      archivedAt:
          json['archivedAt']?.toString() ??
          (json['isActive'] == false
              ? json['updatedAt']?.toString() ?? 'archived'
              : null),
    );
  }

  Map<String, Object?> _addressInput(CustomerAddress value) => {
    'label': value.label,
    'recipientName': value.recipientName,
    'addressLine1': value.addressLine,
    'city': value.city,
    'province': value.province,
    'postalCode': value.postalCode,
    'countryCode': value.countryCode,
    'deliveryInstructions': value.deliveryNotes,
    'isDefault': value.isDefault,
  };

  CustomerPreferences _preferences(Object? value) {
    final json = _map(value, 'customer preferences');
    return CustomerPreferences(
      version: _string(json, 'version'),
      marketingEmailOptIn: json['marketingEmailOptIn'] as bool,
      securityAlertsEnabled: json['securityAlertsEnabled'] as bool,
    );
  }

  SecuritySession _securitySession(Object? value) {
    final json = _map(value, 'security session');
    return SecuritySession(
      id: _string(json, 'id'),
      createdAt: _string(json, 'createdAt'),
      lastUsedAt: _string(json, 'lastUsedAt'),
      expiresAt: _string(json, 'expiresAt'),
      deviceLabel: _nullableString(json, 'deviceLabel'),
      current: json['current'] as bool,
    );
  }

  PrivacyRequest _privacy(Object? value) {
    final json = _map(value, 'privacy request');
    return PrivacyRequest(
      id: _string(json, 'id'),
      kind:
          _string(json, 'kind') == 'export'
              ? PrivacyRequestKind.export
              : PrivacyRequestKind.deletion,
      state: switch (_string(json, 'state')) {
        'requested' => PrivacyRequestState.requested,
        'in_review' => PrivacyRequestState.inReview,
        'completed' => PrivacyRequestState.completed,
        'cancelled' => PrivacyRequestState.cancelled,
        'retention_required' => PrivacyRequestState.retentionRequired,
        _ => throw const FormatException('Unknown privacy request state.'),
      },
      requestedAt: _string(json, 'requestedAt'),
      completedAt: _nullableString(json, 'completedAt'),
      recoveryAction: _nullableString(json, 'recoveryAction'),
    );
  }

  @override
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await _api(
      'POST',
      '/api/v1/auth/register',
      body: {'email': email, 'password': password, 'fullName': displayName},
    );
  }

  @override
  Future<CustomerSession> login({
    required String email,
    required String password,
  }) async {
    final value = await _api(
      'POST',
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
    );
    return _activateSession(value);
  }

  @override
  Future<void> verifyEmail(String token) async {
    await _api('POST', '/api/v1/auth/verify-email', body: {'code': token});
  }

  @override
  Future<void> resendVerification(String email) async {
    await _api(
      'POST',
      '/api/v1/auth/request-email-verification',
      body: {'email': email},
      authenticated: _accessToken != null,
    );
  }

  @override
  Future<void> requestPasswordRecovery(String email) async {
    await _api('POST', '/api/v1/auth/forgot-password', body: {'email': email});
  }

  @override
  Future<void> resetPassword({
    required String code,
    required String password,
  }) async {
    await _api(
      'POST',
      '/api/v1/auth/reset-password',
      body: {'code': code, 'password': password},
    );
  }

  @override
  Future<ProviderIntent> startFederated(String provider) async {
    if (!configuredFederatedProviders.contains(provider)) {
      throw Week2Failure(
        kind: Week2FailureKind.providerUnavailable,
        message: 'Questo metodo di accesso non è configurato.',
        correlationId: _correlationId(),
      );
    }

    final value = await _mutation(
      contract: generated.customerFederatedIntentContract,
      scope: 'customer-federated-intent',
      request:
          (key) => _request(
            headers: {
              'Idempotency-Key': key,
              'X-Correlation-Id': _correlationId(),
            },
            body: {'provider': provider},
          ),
    );
    final json = _map(value, 'provider intent');
    return ProviderIntent(
      provider: _string(json, 'provider'),
      intentId: _string(json, 'intentId'),
      nonce: _string(json, 'nonce'),
      state: _string(json, 'state'),
      live: json['live'] as bool,
    );
  }

  @override
  Future<CustomerSession> completeFederated({
    required ProviderIntent intent,
    required String result,
  }) async {
    if (result == 'success') {
      throw Week2Failure(
        kind: Week2FailureKind.providerUnavailable,
        message:
            'Il ritorno del provider richiede l’adattatore di autenticazione configurato.',
        correlationId: _correlationId(),
      );
    }
    final body = {
      'provider': intent.provider,
      'intentId': intent.intentId,
      'nonce': intent.nonce,
      'state': intent.state,
      'result': result,
    };
    final value = await _mutation(
      contract: generated.customerFederatedCompletionContract,
      scope: 'customer-federated-completion',
      request:
          (key) => _request(
            headers: {
              'Idempotency-Key': key,
              'X-Correlation-Id': _correlationId(),
            },
            body: body,
          ),
    );
    return _activateSession(value);
  }

  @override
  Future<String> reauthenticate(String password) async =>
      throw _privacyProofUnavailable();

  @override
  Future<CustomerSession> refreshSession(String refreshToken) async {
    final value = await _api(
      'POST',
      '/api/v1/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    return _activateSession(value);
  }

  @override
  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        await _api(
          'POST',
          '/api/v1/auth/logout',
          body: {'refreshToken': _refreshToken},
          authenticated: true,
        );
      }
    } on Week2Failure catch (failure) {
      if (failure.kind != Week2FailureKind.unauthenticated &&
          failure.kind != Week2FailureKind.sessionExpired &&
          failure.kind != Week2FailureKind.sessionRevoked) {
        rethrow;
      }
    } finally {
      _accessToken = null;
      _refreshToken = null;
    }
  }

  @override
  Future<CustomerProfile> getProfile() async => _profile(
    await _api('GET', '/api/v1/customers/me/profile', authenticated: true),
  );

  @override
  Future<CustomerProfile> updateProfile({
    required String displayName,
    required String? phone,
    required String expectedVersion,
  }) async {
    return _profile(
      await _api(
        'PATCH',
        '/api/v1/customers/me/profile',
        authenticated: true,
        body: {'displayName': displayName, 'phone': phone},
      ),
    );
  }

  @override
  Future<List<CustomerAddress>> getAddresses() async {
    final value = await _api(
      'GET',
      '/api/v1/customers/me/addresses',
      authenticated: true,
    );
    return List.unmodifiable((value as List<Object?>).map(_address));
  }

  @override
  Future<CustomerAddress> createAddress(CustomerAddress input) async {
    return _address(
      await _api(
        'POST',
        '/api/v1/customers/me/addresses',
        authenticated: true,
        body: _addressInput(input),
      ),
    );
  }

  @override
  Future<CustomerAddress> updateAddress(CustomerAddress input) async {
    return _address(
      await _api(
        'PATCH',
        '/api/v1/customers/me/addresses/${Uri.encodeComponent(input.id)}',
        authenticated: true,
        body: _addressInput(input),
      ),
    );
  }

  @override
  Future<CustomerAddress> archiveAddress(CustomerAddress input) async {
    await _api(
      'DELETE',
      '/api/v1/customers/me/addresses/${Uri.encodeComponent(input.id)}',
      authenticated: true,
    );
    return input.copyWith(archivedAt: DateTime.now().toIso8601String());
  }

  @override
  Future<CustomerPreferences> getPreferences() async => _preferences(
    await _api('GET', '/api/v1/customers/me/preferences', authenticated: true),
  );

  @override
  Future<CustomerPreferences> updatePreferences({
    required bool marketingEmailOptIn,
    required String expectedVersion,
  }) async {
    return _preferences(
      await _api(
        'PATCH',
        '/api/v1/customers/me/preferences',
        authenticated: true,
        body: {'marketingEmailOptIn': marketingEmailOptIn},
      ),
    );
  }

  @override
  Future<List<SecuritySession>> getSecuritySessions() async {
    final value = await _api(
      'GET',
      '/api/v1/customers/me/security/sessions',
      authenticated: true,
    );
    final values =
        value is List<Object?>
            ? value
            : (_map(value, 'security sessions')['data'] as List<Object?>? ??
                const []);
    return List.unmodifiable(values.map(_securitySession));
  }

  @override
  Future<void> revokeSecuritySession(String id) async {
    await _api(
      'DELETE',
      '/api/v1/customers/me/security/sessions/${Uri.encodeComponent(id)}',
      authenticated: true,
    );
  }

  Week2Failure _privacyProofUnavailable() => Week2Failure(
    kind: Week2FailureKind.dependencyUnavailable,
    message:
        'Privacy export and deletion require recent identity verification and are not available yet.',
    correlationId: _correlationId(),
  );

  @override
  Future<PrivacyRequest> requestPrivacyExport(String proof) async =>
      throw _privacyProofUnavailable();
  @override
  Future<PrivacyRequest> requestPrivacyDeletion(String proof) async =>
      throw _privacyProofUnavailable();
  @override
  Future<PrivacyRequest> getPrivacyRequest(String id) async => _privacy(
    await _api(
      'GET',
      '/api/v1/customers/me/privacy/requests/${Uri.encodeComponent(id)}',
      authenticated: true,
    ),
  );
  @override
  Future<MenuSnapshot> getMenu() async {
    final results = await Future.wait([
      _api('GET', '/api/v1/categories'),
      _api('GET', '/api/v1/menu?limit=100'),
    ]);
    final categoryValues = results[0] as List<Object?>;
    final menu = _map(results[1], 'menu');
    final itemValues = menu['items'] as List<Object?>? ?? const [];
    final items = itemValues
        .map((value) => _v1MenuItem(_map(value, 'menu item')))
        .toList(growable: false);
    final categories =
        categoryValues.map((value) {
            final category = _map(value, 'menu category');
            final categoryId = _string(category, 'id');
            final categoryItems =
                items.where((item) => item.categoryId == categoryId).toList()
                  ..sort((left, right) {
                    final byOrder = left.displayOrder.compareTo(
                      right.displayOrder,
                    );
                    return byOrder != 0
                        ? byOrder
                        : left.name.compareTo(right.name);
                  });
            return MenuCategory(
              id: categoryId,
              version: category['updatedAt']?.toString() ?? '1',
              parentCategoryId: category['parentCategoryId']?.toString(),
              name: _string(category, 'name'),
              description: category['description']?.toString(),
              displayOrder: (category['displayOrder'] as num?)?.toInt() ?? 0,
              items: List.unmodifiable(categoryItems),
            );
          }).toList()
          ..sort((left, right) {
            final byOrder = left.displayOrder.compareTo(right.displayOrder);
            return byOrder != 0 ? byOrder : left.name.compareTo(right.name);
          });
    return MenuSnapshot(
      catalogVersion:
          items.isEmpty
              ? 'empty'
              : items
                  .map((item) => item.version)
                  .reduce(
                    (latest, version) =>
                        version.compareTo(latest) > 0 ? version : latest,
                  ),
      categories: List.unmodifiable(categories),
    );
  }

  @override
  Future<MenuItemSummary> getMenuItem(String id) async {
    final item = _map(
      await _api('GET', '/api/v1/menu/${Uri.encodeComponent(id)}'),
      'menu item',
    );
    List<OptionGroupSummary>? builderGroups;
    if (item['itemType'] == 'build_your_own') {
      final configuration = _map(
        await _api('GET', '/api/v1/pizza-builder/${Uri.encodeComponent(id)}'),
        'pizza builder configuration',
      );
      builderGroups = _v1BuilderGroups(configuration, id);
    }
    return _v1MenuItem(item, extraGroups: builderGroups);
  }

  @override
  Future<FulfillmentAvailability> getFulfillmentAvailability({
    required FulfillmentType type,
    String? date,
    String? menuItemId,
  }) async {
    final query = <String, String>{
      'orderType': type.name,
      if (date != null) 'date': date,
      if (menuItemId != null) 'menuItemId': menuItemId,
    };
    final uri = Uri(
      path: '/api/v1/restaurant/availability',
      queryParameters: query,
    );
    final source = _map(
      await _api('GET', uri.toString()),
      'fulfilment availability',
    );
    return FulfillmentAvailability(
      serverNow: _string(source, 'serverNow'),
      timezone: _string(source, 'timezone'),
      date: _string(source, 'date'),
      orderType:
          source['orderType'] == 'pickup'
              ? FulfillmentType.pickup
              : FulfillmentType.delivery,
      leadMinutes: (source['leadMinutes'] as num).toInt(),
      asapAvailable: source['asapAvailable'] == true,
      estimatedReadyAt: source['estimatedReadyAt']?.toString(),
      estimatedDeliveryAt: source['estimatedDeliveryAt']?.toString(),
      slots: (source['slots'] as List<Object?>? ?? const [])
          .map((value) {
            final slot = _map(value, 'fulfilment slot');
            return FulfillmentSlot(
              scheduledFor: _string(slot, 'scheduledFor'),
              localTime: _string(slot, 'localTime'),
            );
          })
          .toList(growable: false),
    );
  }

  MenuItemSummary _v1MenuItem(
    Map<String, Object?> json, {
    List<OptionGroupSummary>? extraGroups,
  }) {
    final id = _string(json, 'id');
    final sizes = (json['sizes'] as List<Object?>? ?? const [])
        .map((value) => _map(value, 'menu item size'))
        .toList(growable: false);
    _knownSizeIds.addAll(sizes.map((size) => _string(size, 'id')));
    final sizeGroup = OptionGroupSummary(
      id: 'size:$id',
      version: json['updatedAt']?.toString() ?? '1',
      name: 'Size',
      displayOrder: -1,
      required: true,
      minChoices: 1,
      maxChoices: 1,
      appliesToItemIds: [id],
      choices: sizes
          .map((size) {
            final sizeId = _string(size, 'id');
            return OptionChoiceSummary(
              id: sizeId,
              version: size['updatedAt']?.toString() ?? '1',
              optionGroupId: 'size:$id',
              name:
                  size['displayName']?.toString() ??
                  size['sizeCode'].toString(),
              displayOrder: (size['displayOrder'] as num?)?.toInt() ?? 0,
              priceAdjustmentMinor: (size['basePriceMinor'] as num).toInt(),
              allergenTags: const [],
              dietaryTags: const [],
              available: true,
              state: 'active',
            );
          })
          .toList(growable: false),
      state: 'active',
    );
    final dietaryTags = <String>[
      if (json['isVegetarian'] == true) 'Vegetarian',
      if (json['isVegan'] == true) 'Vegan',
      if (json['isGlutenFree'] == true) 'Gluten-free',
      if (json['isSpicy'] == true) 'Spicy',
    ];
    final minimumPrice = sizes
        .map((size) => (size['basePriceMinor'] as num).toInt())
        .fold<int?>(
          null,
          (current, value) =>
              current == null || value < current ? value : current,
        );
    return MenuItemSummary(
      id: id,
      version: json['updatedAt']?.toString() ?? '1',
      categoryId: json['categoryId']?.toString() ?? '',
      name: _string(json, 'name'),
      description: json['description']?.toString(),
      price: _formatEuroMinor(minimumPrice),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      basePriceMinor: minimumPrice,
      dietaryTags: dietaryTags,
      attributes: dietaryTags,
      isBuilderProduct: json['itemType'] == 'build_your_own',
      availabilityState: 'available',
      optionGroups: [if (sizes.isNotEmpty) sizeGroup, ...?extraGroups],
    );
  }

  String? _formatEuroMinor(int? value) {
    if (value == null) return null;
    final euros = value ~/ 100;
    final cents = (value % 100).abs().toString().padLeft(2, '0');
    return '€$euros,$cents';
  }

  List<OptionGroupSummary> _v1BuilderGroups(
    Map<String, Object?> configuration,
    String itemId,
  ) {
    final groups = configuration['groups'] as List<Object?>? ?? const [];
    return groups
        .map((value) {
          final group = _map(value, 'builder group');
          final groupId = _string(group, 'id');
          return OptionGroupSummary(
            id: groupId,
            version: '1',
            name: _string(group, 'name'),
            displayOrder: switch (group['type']) {
              'dough' => 10,
              'sauce' => 20,
              'cheese' => 30,
              _ => 40,
            },
            required: group['required'] as bool? ?? false,
            minChoices: (group['minSelections'] as num?)?.toInt() ?? 0,
            maxChoices: (group['maxSelections'] as num?)?.toInt() ?? 30,
            appliesToItemIds: [itemId],
            choices: (group['choices'] as List<Object?>? ?? const [])
                .map((entry) {
                  final choice = _map(entry, 'builder choice');
                  return OptionChoiceSummary(
                    id: _string(choice, 'id'),
                    version: '1',
                    optionGroupId: groupId,
                    name: _string(choice, 'name'),
                    displayOrder: 0,
                    priceAdjustmentMinor:
                        (choice['priceAdjustmentMinor'] as num?)?.toInt() ?? 0,
                    allergenTags: const [],
                    dietaryTags: const [],
                    available: true,
                    state: 'active',
                  );
                })
                .toList(growable: false),
            state: 'active',
          );
        })
        .toList(growable: false);
  }

  // ===== WEEK 3: QUOTES =====

  @override
  Future<Quote> createQuote({
    required String locationId,
    required List<QuoteLineInput> lines,
    required FulfillmentContext fulfillmentContext,
    String? couponCode,
    bool loyaltyIntent = false,
  }) async {
    final restaurant = _map(
      await _api('GET', '/api/v1/restaurant'),
      'restaurant',
    );
    final restaurantId = _string(restaurant, 'id');
    final quoteLines = <QuoteLine>[];
    var subtotalMinor = 0;
    for (final line in lines) {
      final sizeId = line.choiceIds.where(_knownSizeIds.contains).firstOrNull;
      if (sizeId == null) {
        throw Week2Failure(
          kind: Week2FailureKind.validation,
          message: 'Choose a size before continuing.',
          correlationId: _correlationId(),
          field: 'size',
        );
      }
      final optionIds = line.choiceIds
          .where((id) => !_knownSizeIds.contains(id))
          .toList(growable: false);
      final price = _map(
        await _api(
          'POST',
          '/api/v1/pricing/calculate',
          body: {
            'menuItemId': line.itemId,
            'sizeId': sizeId,
            'quantity': line.quantity,
            'optionChoiceIds': optionIds,
          },
        ),
        'price',
      );
      final item = _map(
        await _api('GET', '/api/v1/menu/${Uri.encodeComponent(line.itemId)}'),
        'menu item',
      );
      final lineTotal = (price['lineTotalMinor'] as num).toInt();
      subtotalMinor += lineTotal;
      quoteLines.add(
        QuoteLine(
          itemId: line.itemId,
          itemVersion: item['updatedAt']?.toString() ?? '1',
          name: _string(item, 'name'),
          quantity: line.quantity,
          choices: optionIds
              .map(
                (id) => QuoteLineChoice(
                  choiceId: id,
                  name: 'Selected option',
                  priceAdjustmentMinor: 0,
                ),
              )
              .toList(growable: false),
          unitBasePriceMinor: (price['basePriceMinor'] as num).toInt(),
          unitTotalMinor: (price['unitPriceMinor'] as num).toInt(),
          lineTotalMinor: lineTotal,
        ),
      );
    }
    final fulfilment = _map(restaurant['fulfilment'], 'fulfilment settings');
    final feeMinor =
        fulfillmentContext.type == FulfillmentType.delivery
            ? (fulfilment['deliveryFeeMinor'] as num).toInt()
            : 0;
    final quoteId = _correlationId();
    _pendingCheckouts[quoteId] = _PendingCheckout(
      restaurantId: restaurantId,
      lines: List.unmodifiable(lines),
      fulfilment: fulfillmentContext,
      couponCode: couponCode,
    );
    return Quote(
      quoteId: quoteId,
      catalogVersion: 'live',
      configurationVersion: 'live',
      expiresAt:
          DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      lines: List.unmodifiable(quoteLines),
      subtotalMinor: subtotalMinor,
      discountMinor: 0,
      feeMinor: feeMinor,
      taxMinor: 0,
      totalMinor: subtotalMinor + feeMinor,
      currency: 'EUR',
      appliedPromotions: const [],
      warnings: [
        const QuoteWarning(
          path: 'total',
          code: 'SERVER_RECALCULATION',
          message:
              'Tax, promotions and availability are recalculated securely when the order is placed.',
        ),
        if (couponCode != null)
          const QuoteWarning(
            path: 'couponCode',
            code: 'COUPON_AT_CHECKOUT',
            message:
                'The promotion code will be validated in the final checkout total.',
          ),
      ],
    );
  }

  @override
  Future<Quote> getQuote(String quoteId) async {
    final pending = _pendingCheckouts[quoteId];
    if (pending == null) {
      throw Week2Failure(
        kind: Week2FailureKind.notFound,
        message: 'This checkout preview has expired.',
        correlationId: _correlationId(),
      );
    }
    return createQuote(
      locationId: pending.restaurantId,
      lines: pending.lines,
      fulfillmentContext: pending.fulfilment,
      couponCode: pending.couponCode,
    );
  }

  @override
  Future<Quote> applyPromotion(String quoteId, String code) async {
    final pending = _pendingCheckouts[quoteId];
    if (pending == null) {
      throw Week2Failure(
        kind: Week2FailureKind.notFound,
        message: 'This checkout preview has expired.',
        correlationId: _correlationId(),
      );
    }
    return createQuote(
      locationId: pending.restaurantId,
      lines: pending.lines,
      fulfillmentContext: pending.fulfilment,
      couponCode: code,
    );
  }

  @override
  Future<OrderReceipt> submitOrder(
    String quoteId,
    PaymentMethod paymentMethod,
  ) async {
    if (_accessToken == null) {
      throw Week2Failure(
        kind: Week2FailureKind.unauthenticated,
        message: 'Sign in is required before placing an order.',
        correlationId: _correlationId(),
      );
    }
    final pending = _pendingCheckouts[quoteId];
    if (pending == null) {
      throw Week2Failure(
        kind: Week2FailureKind.notFound,
        message: 'This checkout preview has expired. Refresh the total.',
        correlationId: _correlationId(),
      );
    }
    await _api(
      'DELETE',
      '/api/v1/cart?restaurantId=${Uri.encodeQueryComponent(pending.restaurantId)}',
      authenticated: true,
    );
    for (final line in pending.lines) {
      final sizeId = line.choiceIds.where(_knownSizeIds.contains).firstOrNull;
      if (sizeId == null) {
        throw Week2Failure(
          kind: Week2FailureKind.validation,
          message: 'Choose a size before placing the order.',
          correlationId: _correlationId(),
          field: 'size',
        );
      }
      final optionIds = line.choiceIds
          .where((id) => !_knownSizeIds.contains(id))
          .toList(growable: false);
      await _api(
        'POST',
        '/api/v1/cart/items?restaurantId=${Uri.encodeQueryComponent(pending.restaurantId)}',
        authenticated: true,
        body: {
          'menuItemId': line.itemId,
          'menuItemSizeId': sizeId,
          'quantity': line.quantity,
          'options': optionIds
              .map((id) => {'optionChoiceId': id, 'quantity': 1})
              .toList(growable: false),
        },
      );
    }
    final cart = _map(
      await _api(
        'GET',
        '/api/v1/cart?restaurantId=${Uri.encodeQueryComponent(pending.restaurantId)}',
        authenticated: true,
      ),
      'cart',
    );
    final cartRecord = _map(cart['cart'], 'active cart');
    final result = _map(
      await _api(
        'POST',
        '/api/v1/checkout',
        authenticated: true,
        body: {
          'cartId': _string(cartRecord, 'id'),
          'orderType': pending.fulfilment.type.name,
          if (pending.fulfilment.type == FulfillmentType.delivery)
            'deliveryAddressId': pending.fulfilment.addressId,
          'paymentMethod':
              paymentMethod == PaymentMethod.onlineCard ? 'card' : 'cash',
          if (pending.couponCode != null) 'couponCode': pending.couponCode,
          if (pending.fulfilment.scheduledFor != null)
            'scheduledFor': pending.fulfilment.scheduledFor,
          'idempotencyKey': quoteId,
        },
      ),
      'checkout result',
    );
    _pendingCheckouts.remove(quoteId);
    return _checkoutReceipt(result, paymentMethod);
  }

  @override
  Future<List<OrderReceipt>> getOrders() async {
    final response = await _api(
      'GET',
      '/api/v1/orders/me?page=1&limit=100',
      authenticated: true,
    );
    final values = switch (response) {
      final List<Object?> items => items,
      final Map<Object?, Object?> source =>
        (source['data'] ?? source['items']) as List<Object?>? ?? const [],
      _ => const <Object?>[],
    };
    return List.unmodifiable(
      values.map((value) => _v1OrderReceipt(_map(value, 'order'))),
    );
  }

  @override
  Future<OrderReceipt> getOrder(String orderId) async {
    final detail = _map(
      await _api(
        'GET',
        '/api/v1/orders/me/${Uri.encodeComponent(orderId)}',
        authenticated: true,
      ),
      'order detail',
    );
    return _v1OrderReceipt(
      _map(detail['order'], 'order'),
      timing: detail['timing'] is Map ? _map(detail['timing'], 'timing') : null,
      history: detail['statusHistory'] as List<Object?>? ?? const [],
    );
  }

  @override
  Future<CustomerOrderReceiptDocument> getOrderReceipt(String orderId) async {
    final source = _map(
      await _api(
        'GET',
        '/api/v1/orders/me/${Uri.encodeComponent(orderId)}/receipt',
        authenticated: true,
      ),
      'order receipt',
    );
    final restaurant = _map(source['restaurant'], 'receipt restaurant');
    final order = _map(source['order'], 'receipt order');
    final totals = _map(order['totals'], 'receipt totals');
    return CustomerOrderReceiptDocument(
      documentType: _string(source, 'documentType'),
      fiscalDocument: source['fiscalDocument'] == true,
      issuedAt: _string(source, 'issuedAt'),
      restaurant: ReceiptRestaurant(
        name: _string(restaurant, 'name'),
        address: (restaurant['address'] as List<Object?>? ?? const [])
            .map((value) => value.toString())
            .toList(growable: false),
        vatNumber: restaurant['vatNumber']?.toString(),
        fiscalCode: restaurant['fiscalCode']?.toString(),
        phone: restaurant['phone']?.toString(),
        email: restaurant['email']?.toString(),
      ),
      order: ReceiptOrder(
        number: _string(order, 'number'),
        type: _string(order, 'type'),
        status: _string(order, 'status'),
        paymentStatus: _string(order, 'paymentStatus'),
        paymentMethod: order['paymentMethod']?.toString(),
        currency: _string(order, 'currency'),
        items: (order['items'] as List<Object?>? ?? const [])
            .map((value) {
              final item = _map(value, 'receipt item');
              return ReceiptOrderItem(
                name: _string(item, 'name'),
                size: item['size']?.toString(),
                quantity: (item['quantity'] as num).toInt(),
                unitPriceMinor: (item['unitPriceMinor'] as num).toInt(),
                lineTotalMinor: (item['lineTotalMinor'] as num).toInt(),
                options: (item['options'] as List<Object?>? ?? const [])
                    .map((value) {
                      final option = _map(value, 'receipt option');
                      return ReceiptOrderOption(
                        name: _string(option, 'name'),
                        quantity: (option['quantity'] as num).toInt(),
                        totalPriceAdjustmentMinor:
                            (option['totalPriceAdjustmentMinor'] as num)
                                .toInt(),
                      );
                    })
                    .toList(growable: false),
              );
            })
            .toList(growable: false),
        totals: ReceiptTotals(
          subtotalMinor: (totals['subtotalMinor'] as num).toInt(),
          optionChargesMinor: (totals['optionChargesMinor'] as num).toInt(),
          discountMinor: (totals['discountMinor'] as num).toInt(),
          deliveryFeeMinor: (totals['deliveryFeeMinor'] as num).toInt(),
          taxMinor: (totals['taxMinor'] as num).toInt(),
          grandTotalMinor: (totals['grandTotalMinor'] as num).toInt(),
        ),
      ),
      notice: _string(source, 'notice'),
    );
  }

  @override
  Stream<OrderRealtimeEvent> watchOrderEvents(String orderId) async* {
    if (_accessToken == null) {
      throw Week2Failure(
        kind: Week2FailureKind.unauthenticated,
        message: 'Sign in is required to track this order.',
        correlationId: _correlationId(),
      );
    }
    String? lastVersion;
    while (_accessToken != null) {
      final order = await getOrder(orderId);
      if (order.version != lastVersion) {
        lastVersion = order.version;
        yield OrderRealtimeEvent(sequence: order.version, orderId: orderId);
      }
      if (const {
        'delivered',
        'closed',
        'cancelled',
        'rejected',
      }.contains(order.status)) {
        break;
      }
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  @override
  Future<OrderReceipt> requestOrderCancellation({
    required String orderId,
    required String expectedVersion,
    required String reason,
  }) async {
    await _api(
      'POST',
      '/api/v1/orders/me/${Uri.encodeComponent(orderId)}/cancel',
      authenticated: true,
      body: {'reason': reason},
    );
    return getOrder(orderId);
  }

  OrderReceipt _checkoutReceipt(
    Map<String, Object?> data,
    PaymentMethod paymentMethod,
  ) {
    final serverNow =
        data['serverNow']?.toString() ?? DateTime.now().toIso8601String();
    final target =
        data['estimatedDeliveryAt']?.toString() ??
        data['estimatedReadyAt']?.toString();
    final etaMinutes =
        target == null
            ? null
            : (DateTime.parse(
                      target,
                    ).difference(DateTime.parse(serverNow)).inSeconds /
                    60)
                .ceil()
                .clamp(0, 1440);
    final orderId = data['orderId']?.toString();
    if (orderId == null || orderId.isEmpty) {
      throw Week2Failure(
        kind: Week2FailureKind.malformedResponse,
        message: 'The order was received but its confirmation was incomplete.',
        correlationId: _correlationId(),
        retryable: true,
      );
    }
    final reference =
        data['orderNumber']?.toString() ??
        data['reference']?.toString() ??
        orderId.substring(0, orderId.length.clamp(1, 8));
    return OrderReceipt(
      orderId: orderId,
      reference: reference,
      status: data['status']?.toString() ?? 'placed',
      totalMinor: (data['amountMinor'] as num?)?.toInt() ?? 0,
      currency: data['currency']?.toString() ?? 'EUR',
      createdAt: serverNow,
      fulfillmentType: data['orderType']?.toString() ?? 'delivery',
      paymentMethod: paymentMethod,
      paymentStatus: data['paymentStatus']?.toString() ?? 'pending',
      etaMinutes: etaMinutes,
      estimatedReadyAt: data['estimatedReadyAt']?.toString(),
      estimatedDeliveryAt: data['estimatedDeliveryAt']?.toString(),
      estimateUpdatedAt: serverNow,
      serverTime: serverNow,
    );
  }

  OrderReceipt _v1OrderReceipt(
    Map<String, Object?> data, {
    Map<String, Object?>? timing,
    List<Object?> history = const [],
  }) {
    final serverNow =
        timing?['serverNow']?.toString() ?? DateTime.now().toIso8601String();
    final remainingSeconds = (timing?['remainingSeconds'] as num?)?.toInt();
    return OrderReceipt(
      orderId: _string(data, 'id'),
      reference: _string(data, 'orderNumber'),
      status: _string(data, 'status'),
      totalMinor: (data['grandTotalMinor'] as num).toInt(),
      currency: _string(data, 'currency'),
      createdAt: _string(data, 'createdAt'),
      fulfillmentType: data['orderType']?.toString() ?? 'delivery',
      version: data['version']?.toString() ?? '1',
      paymentMethod:
          data['paymentMethod'] == 'card'
              ? PaymentMethod.onlineCard
              : PaymentMethod.cash,
      paymentStatus: data['paymentStatus']?.toString() ?? 'pending',
      etaMinutes:
          remainingSeconds == null ? null : (remainingSeconds / 60).ceil(),
      estimatedReadyAt:
          timing?['estimatedReadyAt']?.toString() ??
          data['estimatedReadyAt']?.toString(),
      estimatedDeliveryAt:
          timing?['estimatedDeliveryAt']?.toString() ??
          data['estimatedDeliveryAt']?.toString(),
      estimateUpdatedAt: serverNow,
      serverTime: serverNow,
      timeline: history
          .map((value) {
            final event = _map(value, 'order status event');
            return OrderTimelineEvent(
              type: 'status_changed',
              priorStatus: event['previousStatus']?.toString(),
              nextStatus: event['newStatus']?.toString(),
              reason: event['note']?.toString(),
              occurredAt: _string(event, 'occurredAt'),
            );
          })
          .toList(growable: false),
    );
  }
}
