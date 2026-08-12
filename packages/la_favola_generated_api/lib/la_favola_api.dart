// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source of truth: @la-favola/contracts/openapi/openapi.json
// Generator: @la-favola/contracts/scripts/generate-dart-api.mjs

library la_favola_api;

import 'dart:convert';

final class JsonContractException implements FormatException {
  const JsonContractException(this.message, [this.source]);
  @override
  final String message;
  @override
  final Object? source;
  @override
  int? get offset => null;
  @override
  String toString() => 'JsonContractException: $message';
}

Object? _schema(String encoded) => jsonDecode(encoded);
Map<String, Object?> _map(Object? value, String name) {
  if (value is Map<String, Object?>) return value;
  throw JsonContractException('Expected object for $name', value);
}

String _string(Map<String, Object?> json, String name) {
  final value = json[name];
  if (value is String) return value;
  throw JsonContractException('Expected string for $name', value);
}

bool _bool(Map<String, Object?> json, String name) {
  final value = json[name];
  if (value is bool) return value;
  throw JsonContractException('Expected boolean for $name', value);
}

final class ApiTransports {
  const ApiTransports({required this.rest, required this.trpc});
  final String rest;
  final String trpc;
  factory ApiTransports.fromJson(Object? value) {
    final json = _map(value, 'transports');
    return ApiTransports(
      rest: _string(json, 'rest'),
      trpc: _string(json, 'trpc'),
    );
  }
  Map<String, Object?> toJson() => {'rest': rest, 'trpc': trpc};
}

final class ApiMetadata {
  const ApiMetadata({
    required this.service,
    required this.apiVersion,
    required this.contractVersion,
    required this.transports,
  });
  final String service;
  final String apiVersion;
  final String contractVersion;
  final ApiTransports transports;
  factory ApiMetadata.fromJson(Object? value) {
    getApiMetadataContract.validateSuccess(value);
    final json = _map(value, 'ApiMetadata');
    return ApiMetadata(
      service: _string(json, 'service'),
      apiVersion: _string(json, 'apiVersion'),
      contractVersion: _string(json, 'contractVersion'),
      transports: ApiTransports.fromJson(json['transports']),
    );
  }
  Map<String, Object?> toJson() => {
    'service': service,
    'apiVersion': apiVersion,
    'contractVersion': contractVersion,
    'transports': transports.toJson(),
  };
}

void _validateSchema(Object? value, Object? rawSchema, String location) {
  final schema = _map(rawSchema, '$location schema');
  final anyOf = schema['anyOf'];
  if (anyOf is List<Object?>) {
    for (final candidate in anyOf) {
      try {
        _validateSchema(value, candidate, location);
        return;
      } on JsonContractException {
        // Try the next declared alternative.
      }
    }
    throw JsonContractException(
      'Value does not match any allowed shape at $location',
      value,
    );
  }
  if (schema.containsKey('const') && value != schema['const']) {
    throw JsonContractException('Unexpected constant at $location', value);
  }
  final allowed = schema['enum'];
  if (allowed is List<Object?> && !allowed.contains(value)) {
    throw JsonContractException('Unexpected enum value at $location', value);
  }
  final type = schema['type'];
  if (type == 'null') {
    if (value != null)
      throw JsonContractException('Expected null at $location', value);
    return;
  }
  if (type == 'object') {
    final object = _map(value, location);
    final properties = _map(
      schema['properties'] ?? <String, Object?>{},
      '$location properties',
    );
    final required =
        (schema['required'] as List<Object?>? ?? const <Object?>[])
            .cast<String>();
    for (final name in required) {
      if (!object.containsKey(name))
        throw JsonContractException(
          'Missing required field $location.$name',
          object,
        );
    }
    if (schema['additionalProperties'] == false) {
      for (final name in object.keys) {
        if (!properties.containsKey(name))
          throw JsonContractException(
            'Unknown field $location.$name',
            object[name],
          );
      }
    }
    for (final entry in object.entries) {
      if (properties.containsKey(entry.key))
        _validateSchema(
          entry.value,
          properties[entry.key],
          '$location.${entry.key}',
        );
    }
    return;
  }
  if (type == 'array') {
    if (value is! List<Object?>)
      throw JsonContractException('Expected array at $location', value);
    final minItems = schema['minItems'];
    final maxItems = schema['maxItems'];
    if (minItems is num && value.length < minItems)
      throw JsonContractException('Array too short at $location', value);
    if (maxItems is num && value.length > maxItems)
      throw JsonContractException('Array too long at $location', value);
    for (var index = 0; index < value.length; index++) {
      _validateSchema(value[index], schema['items'], '$location[$index]');
    }
    return;
  }
  if (type == 'string') {
    if (value is! String)
      throw JsonContractException('Expected string at $location', value);
    final minLength = schema['minLength'];
    final maxLength = schema['maxLength'];
    if (minLength is num && value.runes.length < minLength)
      throw JsonContractException('String too short at $location', value);
    if (maxLength is num && value.runes.length > maxLength)
      throw JsonContractException('String too long at $location', value);
    final pattern = schema['pattern'];
    if (pattern is String && !RegExp(pattern, unicode: true).hasMatch(value)) {
      throw JsonContractException(
        'String constraint failed at $location',
        value,
      );
    }
    final minCodePoints = schema['x-min-unicode-code-points'];
    if (minCodePoints is num && value.runes.length < minCodePoints) {
      throw JsonContractException(
        'Too few Unicode code points at $location',
        value,
      );
    }
    final maxUtf8Bytes = schema['x-max-utf8-bytes'];
    if (maxUtf8Bytes is num && utf8.encode(value).length > maxUtf8Bytes) {
      throw JsonContractException(
        'UTF-8 byte limit exceeded at $location',
        value,
      );
    }
    return;
  }
  if (type == 'integer' || type == 'number') {
    if (value is! num ||
        (type == 'integer' && value != value.roundToDouble())) {
      throw JsonContractException('Expected $type at $location', value);
    }
    final minimum = schema['minimum'];
    final maximum = schema['maximum'];
    final exclusiveMinimum = schema['exclusiveMinimum'];
    final exclusiveMaximum = schema['exclusiveMaximum'];
    if (minimum is num && value < minimum)
      throw JsonContractException('Number below minimum at $location', value);
    if (maximum is num && value > maximum)
      throw JsonContractException('Number above maximum at $location', value);
    if (exclusiveMinimum is num && value <= exclusiveMinimum)
      throw JsonContractException(
        'Number below exclusive minimum at $location',
        value,
      );
    if (exclusiveMaximum is num && value >= exclusiveMaximum)
      throw JsonContractException(
        'Number above exclusive maximum at $location',
        value,
      );
    return;
  }
  if (type == 'boolean') {
    if (value is! bool)
      throw JsonContractException('Expected boolean at $location', value);
    return;
  }
  if (type != null)
    throw JsonContractException('Unsupported schema type at $location', type);
}

final class JsonOperationRequest {
  const JsonOperationRequest({
    this.path = const <String, Object?>{},
    this.query = const <String, Object?>{},
    this.headers = const <String, Object?>{},
    this.body,
  });
  final Map<String, Object?> path;
  final Map<String, Object?> query;
  final Map<String, Object?> headers;
  final Object? body;
}

class JsonOperationContract {
  const JsonOperationContract({
    required this.operationId,
    required this.method,
    required this.path,
    required this.audience,
    required this.security,
    required this.pathSchema,
    required this.querySchema,
    required this.headerSchema,
    required this.bodySchema,
    required this.responseSchema,
    required this.errorSchema,
  });
  final String operationId;
  final String method;
  final String path;
  final String audience;
  final List<Object?> security;
  final Object pathSchema;
  final Object querySchema;
  final Object headerSchema;
  final Object? bodySchema;
  final Object responseSchema;
  final Object errorSchema;

  JsonOperationRequest requestFromJson(Object? value) {
    final json = _map(value, '$operationId request');
    for (final name in json.keys) {
      if (!const {'path', 'query', 'headers', 'body'}.contains(name)) {
        throw JsonContractException('Unknown request zone $name', json[name]);
      }
    }
    final request = JsonOperationRequest(
      path: _map(json['path'] ?? <String, Object?>{}, 'path'),
      query: _map(json['query'] ?? <String, Object?>{}, 'query'),
      headers: _map(json['headers'] ?? <String, Object?>{}, 'headers'),
      body: json['body'],
    );
    validateRequest(request);
    return request;
  }

  void validateRequest(JsonOperationRequest request) {
    _validateSchema(request.path, pathSchema, '$operationId.path');
    _validateSchema(request.query, querySchema, '$operationId.query');
    _validateSchema(request.headers, headerSchema, '$operationId.headers');
    if (bodySchema == null) {
      if (request.body != null)
        throw JsonContractException(
          'Body is not allowed for $operationId',
          request.body,
        );
    } else {
      _validateSchema(request.body, bodySchema, '$operationId.body');
    }
  }

  void validateSuccess(Object? value) =>
      _validateSchema(value, responseSchema, '$operationId.success');
  void validateError(Object? value) {
    _validateSchema(value, errorSchema, '$operationId.error');
    final envelope = _map(value, '$operationId error envelope');
    _approvedStableMessage(
      _map(envelope['error'], '$operationId stable error'),
    );
  }
}

enum KnownStableErrorCode {
  codeValidationFailed('VALIDATION_FAILED'),
  codeValidationError('VALIDATION_ERROR'),
  codeForbidden('FORBIDDEN'),
  codeUnauthenticated('UNAUTHENTICATED'),
  codeAccessDenied('ACCESS_DENIED'),
  codeNotFound('NOT_FOUND'),
  codeCapabilityNotReady('CAPABILITY_NOT_READY'),
  codeCapabilityNotAvailable('CAPABILITY_NOT_AVAILABLE'),
  codeVersionConflict('VERSION_CONFLICT'),
  codeQuoteStale('QUOTE_STALE'),
  codeQuoteExpired('QUOTE_EXPIRED'),
  codeAvailabilityChanged('AVAILABILITY_CHANGED'),
  codeIdempotencyConflict('IDEMPOTENCY_CONFLICT'),
  codePaymentPending('PAYMENT_PENDING'),
  codeRateLimited('RATE_LIMITED'),
  codeDependencyUnavailable('DEPENDENCY_UNAVAILABLE'),
  codeInternalError('INTERNAL_ERROR'),
  codeAuthInvalidCredentials('AUTH_INVALID_CREDENTIALS'),
  codeAuthVerificationRequired('AUTH_VERIFICATION_REQUIRED'),
  codeAuthEmailUnverified('AUTH_EMAIL_UNVERIFIED'),
  codeAuthSessionExpired('AUTH_SESSION_EXPIRED'),
  codeAuthTokenExpired('AUTH_TOKEN_EXPIRED'),
  codeAuthTokenUsed('AUTH_TOKEN_USED'),
  codeAuthSessionRevoked('AUTH_SESSION_REVOKED'),
  codeAuthSessionReuseDetected('AUTH_SESSION_REUSE_DETECTED'),
  codeAuthLinkConflict('AUTH_LINK_CONFLICT'),
  codeAuthProviderCancelled('AUTH_PROVIDER_CANCELLED'),
  codeAuthConflict('AUTH_CONFLICT'),
  codeAuthRateLimited('AUTH_RATE_LIMITED'),
  codeChoiceUnavailable('CHOICE_UNAVAILABLE'),
  codeChoiceIncompatible('CHOICE_INCOMPATIBLE'),
  codeChoiceMinMaxViolation('CHOICE_MIN_MAX_VIOLATION'),
  codeRequiredGroupMissing('REQUIRED_GROUP_MISSING'),
  codePromotionInvalid('PROMOTION_INVALID'),
  codePromotionExpired('PROMOTION_EXPIRED'),
  codePromotionIneligible('PROMOTION_INELIGIBLE'),
  codePromotionUsageLimit('PROMOTION_USAGE_LIMIT'),
  codePromotionStackingConflict('PROMOTION_STACKING_CONFLICT'),
  codeItemUnavailable('ITEM_UNAVAILABLE'),
  codeBuilderRuleViolation('BUILDER_RULE_VIOLATION');

  const KnownStableErrorCode(this.wireValue);
  final String wireValue;
}

const Map<String, List<String>> _approvedStableMessages = {
  'VALIDATION_FAILED': ['request.invalid', 'Richiesta non valida.'],
  'VALIDATION_ERROR': ['request.invalid', 'Richiesta non valida.'],
  'FORBIDDEN': ['auth.forbidden', 'Accesso negato.'],
  'UNAUTHENTICATED': ['auth.required', 'Autenticazione richiesta.'],
  'ACCESS_DENIED': ['auth.forbidden', 'Accesso negato.'],
  'NOT_FOUND': ['resource.not_found', 'Risorsa non trovata.'],
  'CAPABILITY_NOT_READY': [
    'capability.not_ready',
    'Operazione non disponibile.',
  ],
  'CAPABILITY_NOT_AVAILABLE': [
    'capability.not_available',
    'Operazione non disponibile.',
  ],
  'VERSION_CONFLICT': ['resource.version_conflict', 'Conflitto di versione.'],
  'QUOTE_STALE': ['resource.stale', 'Dati non piu attuali.'],
  'AVAILABILITY_CHANGED': [
    'resource.availability_changed',
    'Disponibilita cambiata.',
  ],
  'IDEMPOTENCY_CONFLICT': [
    'request.idempotency_conflict',
    'Conflitto di richiesta.',
  ],
  'PAYMENT_PENDING': ['operation.pending', 'Operazione in elaborazione.'],
  'RATE_LIMITED': ['request.rate_limited', 'Troppe richieste.'],
  'DEPENDENCY_UNAVAILABLE': [
    'dependency.unavailable',
    'Servizio temporaneamente non disponibile.',
  ],
  'INTERNAL_ERROR': ['operation.failed', 'Operazione non riuscita.'],
  'AUTH_INVALID_CREDENTIALS': [
    'auth.invalid_credentials',
    'Credenziali non valide.',
  ],
  'AUTH_VERIFICATION_REQUIRED': [
    'auth.verification_required',
    'Verifica richiesta.',
  ],
  'AUTH_EMAIL_UNVERIFIED': ['auth.email_unverified', 'Verifica richiesta.'],
  'AUTH_SESSION_EXPIRED': ['auth.session_expired', 'Sessione scaduta.'],
  'AUTH_TOKEN_EXPIRED': ['auth.artifact_expired', 'Collegamento scaduto.'],
  'AUTH_TOKEN_USED': ['auth.artifact_used', 'Collegamento non disponibile.'],
  'AUTH_SESSION_REVOKED': ['auth.session_revoked', 'Sessione non disponibile.'],
  'AUTH_SESSION_REUSE_DETECTED': [
    'auth.session_reuse_detected',
    'Sessione non disponibile.',
  ],
  'AUTH_LINK_CONFLICT': ['auth.link_conflict', 'Conflitto di autenticazione.'],
  'AUTH_PROVIDER_CANCELLED': [
    'auth.provider_cancelled',
    'Operazione annullata.',
  ],
  'AUTH_CONFLICT': ['auth.conflict', 'Conflitto di autenticazione.'],
  'AUTH_RATE_LIMITED': ['auth.rate_limited', 'Troppe richieste.'],
  'CHOICE_UNAVAILABLE': ['choice.unavailable', 'Scelta non disponibile.'],
  'CHOICE_INCOMPATIBLE': [
    'choice.incompatible',
    'Scelta incompatibile con altre selezioni.',
  ],
  'CHOICE_MIN_MAX_VIOLATION': [
    'choice.min_max_violation',
    'Numero di scelte non valido per questo gruppo.',
  ],
  'REQUIRED_GROUP_MISSING': [
    'choice.required_group_missing',
    'Gruppo obbligatorio mancante.',
  ],
  'PROMOTION_INVALID': ['promotion.invalid', 'Codice promozionale non valido.'],
  'PROMOTION_EXPIRED': ['promotion.expired', 'Promozione scaduta.'],
  'PROMOTION_INELIGIBLE': [
    'promotion.ineligible',
    'Promozione non applicabile a questo ordine.',
  ],
  'PROMOTION_USAGE_LIMIT': [
    'promotion.usage_limit',
    'Limite di utilizzo raggiunto.',
  ],
  'PROMOTION_STACKING_CONFLICT': [
    'promotion.stacking_conflict',
    'Promozione incompatibile con altre applicate.',
  ],
  'ITEM_UNAVAILABLE': ['item.unavailable', 'Articolo non disponibile.'],
  'BUILDER_RULE_VIOLATION': [
    'builder.rule_violation',
    'Configurazione pizza non valida.',
  ],
  'QUOTE_EXPIRED': ['quote.expired', 'Preventivo scaduto.'],
};
({String key, String message}) _approvedStableMessage(
  Map<String, Object?> json,
) {
  final code = _string(json, 'code');
  final key = _string(json, 'messageKey');
  final message = _string(json, 'message');
  final approved = _approvedStableMessages[code];
  if (approved == null || approved[0] != key || approved[1] != message) {
    throw JsonContractException(
      'Unapproved stable error message contract',
      json,
    );
  }
  return (key: key, message: message);
}

final class StableErrorCode {
  const StableErrorCode._(this.wireValue, this.known);
  final String wireValue;
  final KnownStableErrorCode? known;
  bool get isKnown => known != null;
  factory StableErrorCode.fromJson(Object? value) {
    if (value is! String)
      throw JsonContractException('Expected string for code', value);
    for (final candidate in KnownStableErrorCode.values) {
      if (candidate.wireValue == value)
        return StableErrorCode._(value, candidate);
    }
    return StableErrorCode._(value, null);
  }
  String toJson() => wireValue;
}

final class FieldError {
  const FieldError({required this.path, required this.code});
  final String path;
  final String code;
  factory FieldError.fromJson(Object? value) {
    final json = _map(value, 'FieldError');
    return FieldError(path: _string(json, 'path'), code: _string(json, 'code'));
  }
  Map<String, Object?> toJson() => {'path': path, 'code': code};
}

final class VersionConflict {
  const VersionConflict({
    required this.currentVersion,
    required this.changedFields,
  });
  final String currentVersion;
  final List<String> changedFields;
  factory VersionConflict.fromJson(Object? value) {
    final json = _map(value, 'VersionConflict');
    final fields = json['changedFields'];
    if (fields is! List<Object?> || fields.any((field) => field is! String)) {
      throw JsonContractException(
        'Expected string array for changedFields',
        fields,
      );
    }
    return VersionConflict(
      currentVersion: _string(json, 'currentVersion'),
      changedFields: List<String>.unmodifiable(fields.cast<String>()),
    );
  }
  Map<String, Object?> toJson() => {
    'currentVersion': currentVersion,
    'changedFields': changedFields,
  };
}

final class StableApiError {
  const StableApiError({
    required this.code,
    required this.messageKey,
    required this.message,
    required this.correlationId,
    required this.retryable,
    this.fieldErrors,
    this.versionConflict,
  });
  final StableErrorCode code;
  final String messageKey;
  final String message;
  final String correlationId;
  final bool retryable;
  final List<FieldError>? fieldErrors;
  final VersionConflict? versionConflict;
  factory StableApiError.fromJson(Object? value) {
    final json = _map(value, 'StableApiError');
    final rawFields = json['fieldErrors'];
    if (json.containsKey('fieldErrors') && rawFields is! List<Object?>) {
      throw JsonContractException('Expected array for fieldErrors', rawFields);
    }
    final fields = rawFields == null ? null : rawFields as List<Object?>;
    final approvedMessage = _approvedStableMessage(json);
    return StableApiError(
      code: StableErrorCode.fromJson(json['code']),
      messageKey: approvedMessage.key,
      message: approvedMessage.message,
      correlationId: _string(json, 'correlationId'),
      retryable: _bool(json, 'retryable'),
      fieldErrors:
          fields == null
              ? null
              : List<FieldError>.unmodifiable(fields.map(FieldError.fromJson)),
      versionConflict:
          json['versionConflict'] == null
              ? null
              : VersionConflict.fromJson(json['versionConflict']),
    );
  }
  Map<String, Object?> toJson() => {
    'code': code.toJson(),
    'messageKey': messageKey,
    'message': message,
    'correlationId': correlationId,
    'retryable': retryable,
    if (fieldErrors != null)
      'fieldErrors': fieldErrors!
          .map((value) => value.toJson())
          .toList(growable: false),
    if (versionConflict != null) 'versionConflict': versionConflict!.toJson(),
  };
}

final class StableErrorEnvelope {
  const StableErrorEnvelope({required this.error});
  final StableApiError error;
  factory StableErrorEnvelope.fromJson(Object? value) {
    final json = _map(value, 'StableErrorEnvelope');
    getApiMetadataContract.validateError(json);
    return StableErrorEnvelope(error: StableApiError.fromJson(json['error']));
  }
  Map<String, Object?> toJson() => {'error': error.toJson()};
}

final class CustomerVerifyEmailContract extends JsonOperationContract {
  CustomerVerifyEmailContract()
    : super(
        operationId: 'customerVerifyEmail',
        method: 'POST',
        path: '/api/v1/auth/customer/email-verifications',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"token":{"type":"string","minLength":8,"maxLength":128}},"required":["token"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"message":{"type":"string","const":"Email verified"}},"required":["message"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerVerifyEmailContract = CustomerVerifyEmailContract();

final class CustomerResendEmailVerificationContract
    extends JsonOperationContract {
  CustomerResendEmailVerificationContract()
    : super(
        operationId: 'customerResendEmailVerification',
        method: 'POST',
        path: '/api/v1/auth/customer/email-verifications/resend',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"email":{"type":"string","maxLength":254,"format":"email","pattern":"^(?!\\\\.)(?!.*\\\\.\\\\.)([A-Za-z0-9_\'+\\\\-\\\\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\\\\-]*\\\\.)+[A-Za-z]{2,}\$"}},"required":["email"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"message":{"type":"string","const":"Verification request accepted"}},"required":["message"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerResendEmailVerificationContract =
    CustomerResendEmailVerificationContract();

final class CustomerFederatedCompletionContract extends JsonOperationContract {
  CustomerFederatedCompletionContract()
    : super(
        operationId: 'customerFederatedCompletion',
        method: 'POST',
        path: '/api/v1/auth/customer/federated-completions',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"provider":{"type":"string","enum":["google","apple"]},"intentId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"nonce":{"type":"string","minLength":16,"maxLength":512},"state":{"type":"string","minLength":16,"maxLength":512},"result":{"type":"string","enum":["success","cancelled","denied","timeout","malformed","provider_failure"]},"credential":{"type":"string","minLength":16,"maxLength":512}},"required":["provider","intentId","nonce","state","result"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"accessToken":{"type":"string","minLength":16,"maxLength":512},"refreshToken":{"type":"string","minLength":16,"maxLength":512},"expiresIn":{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},"sessionId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["accessToken","refreshToken","expiresIn","sessionId"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerFederatedCompletionContract =
    CustomerFederatedCompletionContract();

final class CustomerFederatedIntentContract extends JsonOperationContract {
  CustomerFederatedIntentContract()
    : super(
        operationId: 'customerFederatedIntent',
        method: 'POST',
        path: '/api/v1/auth/customer/federated-intents',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"provider":{"type":"string","enum":["google","apple"]}},"required":["provider"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"provider":{"type":"string","enum":["google","apple"]},"intentId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"nonce":{"type":"string","minLength":16,"maxLength":512},"state":{"type":"string","minLength":16,"maxLength":512},"live":{"type":"boolean","const":false}},"required":["provider","intentId","nonce","state","live"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerFederatedIntentContract = CustomerFederatedIntentContract();

final class CustomerPasswordRecoveryContract extends JsonOperationContract {
  CustomerPasswordRecoveryContract()
    : super(
        operationId: 'customerPasswordRecovery',
        method: 'POST',
        path: '/api/v1/auth/customer/password-recoveries',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"email":{"type":"string","maxLength":254,"format":"email","pattern":"^(?!\\\\.)(?!.*\\\\.\\\\.)([A-Za-z0-9_\'+\\\\-\\\\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\\\\-]*\\\\.)+[A-Za-z]{2,}\$"}},"required":["email"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"message":{"type":"string","const":"Recovery request accepted"}},"required":["message"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerPasswordRecoveryContract = CustomerPasswordRecoveryContract();

final class CustomerPasswordResetContract extends JsonOperationContract {
  CustomerPasswordResetContract()
    : super(
        operationId: 'customerPasswordReset',
        method: 'POST',
        path: '/api/v1/auth/customer/password-resets',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"token":{"type":"string","minLength":8,"maxLength":128},"password":{"type":"string","minLength":8,"maxLength":72,"x-min-unicode-code-points":8,"x-max-utf8-bytes":72}},"required":["token","password"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"message":{"type":"string","const":"Password reset successful"}},"required":["message"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerPasswordResetContract = CustomerPasswordResetContract();

final class CustomerReauthenticateContract extends JsonOperationContract {
  CustomerReauthenticateContract()
    : super(
        operationId: 'customerReauthenticate',
        method: 'POST',
        path: '/api/v1/auth/customer/reauthentications',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"password":{"type":"string","minLength":8,"maxLength":72,"x-min-unicode-code-points":8,"x-max-utf8-bytes":72}},"required":["password"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"reauthenticationProof":{"type":"string","minLength":16,"maxLength":512},"expiresAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"}},"required":["reauthenticationProof","expiresAt"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerReauthenticateContract = CustomerReauthenticateContract();

final class CustomerRegisterContract extends JsonOperationContract {
  CustomerRegisterContract()
    : super(
        operationId: 'customerRegister',
        method: 'POST',
        path: '/api/v1/auth/customer/registrations',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"email":{"type":"string","maxLength":254,"format":"email","pattern":"^(?!\\\\.)(?!.*\\\\.\\\\.)([A-Za-z0-9_\'+\\\\-\\\\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\\\\-]*\\\\.)+[A-Za-z]{2,}\$"},"password":{"type":"string","minLength":8,"maxLength":72,"x-min-unicode-code-points":8,"x-max-utf8-bytes":72},"displayName":{"type":"string","minLength":1,"maxLength":100}},"required":["email","password","displayName"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"message":{"type":"string","const":"Registration accepted"}},"required":["message"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerRegisterContract = CustomerRegisterContract();

final class CustomerLogoutContract extends JsonOperationContract {
  CustomerLogoutContract()
    : super(
        operationId: 'customerLogout',
        method: 'DELETE',
        path: '/api/v1/auth/customer/session',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"message":{"type":"string","const":"Logged out"}},"required":["message"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerLogoutContract = CustomerLogoutContract();

final class CustomerSessionRefreshContract extends JsonOperationContract {
  CustomerSessionRefreshContract()
    : super(
        operationId: 'customerSessionRefresh',
        method: 'POST',
        path: '/api/v1/auth/customer/session-refreshes',
        audience: 'customer_refresh',
        security: _schema('[{"customerRefresh":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"refreshToken":{"type":"string","minLength":16,"maxLength":512}},"required":["refreshToken"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"accessToken":{"type":"string","minLength":16,"maxLength":512},"refreshToken":{"type":"string","minLength":16,"maxLength":512},"expiresIn":{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},"sessionId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["accessToken","refreshToken","expiresIn","sessionId"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerSessionRefreshContract = CustomerSessionRefreshContract();

final class CustomerLoginContract extends JsonOperationContract {
  CustomerLoginContract()
    : super(
        operationId: 'customerLogin',
        method: 'POST',
        path: '/api/v1/auth/customer/sessions',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"email":{"type":"string","maxLength":254,"format":"email","pattern":"^(?!\\\\.)(?!.*\\\\.\\\\.)([A-Za-z0-9_\'+\\\\-\\\\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\\\\-]*\\\\.)+[A-Za-z]{2,}\$"},"password":{"type":"string","minLength":8,"maxLength":72,"x-min-unicode-code-points":8,"x-max-utf8-bytes":72}},"required":["email","password"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"accessToken":{"type":"string","minLength":16,"maxLength":512},"refreshToken":{"type":"string","minLength":16,"maxLength":512},"expiresIn":{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},"sessionId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["accessToken","refreshToken","expiresIn","sessionId"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerLoginContract = CustomerLoginContract();

final class CustomerGetAddressesContract extends JsonOperationContract {
  CustomerGetAddressesContract()
    : super(
        operationId: 'customerGetAddresses',
        method: 'GET',
        path: '/api/v1/customer/addresses',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"data":{"type":"array","items":{"type":"object","properties":{"label":{"type":"string","minLength":1,"maxLength":100},"recipientName":{"type":"string","minLength":1,"maxLength":100},"addressLine":{"type":"string","minLength":1,"maxLength":180},"city":{"type":"string","minLength":1,"maxLength":100},"province":{"type":"string","minLength":2,"maxLength":100},"postalCode":{"type":"string","pattern":"^\\\\d{5}\$"},"countryCode":{"type":"string","const":"IT"},"deliveryNotes":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"isDefault":{"type":"boolean"},"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"archivedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]}},"required":["label","recipientName","addressLine","city","province","postalCode","countryCode","isDefault","id","version","archivedAt"],"additionalProperties":false}}},"required":["data"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerGetAddressesContract = CustomerGetAddressesContract();

final class CustomerCreateAddressContract extends JsonOperationContract {
  CustomerCreateAddressContract()
    : super(
        operationId: 'customerCreateAddress',
        method: 'POST',
        path: '/api/v1/customer/addresses',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"label":{"type":"string","minLength":1,"maxLength":100},"recipientName":{"type":"string","minLength":1,"maxLength":100},"addressLine":{"type":"string","minLength":1,"maxLength":180},"city":{"type":"string","minLength":1,"maxLength":100},"province":{"type":"string","minLength":2,"maxLength":100},"postalCode":{"type":"string","pattern":"^\\\\d{5}\$"},"countryCode":{"type":"string","const":"IT"},"deliveryNotes":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"isDefault":{"type":"boolean"}},"required":["label","recipientName","addressLine","city","province","postalCode","countryCode","isDefault"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"label":{"type":"string","minLength":1,"maxLength":100},"recipientName":{"type":"string","minLength":1,"maxLength":100},"addressLine":{"type":"string","minLength":1,"maxLength":180},"city":{"type":"string","minLength":1,"maxLength":100},"province":{"type":"string","minLength":2,"maxLength":100},"postalCode":{"type":"string","pattern":"^\\\\d{5}\$"},"countryCode":{"type":"string","const":"IT"},"deliveryNotes":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"isDefault":{"type":"boolean"},"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"archivedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]}},"required":["label","recipientName","addressLine","city","province","postalCode","countryCode","isDefault","id","version","archivedAt"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerCreateAddressContract = CustomerCreateAddressContract();

final class CustomerGetAddressContract extends JsonOperationContract {
  CustomerGetAddressContract()
    : super(
        operationId: 'customerGetAddress',
        method: 'GET',
        path: '/api/v1/customer/addresses/{id}',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["id"],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"label":{"type":"string","minLength":1,"maxLength":100},"recipientName":{"type":"string","minLength":1,"maxLength":100},"addressLine":{"type":"string","minLength":1,"maxLength":180},"city":{"type":"string","minLength":1,"maxLength":100},"province":{"type":"string","minLength":2,"maxLength":100},"postalCode":{"type":"string","pattern":"^\\\\d{5}\$"},"countryCode":{"type":"string","const":"IT"},"deliveryNotes":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"isDefault":{"type":"boolean"},"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"archivedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]}},"required":["label","recipientName","addressLine","city","province","postalCode","countryCode","isDefault","id","version","archivedAt"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerGetAddressContract = CustomerGetAddressContract();

final class CustomerUpdateAddressContract extends JsonOperationContract {
  CustomerUpdateAddressContract()
    : super(
        operationId: 'customerUpdateAddress',
        method: 'PATCH',
        path: '/api/v1/customer/addresses/{id}',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["id"],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"label":{"type":"string","minLength":1,"maxLength":100},"recipientName":{"type":"string","minLength":1,"maxLength":100},"addressLine":{"type":"string","minLength":1,"maxLength":180},"city":{"type":"string","minLength":1,"maxLength":100},"province":{"type":"string","minLength":2,"maxLength":100},"postalCode":{"type":"string","pattern":"^\\\\d{5}\$"},"countryCode":{"type":"string","const":"IT"},"deliveryNotes":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"isDefault":{"type":"boolean"},"expectedVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"}},"required":["expectedVersion"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"label":{"type":"string","minLength":1,"maxLength":100},"recipientName":{"type":"string","minLength":1,"maxLength":100},"addressLine":{"type":"string","minLength":1,"maxLength":180},"city":{"type":"string","minLength":1,"maxLength":100},"province":{"type":"string","minLength":2,"maxLength":100},"postalCode":{"type":"string","pattern":"^\\\\d{5}\$"},"countryCode":{"type":"string","const":"IT"},"deliveryNotes":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"isDefault":{"type":"boolean"},"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"archivedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]}},"required":["label","recipientName","addressLine","city","province","postalCode","countryCode","isDefault","id","version","archivedAt"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerUpdateAddressContract = CustomerUpdateAddressContract();

final class CustomerDeleteAddressContract extends JsonOperationContract {
  CustomerDeleteAddressContract()
    : super(
        operationId: 'customerDeleteAddress',
        method: 'DELETE',
        path: '/api/v1/customer/addresses/{id}',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["id"],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"expectedVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"}},"required":["expectedVersion"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"label":{"type":"string","minLength":1,"maxLength":100},"recipientName":{"type":"string","minLength":1,"maxLength":100},"addressLine":{"type":"string","minLength":1,"maxLength":180},"city":{"type":"string","minLength":1,"maxLength":100},"province":{"type":"string","minLength":2,"maxLength":100},"postalCode":{"type":"string","pattern":"^\\\\d{5}\$"},"countryCode":{"type":"string","const":"IT"},"deliveryNotes":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"isDefault":{"type":"boolean"},"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"archivedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]}},"required":["label","recipientName","addressLine","city","province","postalCode","countryCode","isDefault","id","version","archivedAt"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerDeleteAddressContract = CustomerDeleteAddressContract();

final class CustomerGetPreferencesContract extends JsonOperationContract {
  CustomerGetPreferencesContract()
    : super(
        operationId: 'customerGetPreferences',
        method: 'GET',
        path: '/api/v1/customer/preferences',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"marketingEmailOptIn":{"type":"boolean"},"securityAlertsEnabled":{"type":"boolean","const":true}},"required":["version","marketingEmailOptIn","securityAlertsEnabled"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerGetPreferencesContract = CustomerGetPreferencesContract();

final class CustomerUpdatePreferencesContract extends JsonOperationContract {
  CustomerUpdatePreferencesContract()
    : super(
        operationId: 'customerUpdatePreferences',
        method: 'PATCH',
        path: '/api/v1/customer/preferences',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"marketingEmailOptIn":{"type":"boolean"},"expectedVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"}},"required":["marketingEmailOptIn","expectedVersion"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"marketingEmailOptIn":{"type":"boolean"},"securityAlertsEnabled":{"type":"boolean","const":true}},"required":["version","marketingEmailOptIn","securityAlertsEnabled"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerUpdatePreferencesContract = CustomerUpdatePreferencesContract();

final class CustomerRequestPrivacyDeletionContract
    extends JsonOperationContract {
  CustomerRequestPrivacyDeletionContract()
    : super(
        operationId: 'customerRequestPrivacyDeletion',
        method: 'POST',
        path: '/api/v1/customer/privacy/deletions',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"reauthenticationProof":{"type":"string","minLength":16,"maxLength":512}},"required":["reauthenticationProof"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"kind":{"type":"string","enum":["export","deletion"]},"state":{"type":"string","enum":["requested","in_review","completed","cancelled","retention_required"]},"requestedAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"completedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"recoveryAction":{"anyOf":[{"type":"string","minLength":1,"maxLength":256},{"type":"null"}]}},"required":["id","kind","state","requestedAt","completedAt","recoveryAction"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerRequestPrivacyDeletionContract =
    CustomerRequestPrivacyDeletionContract();

final class CustomerRequestPrivacyExportContract extends JsonOperationContract {
  CustomerRequestPrivacyExportContract()
    : super(
        operationId: 'customerRequestPrivacyExport',
        method: 'POST',
        path: '/api/v1/customer/privacy/exports',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"reauthenticationProof":{"type":"string","minLength":16,"maxLength":512}},"required":["reauthenticationProof"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"kind":{"type":"string","enum":["export","deletion"]},"state":{"type":"string","enum":["requested","in_review","completed","cancelled","retention_required"]},"requestedAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"completedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"recoveryAction":{"anyOf":[{"type":"string","minLength":1,"maxLength":256},{"type":"null"}]}},"required":["id","kind","state","requestedAt","completedAt","recoveryAction"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerRequestPrivacyExportContract =
    CustomerRequestPrivacyExportContract();

final class CustomerGetPrivacyRequestStateContract
    extends JsonOperationContract {
  CustomerGetPrivacyRequestStateContract()
    : super(
        operationId: 'customerGetPrivacyRequestState',
        method: 'GET',
        path: '/api/v1/customer/privacy/requests/{id}',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["id"],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"kind":{"type":"string","enum":["export","deletion"]},"state":{"type":"string","enum":["requested","in_review","completed","cancelled","retention_required"]},"requestedAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"completedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"recoveryAction":{"anyOf":[{"type":"string","minLength":1,"maxLength":256},{"type":"null"}]}},"required":["id","kind","state","requestedAt","completedAt","recoveryAction"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerGetPrivacyRequestStateContract =
    CustomerGetPrivacyRequestStateContract();

final class CustomerGetProfileContract extends JsonOperationContract {
  CustomerGetProfileContract()
    : super(
        operationId: 'customerGetProfile',
        method: 'GET',
        path: '/api/v1/customer/profile',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"displayName":{"type":"string","minLength":1,"maxLength":100},"email":{"type":"string","maxLength":254,"format":"email","pattern":"^(?!\\\\.)(?!.*\\\\.\\\\.)([A-Za-z0-9_\'+\\\\-\\\\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\\\\-]*\\\\.)+[A-Za-z]{2,}\$"},"emailVerified":{"type":"boolean"},"phone":{"anyOf":[{"type":"string","pattern":"^\\\\+?[1-9]\\\\d{1,14}\$"},{"type":"null"}]},"locale":{"type":"string","const":"it-IT"}},"required":["version","displayName","email","emailVerified","phone","locale"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerGetProfileContract = CustomerGetProfileContract();

final class CustomerPatchProfileContract extends JsonOperationContract {
  CustomerPatchProfileContract()
    : super(
        operationId: 'customerPatchProfile',
        method: 'PATCH',
        path: '/api/v1/customer/profile',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"displayName":{"type":"string","minLength":1,"maxLength":100},"phone":{"anyOf":[{"type":"string","pattern":"^\\\\+?[1-9]\\\\d{1,14}\$"},{"type":"null"}]},"locale":{"type":"string","const":"it-IT"},"expectedVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"}},"required":["expectedVersion"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"displayName":{"type":"string","minLength":1,"maxLength":100},"email":{"type":"string","maxLength":254,"format":"email","pattern":"^(?!\\\\.)(?!.*\\\\.\\\\.)([A-Za-z0-9_\'+\\\\-\\\\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\\\\-]*\\\\.)+[A-Za-z]{2,}\$"},"emailVerified":{"type":"boolean"},"phone":{"anyOf":[{"type":"string","pattern":"^\\\\+?[1-9]\\\\d{1,14}\$"},{"type":"null"}]},"locale":{"type":"string","const":"it-IT"}},"required":["version","displayName","email","emailVerified","phone","locale"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerPatchProfileContract = CustomerPatchProfileContract();

final class CustomerGetSecuritySessionsContract extends JsonOperationContract {
  CustomerGetSecuritySessionsContract()
    : super(
        operationId: 'customerGetSecuritySessions',
        method: 'GET',
        path: '/api/v1/customer/security/sessions',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"data":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"createdAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"lastUsedAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"expiresAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"deviceLabel":{"anyOf":[{"type":"string","maxLength":100},{"type":"null"}]},"current":{"type":"boolean"}},"required":["id","createdAt","lastUsedAt","expiresAt","deviceLabel","current"],"additionalProperties":false}}},"required":["data"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerGetSecuritySessionsContract =
    CustomerGetSecuritySessionsContract();

final class CustomerRevokeSecuritySessionContract
    extends JsonOperationContract {
  CustomerRevokeSecuritySessionContract()
    : super(
        operationId: 'customerRevokeSecuritySession',
        method: 'DELETE',
        path: '/api/v1/customer/security/sessions/{id}',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["id"],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"message":{"type":"string","const":"Logged out"}},"required":["message"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerRevokeSecuritySessionContract =
    CustomerRevokeSecuritySessionContract();

final class PublicGetMenuCategoriesContract extends JsonOperationContract {
  PublicGetMenuCategoriesContract()
    : super(
        operationId: 'publicGetMenuCategories',
        method: 'GET',
        path: '/api/v1/menu/categories',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"catalogVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"data":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"parentCategoryId":{"anyOf":[{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},{"type":"null"}]},"name":{"type":"string","minLength":1,"maxLength":100},"description":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"displayOrder":{"type":"integer","minimum":0,"maximum":9007199254740991},"active":{"type":"boolean","const":true},"items":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"categoryId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"name":{"type":"string","minLength":1,"maxLength":200},"description":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"price":{"anyOf":[{"type":"string","maxLength":50},{"type":"null"}]},"basePriceMinor":{"anyOf":[{"type":"integer","minimum":0,"maximum":9007199254740991},{"type":"null"}]},"note":{"anyOf":[{"type":"string","maxLength":100},{"type":"null"}]},"attributes":{"type":"array","items":{"type":"string"}},"displayOrder":{"type":"integer","minimum":0,"maximum":9007199254740991},"active":{"type":"boolean","const":true},"syntheticMediaReference":{"anyOf":[{"type":"string","minLength":13,"maxLength":204,"pattern":"^local-media:[A-Za-z0-9][A-Za-z0-9._/-]*\$"},{"type":"null"}]},"isBuilderProduct":{"type":"boolean"},"optionGroups":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"name":{"type":"string","minLength":1,"maxLength":100},"description":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"displayOrder":{"type":"integer","minimum":0,"maximum":9007199254740991},"required":{"type":"boolean"},"minChoices":{"type":"integer","minimum":0,"maximum":9007199254740991},"maxChoices":{"type":"integer","minimum":0,"maximum":9007199254740991},"appliesToItemIds":{"type":"array","items":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"choices":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"optionGroupId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"name":{"type":"string","minLength":1,"maxLength":200},"description":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"displayOrder":{"type":"integer","minimum":0,"maximum":9007199254740991},"priceAdjustmentMinor":{"type":"integer","minimum":-9007199254740991,"maximum":9007199254740991},"allergenTags":{"type":"array","items":{"type":"string"}},"dietaryTags":{"type":"array","items":{"type":"string"}},"available":{"type":"boolean"},"state":{"type":"string","const":"active"}},"required":["id","version","optionGroupId","name","description","displayOrder","priceAdjustmentMinor","allergenTags","dietaryTags","available","state"],"additionalProperties":false}},"state":{"type":"string","const":"active"}},"required":["id","version","name","description","displayOrder","required","minChoices","maxChoices","appliesToItemIds","choices","state"],"additionalProperties":false}}},"required":["id","version","categoryId","name","description","displayOrder","active","syntheticMediaReference"],"additionalProperties":false}}},"required":["id","version","parentCategoryId","name","description","displayOrder","active","items"],"additionalProperties":false}}},"required":["catalogVersion","data"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final publicGetMenuCategoriesContract = PublicGetMenuCategoriesContract();

final class PublicGetMenuItemContract extends JsonOperationContract {
  PublicGetMenuItemContract()
    : super(
        operationId: 'publicGetMenuItem',
        method: 'GET',
        path: '/api/v1/menu/items/{id}',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["id"],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"catalogVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"data":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"categoryId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"name":{"type":"string","minLength":1,"maxLength":200},"description":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"price":{"anyOf":[{"type":"string","maxLength":50},{"type":"null"}]},"basePriceMinor":{"anyOf":[{"type":"integer","minimum":0,"maximum":9007199254740991},{"type":"null"}]},"note":{"anyOf":[{"type":"string","maxLength":100},{"type":"null"}]},"attributes":{"type":"array","items":{"type":"string"}},"displayOrder":{"type":"integer","minimum":0,"maximum":9007199254740991},"active":{"type":"boolean","const":true},"syntheticMediaReference":{"anyOf":[{"type":"string","minLength":13,"maxLength":204,"pattern":"^local-media:[A-Za-z0-9][A-Za-z0-9._/-]*\$"},{"type":"null"}]},"isBuilderProduct":{"type":"boolean"},"optionGroups":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"name":{"type":"string","minLength":1,"maxLength":100},"description":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"displayOrder":{"type":"integer","minimum":0,"maximum":9007199254740991},"required":{"type":"boolean"},"minChoices":{"type":"integer","minimum":0,"maximum":9007199254740991},"maxChoices":{"type":"integer","minimum":0,"maximum":9007199254740991},"appliesToItemIds":{"type":"array","items":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"choices":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"optionGroupId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"name":{"type":"string","minLength":1,"maxLength":200},"description":{"anyOf":[{"type":"string","maxLength":500},{"type":"null"}]},"displayOrder":{"type":"integer","minimum":0,"maximum":9007199254740991},"priceAdjustmentMinor":{"type":"integer","minimum":-9007199254740991,"maximum":9007199254740991},"allergenTags":{"type":"array","items":{"type":"string"}},"dietaryTags":{"type":"array","items":{"type":"string"}},"available":{"type":"boolean"},"state":{"type":"string","const":"active"}},"required":["id","version","optionGroupId","name","description","displayOrder","priceAdjustmentMinor","allergenTags","dietaryTags","available","state"],"additionalProperties":false}},"state":{"type":"string","const":"active"}},"required":["id","version","name","description","displayOrder","required","minChoices","maxChoices","appliesToItemIds","choices","state"],"additionalProperties":false}}},"required":["id","version","categoryId","name","description","displayOrder","active","syntheticMediaReference"],"additionalProperties":false}},"required":["catalogVersion","data"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final publicGetMenuItemContract = PublicGetMenuItemContract();

final class GetApiMetadataContract extends JsonOperationContract {
  GetApiMetadataContract()
    : super(
        operationId: 'getApiMetadata',
        method: 'GET',
        path: '/api/v1/metadata',
        audience: 'public',
        security: _schema('[]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"service":{"type":"string","const":"la-favola-api"},"apiVersion":{"type":"string","pattern":"^v[1-9]\\\\d*\$"},"contractVersion":{"type":"string","maxLength":64,"pattern":"^\\\\d+\\\\.\\\\d+\\\\.\\\\d+(?:-[0-9A-Za-z.-]+)?\$"},"transports":{"type":"object","properties":{"rest":{"type":"string","const":"/api/v1"},"trpc":{"type":"string","const":"/trpc"}},"required":["rest","trpc"],"additionalProperties":false}},"required":["service","apiVersion","contractVersion","transports"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final getApiMetadataContract = GetApiMetadataContract();

final class CustomerListOrdersContract extends JsonOperationContract {
  CustomerListOrdersContract()
    : super(
        operationId: 'customerListOrders',
        method: 'GET',
        path: '/api/v1/orders',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"data":{"type":"array","items":{"type":"object","properties":{"orderId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"reference":{"type":"string","minLength":1,"maxLength":64},"orderSource":{"type":"string","enum":["customer_app","staff_pos"]},"status":{"type":"string","enum":["pending_payment","placed","accepted","preparing","baking","packing","ready","out_for_delivery","delivered","picked_up","served","closed","rejected","cancelled","delivery_failed"]},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"fulfillmentContext":{"type":"object","propertyNames":{"type":"string"},"additionalProperties":{}},"lines":{"type":"array","items":{}},"subtotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"discountMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"feeMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"taxMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"totalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"currency":{"type":"string","const":"EUR"},"paymentMethod":{"type":"string","enum":["online_card","cash","external_terminal"]},"paymentStatus":{"type":"string","enum":["not_started","pending","collection_pending","authorized","paid","failed","cancelled","partially_refunded","refunded"]},"cancellationStatus":{"type":"string","enum":["not_requested","requested","approved","rejected"]},"refundStatus":{"type":"string","enum":["not_applicable","pending","partially_refunded","refunded","rejected"]},"refundMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"etaMinutes":{"anyOf":[{"type":"integer","minimum":0,"maximum":1440},{"type":"null"}]},"estimatedReadyAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"estimatedDeliveryAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"estimateUpdatedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"serverTime":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"tableId":{"anyOf":[{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},{"type":"null"}]},"tableLabel":{"anyOf":[{"type":"string","maxLength":50},{"type":"null"}]},"guestName":{"anyOf":[{"type":"string","maxLength":100},{"type":"null"}]},"createdAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"updatedAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"timeline":{"type":"array","items":{"type":"object","properties":{"type":{"type":"string","minLength":1,"maxLength":100},"priorStatus":{"anyOf":[{"type":"string"},{"type":"null"}]},"nextStatus":{"anyOf":[{"type":"string"},{"type":"null"}]},"reason":{"anyOf":[{"type":"string"},{"type":"null"}]},"occurredAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"}},"required":["type","priorStatus","nextStatus","reason","occurredAt"],"additionalProperties":false}}},"required":["orderId","reference","orderSource","status","version","fulfillmentContext","lines","subtotalMinor","discountMinor","feeMinor","taxMinor","totalMinor","currency","paymentMethod","paymentStatus","cancellationStatus","refundStatus","refundMinor","etaMinutes","estimatedReadyAt","estimatedDeliveryAt","estimateUpdatedAt","serverTime","tableId","tableLabel","guestName","createdAt","updatedAt","timeline"],"additionalProperties":false}},"page":{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},"pageSize":{"type":"integer","exclusiveMinimum":0,"maximum":100},"total":{"type":"integer","minimum":0,"maximum":9007199254740991},"summary":{"type":"object","properties":{"total":{"type":"integer","minimum":0,"maximum":9007199254740991},"active":{"type":"integer","minimum":0,"maximum":9007199254740991},"completed":{"type":"integer","minimum":0,"maximum":9007199254740991},"cancelled":{"type":"integer","minimum":0,"maximum":9007199254740991},"delivery":{"type":"integer","minimum":0,"maximum":9007199254740991},"pickup":{"type":"integer","minimum":0,"maximum":9007199254740991}},"required":["total","active","completed","cancelled","delivery","pickup"],"additionalProperties":false}},"required":["data","page","pageSize","total","summary"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerListOrdersContract = CustomerListOrdersContract();

final class CustomerCreateOrderContract extends JsonOperationContract {
  CustomerCreateOrderContract()
    : super(
        operationId: 'customerCreateOrder',
        method: 'POST',
        path: '/api/v1/orders',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"quoteId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"paymentMethod":{"type":"string","enum":["online_card","cash","external_terminal"]}},"required":["quoteId","paymentMethod"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"orderId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"reference":{"type":"string","minLength":1,"maxLength":64},"orderSource":{"type":"string","enum":["customer_app","staff_pos"]},"status":{"type":"string","enum":["pending_payment","placed","accepted","preparing","baking","packing","ready","out_for_delivery","delivered","picked_up","served","closed","rejected","cancelled","delivery_failed"]},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"fulfillmentContext":{"type":"object","propertyNames":{"type":"string"},"additionalProperties":{}},"lines":{"type":"array","items":{}},"subtotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"discountMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"feeMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"taxMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"totalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"currency":{"type":"string","const":"EUR"},"paymentMethod":{"type":"string","enum":["online_card","cash","external_terminal"]},"paymentStatus":{"type":"string","enum":["not_started","pending","collection_pending","authorized","paid","failed","cancelled","partially_refunded","refunded"]},"cancellationStatus":{"type":"string","enum":["not_requested","requested","approved","rejected"]},"refundStatus":{"type":"string","enum":["not_applicable","pending","partially_refunded","refunded","rejected"]},"refundMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"etaMinutes":{"anyOf":[{"type":"integer","minimum":0,"maximum":1440},{"type":"null"}]},"estimatedReadyAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"estimatedDeliveryAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"estimateUpdatedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"serverTime":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"tableId":{"anyOf":[{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},{"type":"null"}]},"tableLabel":{"anyOf":[{"type":"string","maxLength":50},{"type":"null"}]},"guestName":{"anyOf":[{"type":"string","maxLength":100},{"type":"null"}]},"createdAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"updatedAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"timeline":{"type":"array","items":{"type":"object","properties":{"type":{"type":"string","minLength":1,"maxLength":100},"priorStatus":{"anyOf":[{"type":"string"},{"type":"null"}]},"nextStatus":{"anyOf":[{"type":"string"},{"type":"null"}]},"reason":{"anyOf":[{"type":"string"},{"type":"null"}]},"occurredAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"}},"required":["type","priorStatus","nextStatus","reason","occurredAt"],"additionalProperties":false}}},"required":["orderId","reference","orderSource","status","version","fulfillmentContext","lines","subtotalMinor","discountMinor","feeMinor","taxMinor","totalMinor","currency","paymentMethod","paymentStatus","cancellationStatus","refundStatus","refundMinor","etaMinutes","estimatedReadyAt","estimatedDeliveryAt","estimateUpdatedAt","serverTime","tableId","tableLabel","guestName","createdAt","updatedAt","timeline"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerCreateOrderContract = CustomerCreateOrderContract();

final class CustomerGetOrderContract extends JsonOperationContract {
  CustomerGetOrderContract()
    : super(
        operationId: 'customerGetOrder',
        method: 'GET',
        path: '/api/v1/orders/{id}',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["id"],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"orderId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"reference":{"type":"string","minLength":1,"maxLength":64},"orderSource":{"type":"string","enum":["customer_app","staff_pos"]},"status":{"type":"string","enum":["pending_payment","placed","accepted","preparing","baking","packing","ready","out_for_delivery","delivered","picked_up","served","closed","rejected","cancelled","delivery_failed"]},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"fulfillmentContext":{"type":"object","propertyNames":{"type":"string"},"additionalProperties":{}},"lines":{"type":"array","items":{}},"subtotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"discountMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"feeMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"taxMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"totalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"currency":{"type":"string","const":"EUR"},"paymentMethod":{"type":"string","enum":["online_card","cash","external_terminal"]},"paymentStatus":{"type":"string","enum":["not_started","pending","collection_pending","authorized","paid","failed","cancelled","partially_refunded","refunded"]},"cancellationStatus":{"type":"string","enum":["not_requested","requested","approved","rejected"]},"refundStatus":{"type":"string","enum":["not_applicable","pending","partially_refunded","refunded","rejected"]},"refundMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"etaMinutes":{"anyOf":[{"type":"integer","minimum":0,"maximum":1440},{"type":"null"}]},"estimatedReadyAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"estimatedDeliveryAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"estimateUpdatedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"serverTime":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"tableId":{"anyOf":[{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},{"type":"null"}]},"tableLabel":{"anyOf":[{"type":"string","maxLength":50},{"type":"null"}]},"guestName":{"anyOf":[{"type":"string","maxLength":100},{"type":"null"}]},"createdAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"updatedAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"timeline":{"type":"array","items":{"type":"object","properties":{"type":{"type":"string","minLength":1,"maxLength":100},"priorStatus":{"anyOf":[{"type":"string"},{"type":"null"}]},"nextStatus":{"anyOf":[{"type":"string"},{"type":"null"}]},"reason":{"anyOf":[{"type":"string"},{"type":"null"}]},"occurredAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"}},"required":["type","priorStatus","nextStatus","reason","occurredAt"],"additionalProperties":false}}},"required":["orderId","reference","orderSource","status","version","fulfillmentContext","lines","subtotalMinor","discountMinor","feeMinor","taxMinor","totalMinor","currency","paymentMethod","paymentStatus","cancellationStatus","refundStatus","refundMinor","etaMinutes","estimatedReadyAt","estimatedDeliveryAt","estimateUpdatedAt","serverTime","tableId","tableLabel","guestName","createdAt","updatedAt","timeline"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerGetOrderContract = CustomerGetOrderContract();

final class CustomerRequestOrderCancellationContract
    extends JsonOperationContract {
  CustomerRequestOrderCancellationContract()
    : super(
        operationId: 'customerRequestOrderCancellation',
        method: 'POST',
        path: '/api/v1/orders/{id}/cancellation',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["id"],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"expectedVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"reason":{"type":"string","minLength":3,"maxLength":500}},"required":["expectedVersion","reason"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"orderId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"reference":{"type":"string","minLength":1,"maxLength":64},"orderSource":{"type":"string","enum":["customer_app","staff_pos"]},"status":{"type":"string","enum":["pending_payment","placed","accepted","preparing","baking","packing","ready","out_for_delivery","delivered","picked_up","served","closed","rejected","cancelled","delivery_failed"]},"version":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"fulfillmentContext":{"type":"object","propertyNames":{"type":"string"},"additionalProperties":{}},"lines":{"type":"array","items":{}},"subtotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"discountMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"feeMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"taxMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"totalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"currency":{"type":"string","const":"EUR"},"paymentMethod":{"type":"string","enum":["online_card","cash","external_terminal"]},"paymentStatus":{"type":"string","enum":["not_started","pending","collection_pending","authorized","paid","failed","cancelled","partially_refunded","refunded"]},"cancellationStatus":{"type":"string","enum":["not_requested","requested","approved","rejected"]},"refundStatus":{"type":"string","enum":["not_applicable","pending","partially_refunded","refunded","rejected"]},"refundMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"etaMinutes":{"anyOf":[{"type":"integer","minimum":0,"maximum":1440},{"type":"null"}]},"estimatedReadyAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"estimatedDeliveryAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"estimateUpdatedAt":{"anyOf":[{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},{"type":"null"}]},"serverTime":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"tableId":{"anyOf":[{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},{"type":"null"}]},"tableLabel":{"anyOf":[{"type":"string","maxLength":50},{"type":"null"}]},"guestName":{"anyOf":[{"type":"string","maxLength":100},{"type":"null"}]},"createdAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"updatedAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"timeline":{"type":"array","items":{"type":"object","properties":{"type":{"type":"string","minLength":1,"maxLength":100},"priorStatus":{"anyOf":[{"type":"string"},{"type":"null"}]},"nextStatus":{"anyOf":[{"type":"string"},{"type":"null"}]},"reason":{"anyOf":[{"type":"string"},{"type":"null"}]},"occurredAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"}},"required":["type","priorStatus","nextStatus","reason","occurredAt"],"additionalProperties":false}}},"required":["orderId","reference","orderSource","status","version","fulfillmentContext","lines","subtotalMinor","discountMinor","feeMinor","taxMinor","totalMinor","currency","paymentMethod","paymentStatus","cancellationStatus","refundStatus","refundMinor","etaMinutes","estimatedReadyAt","estimatedDeliveryAt","estimateUpdatedAt","serverTime","tableId","tableLabel","guestName","createdAt","updatedAt","timeline"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerRequestOrderCancellationContract =
    CustomerRequestOrderCancellationContract();

final class CustomerCreateQuoteContract extends JsonOperationContract {
  CustomerCreateQuoteContract()
    : super(
        operationId: 'customerCreateQuote',
        method: 'POST',
        path: '/api/v1/quotes',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"locationId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"lines":{"minItems":1,"maxItems":50,"type":"array","items":{"type":"object","properties":{"itemId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"quantity":{"type":"integer","exclusiveMinimum":0,"maximum":99},"choiceIds":{"default":[],"type":"array","items":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}}},"required":["itemId","quantity","choiceIds"],"additionalProperties":false}},"fulfillmentContext":{"type":"object","properties":{"type":{"type":"string","enum":["delivery","pickup"]},"addressId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"pickupTime":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"}},"required":["type"],"additionalProperties":false},"couponCode":{"type":"string","maxLength":32},"loyaltyIntent":{"default":false,"type":"boolean"}},"required":["locationId","lines","fulfillmentContext","loyaltyIntent"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"quoteId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"catalogVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"configurationVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"expiresAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"lines":{"type":"array","items":{"type":"object","properties":{"itemId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"itemVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"name":{"type":"string"},"quantity":{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},"choices":{"type":"array","items":{"type":"object","properties":{"choiceId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"name":{"type":"string"},"priceAdjustmentMinor":{"type":"integer","minimum":-9007199254740991,"maximum":9007199254740991}},"required":["choiceId","name","priceAdjustmentMinor"],"additionalProperties":false}},"unitBasePriceMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"unitTotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"lineTotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991}},"required":["itemId","itemVersion","name","quantity","choices","unitBasePriceMinor","unitTotalMinor","lineTotalMinor"],"additionalProperties":false}},"subtotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"discountMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"feeMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"taxMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"totalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"currency":{"type":"string","const":"EUR"},"appliedPromotions":{"default":[],"type":"array","items":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"code":{"type":"string"},"discountMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"stackingGroup":{"anyOf":[{"type":"string"},{"type":"null"}]}},"required":["id","code","discountMinor"],"additionalProperties":false}},"warnings":{"default":[],"type":"array","items":{"type":"object","properties":{"path":{"type":"string"},"code":{"type":"string"},"message":{"type":"string"}},"required":["path","code","message"],"additionalProperties":false}}},"required":["quoteId","catalogVersion","configurationVersion","expiresAt","lines","subtotalMinor","discountMinor","feeMinor","taxMinor","totalMinor","currency","appliedPromotions","warnings"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerCreateQuoteContract = CustomerCreateQuoteContract();

final class CustomerGetQuoteContract extends JsonOperationContract {
  CustomerGetQuoteContract()
    : super(
        operationId: 'customerGetQuote',
        method: 'GET',
        path: '/api/v1/quotes/{id}',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["id"],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"}},"required":[],"additionalProperties":false}',
            )!,
        bodySchema: null,
        responseSchema:
            _schema(
              '{"type":"object","properties":{"quoteId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"catalogVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"configurationVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"expiresAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"lines":{"type":"array","items":{"type":"object","properties":{"itemId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"itemVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"name":{"type":"string"},"quantity":{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},"choices":{"type":"array","items":{"type":"object","properties":{"choiceId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"name":{"type":"string"},"priceAdjustmentMinor":{"type":"integer","minimum":-9007199254740991,"maximum":9007199254740991}},"required":["choiceId","name","priceAdjustmentMinor"],"additionalProperties":false}},"unitBasePriceMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"unitTotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"lineTotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991}},"required":["itemId","itemVersion","name","quantity","choices","unitBasePriceMinor","unitTotalMinor","lineTotalMinor"],"additionalProperties":false}},"subtotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"discountMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"feeMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"taxMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"totalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"currency":{"type":"string","const":"EUR"},"appliedPromotions":{"default":[],"type":"array","items":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"code":{"type":"string"},"discountMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"stackingGroup":{"anyOf":[{"type":"string"},{"type":"null"}]}},"required":["id","code","discountMinor"],"additionalProperties":false}},"warnings":{"default":[],"type":"array","items":{"type":"object","properties":{"path":{"type":"string"},"code":{"type":"string"},"message":{"type":"string"}},"required":["path","code","message"],"additionalProperties":false}}},"required":["quoteId","catalogVersion","configurationVersion","expiresAt","lines","subtotalMinor","discountMinor","feeMinor","taxMinor","totalMinor","currency","appliedPromotions","warnings"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerGetQuoteContract = CustomerGetQuoteContract();

final class CustomerApplyQuotePromotionContract extends JsonOperationContract {
  CustomerApplyQuotePromotionContract()
    : super(
        operationId: 'customerApplyQuotePromotion',
        method: 'POST',
        path: '/api/v1/quotes/{id}/promotions',
        audience: 'customer',
        security: _schema('[{"customerBearer":[]}]') as List<Object?>,
        pathSchema:
            _schema(
              '{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"}},"required":["id"],"additionalProperties":false}',
            )!,
        querySchema:
            _schema(
              '{"type":"object","properties":{},"required":[],"additionalProperties":false}',
            )!,
        headerSchema:
            _schema(
              '{"type":"object","properties":{"X-Correlation-Id":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"Idempotency-Key":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[\\\\x20-\\\\x7e]+\$"}},"required":["Idempotency-Key"],"additionalProperties":false}',
            )!,
        bodySchema: _schema(
          '{"type":"object","properties":{"code":{"type":"string","maxLength":32}},"required":["code"],"additionalProperties":false}',
        ),
        responseSchema:
            _schema(
              '{"type":"object","properties":{"quoteId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"catalogVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"configurationVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"expiresAt":{"type":"string","format":"date-time","pattern":"^(?:(?:\\\\d\\\\d[2468][048]|\\\\d\\\\d[13579][26]|\\\\d\\\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\\\d|30)|(?:02)-(?:0[1-9]|1\\\\d|2[0-8])))T(?:(?:[01]\\\\d|2[0-3]):[0-5]\\\\d(?::[0-5]\\\\d(?:\\\\.\\\\d+)?)?(?:Z))\$"},"lines":{"type":"array","items":{"type":"object","properties":{"itemId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"itemVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"name":{"type":"string"},"quantity":{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},"choices":{"type":"array","items":{"type":"object","properties":{"choiceId":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"name":{"type":"string"},"priceAdjustmentMinor":{"type":"integer","minimum":-9007199254740991,"maximum":9007199254740991}},"required":["choiceId","name","priceAdjustmentMinor"],"additionalProperties":false}},"unitBasePriceMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"unitTotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"lineTotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991}},"required":["itemId","itemVersion","name","quantity","choices","unitBasePriceMinor","unitTotalMinor","lineTotalMinor"],"additionalProperties":false}},"subtotalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"discountMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"feeMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"taxMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"totalMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"currency":{"type":"string","const":"EUR"},"appliedPromotions":{"default":[],"type":"array","items":{"type":"object","properties":{"id":{"type":"string","format":"uuid","pattern":"^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\$"},"code":{"type":"string"},"discountMinor":{"type":"integer","minimum":0,"maximum":9007199254740991},"stackingGroup":{"anyOf":[{"type":"string"},{"type":"null"}]}},"required":["id","code","discountMinor"],"additionalProperties":false}},"warnings":{"default":[],"type":"array","items":{"type":"object","properties":{"path":{"type":"string"},"code":{"type":"string"},"message":{"type":"string"}},"required":["path","code","message"],"additionalProperties":false}}},"required":["quoteId","catalogVersion","configurationVersion","expiresAt","lines","subtotalMinor","discountMinor","feeMinor","taxMinor","totalMinor","currency","appliedPromotions","warnings"],"additionalProperties":false}',
            )!,
        errorSchema:
            _schema(
              '{"type":"object","properties":{"error":{"type":"object","properties":{"code":{"type":"string","enum":["VALIDATION_FAILED","VALIDATION_ERROR","FORBIDDEN","UNAUTHENTICATED","ACCESS_DENIED","NOT_FOUND","CAPABILITY_NOT_READY","CAPABILITY_NOT_AVAILABLE","VERSION_CONFLICT","QUOTE_STALE","QUOTE_EXPIRED","AVAILABILITY_CHANGED","IDEMPOTENCY_CONFLICT","PAYMENT_PENDING","RATE_LIMITED","DEPENDENCY_UNAVAILABLE","INTERNAL_ERROR","AUTH_INVALID_CREDENTIALS","AUTH_VERIFICATION_REQUIRED","AUTH_EMAIL_UNVERIFIED","AUTH_SESSION_EXPIRED","AUTH_TOKEN_EXPIRED","AUTH_TOKEN_USED","AUTH_SESSION_REVOKED","AUTH_SESSION_REUSE_DETECTED","AUTH_LINK_CONFLICT","AUTH_PROVIDER_CANCELLED","AUTH_CONFLICT","AUTH_RATE_LIMITED","CHOICE_UNAVAILABLE","CHOICE_INCOMPATIBLE","CHOICE_MIN_MAX_VIOLATION","REQUIRED_GROUP_MISSING","PROMOTION_INVALID","PROMOTION_EXPIRED","PROMOTION_INELIGIBLE","PROMOTION_USAGE_LIMIT","PROMOTION_STACKING_CONFLICT","ITEM_UNAVAILABLE","BUILDER_RULE_VIOLATION"]},"messageKey":{"type":"string","enum":["request.invalid","auth.forbidden","auth.required","resource.not_found","capability.not_ready","capability.not_available","resource.version_conflict","resource.stale","resource.availability_changed","request.idempotency_conflict","operation.pending","request.rate_limited","dependency.unavailable","operation.failed","auth.invalid_credentials","auth.verification_required","auth.email_unverified","auth.session_expired","auth.artifact_expired","auth.artifact_used","auth.session_revoked","auth.session_reuse_detected","auth.link_conflict","auth.provider_cancelled","auth.conflict","auth.rate_limited","choice.unavailable","choice.incompatible","choice.min_max_violation","choice.required_group_missing","promotion.invalid","promotion.expired","promotion.ineligible","promotion.usage_limit","promotion.stacking_conflict","item.unavailable","builder.rule_violation","quote.expired"]},"message":{"type":"string","enum":["Richiesta non valida.","Accesso negato.","Autenticazione richiesta.","Risorsa non trovata.","Operazione non disponibile.","Conflitto di versione.","Dati non piu attuali.","Disponibilita cambiata.","Conflitto di richiesta.","Operazione in elaborazione.","Troppe richieste.","Servizio temporaneamente non disponibile.","Operazione non riuscita.","Credenziali non valide.","Verifica richiesta.","Sessione scaduta.","Collegamento scaduto.","Collegamento non disponibile.","Sessione non disponibile.","Conflitto di autenticazione.","Operazione annullata.","Scelta non disponibile.","Scelta incompatibile con altre selezioni.","Numero di scelte non valido per questo gruppo.","Gruppo obbligatorio mancante.","Codice promozionale non valido.","Promozione scaduta.","Promozione non applicabile a questo ordine.","Limite di utilizzo raggiunto.","Promozione incompatibile con altre applicate.","Articolo non disponibile.","Configurazione pizza non valida.","Preventivo scaduto."]},"correlationId":{"type":"string","minLength":8,"maxLength":128,"pattern":"^[A-Za-z0-9._:-]+\$"},"retryable":{"type":"boolean"},"fieldErrors":{"maxItems":50,"type":"array","items":{"type":"object","properties":{"path":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z0-9_.[\\\\]-]+\$"},"code":{"type":"string","maxLength":64,"pattern":"^[A-Z][A-Z0-9_]*\$"}},"required":["path","code"],"additionalProperties":false}},"versionConflict":{"type":"object","properties":{"currentVersion":{"type":"string","pattern":"^[1-9]\\\\d*\$"},"changedFields":{"maxItems":20,"type":"array","items":{"type":"string","enum":["displayName","phone","locale","label","recipientName","addressLine","city","province","postalCode","countryCode","deliveryNotes","isDefault","marketingEmailOptIn","name","description","displayOrder","categoryId","state","syntheticMediaReference","required","minChoices","maxChoices","appliesToItemIds","priceAdjustmentMinor","allergenTags","dietaryTags","available","basePriceMinor","effectiveFrom","effectiveTo","groupSequence","code","discountType","discountValue","maxDiscountMinor","minOrderMinor","eligibleItemIds","eligibleCategoryIds","stackingGroup","usageLimitTotal","usageLimitPerCustomer","validFrom","validTo","active"]}}},"required":["currentVersion","changedFields"],"additionalProperties":false}},"required":["code","messageKey","message","correlationId","retryable"],"additionalProperties":false}},"required":["error"],"additionalProperties":false}',
            )!,
      );
}

final customerApplyQuotePromotionContract =
    CustomerApplyQuotePromotionContract();

final Map<String, JsonOperationContract>
kPublicCustomerOperations = Map<String, JsonOperationContract>.unmodifiable({
  'customerVerifyEmail': customerVerifyEmailContract,
  'customerResendEmailVerification': customerResendEmailVerificationContract,
  'customerFederatedCompletion': customerFederatedCompletionContract,
  'customerFederatedIntent': customerFederatedIntentContract,
  'customerPasswordRecovery': customerPasswordRecoveryContract,
  'customerPasswordReset': customerPasswordResetContract,
  'customerReauthenticate': customerReauthenticateContract,
  'customerRegister': customerRegisterContract,
  'customerLogout': customerLogoutContract,
  'customerSessionRefresh': customerSessionRefreshContract,
  'customerLogin': customerLoginContract,
  'customerGetAddresses': customerGetAddressesContract,
  'customerCreateAddress': customerCreateAddressContract,
  'customerGetAddress': customerGetAddressContract,
  'customerUpdateAddress': customerUpdateAddressContract,
  'customerDeleteAddress': customerDeleteAddressContract,
  'customerGetPreferences': customerGetPreferencesContract,
  'customerUpdatePreferences': customerUpdatePreferencesContract,
  'customerRequestPrivacyDeletion': customerRequestPrivacyDeletionContract,
  'customerRequestPrivacyExport': customerRequestPrivacyExportContract,
  'customerGetPrivacyRequestState': customerGetPrivacyRequestStateContract,
  'customerGetProfile': customerGetProfileContract,
  'customerPatchProfile': customerPatchProfileContract,
  'customerGetSecuritySessions': customerGetSecuritySessionsContract,
  'customerRevokeSecuritySession': customerRevokeSecuritySessionContract,
  'publicGetMenuCategories': publicGetMenuCategoriesContract,
  'publicGetMenuItem': publicGetMenuItemContract,
  'getApiMetadata': getApiMetadataContract,
  'customerListOrders': customerListOrdersContract,
  'customerCreateOrder': customerCreateOrderContract,
  'customerGetOrder': customerGetOrderContract,
  'customerRequestOrderCancellation': customerRequestOrderCancellationContract,
  'customerCreateQuote': customerCreateQuoteContract,
  'customerGetQuote': customerGetQuoteContract,
  'customerApplyQuotePromotion': customerApplyQuotePromotionContract,
});
