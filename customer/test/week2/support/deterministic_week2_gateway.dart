import 'dart:async';

import 'package:la_favola/week2/week2_models.dart';
import 'package:la_favola_generated_api/la_favola_api.dart' as generated;

final class DeterministicWeek2Gateway implements Week2Gateway {
  DeterministicWeek2Gateway({
    this.latency = const Duration(milliseconds: 20),
    Map<Week2Operation, Week2FailureKind>? faults,
    bool emptyMenu = false,
    bool emptyAddresses = false,
  }) : _faults = {...?faults},
       _emptyMenu = emptyMenu,
       _addresses = emptyAddresses ? <CustomerAddress>[] : [_fixtureAddress];

  final Duration latency;
  final Map<Week2Operation, Week2FailureKind> _faults;
  final bool _emptyMenu;

  @override
  Set<String> get configuredFederatedProviders => const {'google', 'apple'};

  @override
  bool get supportsCustomerReauthentication => true;
  CustomerProfile _profile = _fixtureProfile;
  CustomerPreferences _preferences = const CustomerPreferences(
    version: '1',
    marketingEmailOptIn: false,
    securityAlertsEnabled: true,
  );
  final List<CustomerAddress> _addresses;
  final List<PrivacyRequest> _privacyRequests = [];
  final Map<String, CustomerAddress> _createdAddresses = {};
  final Set<String> _usedRefreshTokens = {};
  String? _activeRefreshToken;
  int _sessionGeneration = 0;
  int _addressGeneration = 0;
  final List<SecuritySession> _sessions = [
    const SecuritySession(
      id: _currentSessionId,
      createdAt: _fixtureDate,
      lastUsedAt: _fixtureDate,
      expiresAt: '2026-08-01T10:00:00Z',
      deviceLabel: 'Dispositivo demo corrente',
      current: true,
    ),
    const SecuritySession(
      id: '22222222-2222-4222-8222-222222222222',
      createdAt: '2026-07-23T08:00:00Z',
      lastUsedAt: '2026-07-24T08:00:00Z',
      expiresAt: '2026-07-31T08:00:00Z',
      deviceLabel: 'Tablet demo',
      current: false,
    ),
  ];

  static const _fixtureDate = '2026-07-26T10:00:00Z';
  static const _currentSessionId = '11111111-1111-4111-8111-111111111111';
  static const _addressId = '33333333-3333-4333-8333-333333333333';
  static const _categoryId = '44444444-4444-4444-8444-444444444444';
  static const _itemId = '55555555-5555-4555-8555-555555555555';
  static const _privacyExportId = '66666666-6666-4666-8666-666666666666';
  static const _privacyDeletionId = '77777777-7777-4777-8777-777777777777';
  static const _intentId = '88888888-8888-4888-8888-888888888888';
  static const _nonce = 'local-demo-nonce-00000001';
  static const _state = 'local-demo-state-00000001';
  static const _correlationId = 'lf-mobile-local-0001';

  static const _fixtureProfile = CustomerProfile(
    version: '1',
    displayName: 'Cliente Demo',
    email: 'cliente.demo@example.invalid',
    emailVerified: true,
    phone: null,
    locale: 'it-IT',
  );

  static const _fixtureAddress = CustomerAddress(
    id: _addressId,
    version: '1',
    label: 'Indirizzo demo',
    recipientName: 'Cliente Demo',
    addressLine: 'Via sintetica 1',
    city: 'Brescia',
    province: 'BS',
    postalCode: '25100',
    countryCode: 'IT',
    deliveryNotes: 'Dati demo, non usare per consegne',
    isDefault: true,
    archivedAt: null,
  );

  static const _fixtureItem = MenuItemSummary(
    id: _itemId,
    version: '1',
    categoryId: _categoryId,
    name: '[VOCE MENU SINTETICA] Margherita demo',
    description:
        'Descrizione strutturale demo con prezzo e caratteristiche visuali.',
    price: '€7,00',
    attributes: ['vegetarian', 'gluten', 'lactose'],
    displayOrder: 1,
    syntheticMediaReference: null,
    basePriceMinor: 700,
  );

  static const _builderItem = MenuItemSummary(
    id: '11000000-0000-4000-8000-000000000011',
    version: '1',
    categoryId: _categoryId,
    name: 'Build your pizza',
    description: 'Restaurant-configured pizza choices.',
    price: '€7,00',
    displayOrder: 2,
    basePriceMinor: 700,
    isBuilderProduct: true,
    optionGroups: [
      OptionGroupSummary(
        id: '51000000-0000-4000-8000-000000000001',
        version: '1',
        name: 'Dough',
        displayOrder: 1,
        required: true,
        minChoices: 1,
        maxChoices: 1,
        appliesToItemIds: ['11000000-0000-4000-8000-000000000011'],
        state: 'active',
        choices: [
          OptionChoiceSummary(
            id: '52000000-0000-4000-8000-000000000001',
            version: '1',
            optionGroupId: '51000000-0000-4000-8000-000000000001',
            name: 'Standard pizza dough',
            displayOrder: 1,
            priceAdjustmentMinor: 0,
            allergenTags: [],
            dietaryTags: [],
            available: true,
            state: 'active',
          ),
        ],
      ),
    ],
  );

  @override
  Map<String, generated.JsonOperationContract> get generatedOperations =>
      generated.kPublicCustomerOperations;

  void setFault(Week2Operation operation, Week2FailureKind? fault) {
    if (fault == null) {
      _faults.remove(operation);
    } else {
      _faults[operation] = fault;
    }
  }

  Future<T> _perform<T>({
    required Week2Operation operation,
    required generated.JsonOperationContract contract,
    required generated.JsonOperationRequest request,
    required Object success,
    required T Function() result,
  }) async {
    try {
      contract.validateRequest(request);
    } on generated.JsonContractException catch (error) {
      final field = _fieldFromContractError(error.message);
      throw Week2Failure(
        kind: Week2FailureKind.validation,
        message: 'Controlla i campi indicati.',
        correlationId: _correlationId,
        field: field,
        fieldErrors: {if (field != null) field: 'Valore non valido.'},
      );
    }
    await Future<void>.delayed(latency);
    final fault = _faults[operation];
    if (fault != null) {
      throw _failureFor(fault);
    }
    try {
      contract.validateSuccess(success);
    } on generated.JsonContractException {
      throw const Week2Failure(
        kind: Week2FailureKind.malformedResponse,
        message: 'La risposta demo non rispetta il contratto generato.',
        correlationId: _correlationId,
      );
    }
    return result();
  }

  Future<void> _validateFailureRequest({
    required Week2Operation operation,
    required generated.JsonOperationContract contract,
    required generated.JsonOperationRequest request,
  }) async {
    try {
      contract.validateRequest(request);
    } on generated.JsonContractException catch (error) {
      final field = _fieldFromContractError(error.message);
      throw Week2Failure(
        kind: Week2FailureKind.validation,
        message: 'Controlla i campi indicati.',
        correlationId: _correlationId,
        field: field,
        fieldErrors: {if (field != null) field: 'Valore non valido.'},
      );
    }
    await Future<void>.delayed(latency);
    final fault = _faults[operation];
    if (fault != null) throw _failureFor(fault);
  }

  Week2Failure _failureFor(Week2FailureKind kind) {
    return switch (kind) {
      Week2FailureKind.validation => const Week2Failure(
        kind: Week2FailureKind.validation,
        message: 'Controlla i campi indicati.',
        correlationId: _correlationId,
        field: 'email',
      ),
      Week2FailureKind.unauthenticated => const Week2Failure(
        kind: Week2FailureKind.unauthenticated,
        message: 'Autenticazione richiesta.',
        correlationId: _correlationId,
      ),
      Week2FailureKind.verificationRequired => const Week2Failure(
        kind: Week2FailureKind.verificationRequired,
        message: 'Verifica richiesta.',
        correlationId: _correlationId,
      ),
      Week2FailureKind.forbidden => const Week2Failure(
        kind: Week2FailureKind.forbidden,
        message: 'Accesso negato.',
        correlationId: _correlationId,
      ),
      Week2FailureKind.notFound => const Week2Failure(
        kind: Week2FailureKind.notFound,
        message: 'Risorsa non trovata.',
        correlationId: _correlationId,
      ),
      Week2FailureKind.rateLimited => const Week2Failure(
        kind: Week2FailureKind.rateLimited,
        message: 'Troppe richieste. Attendi e riprova.',
        correlationId: _correlationId,
        retryable: true,
      ),
      Week2FailureKind.dependencyUnavailable => const Week2Failure(
        kind: Week2FailureKind.dependencyUnavailable,
        message: 'Servizio demo temporaneamente non disponibile.',
        correlationId: _correlationId,
        retryable: true,
      ),
      Week2FailureKind.timeout => const Week2Failure(
        kind: Week2FailureKind.timeout,
        message: 'Tempo di attesa superato.',
        correlationId: _correlationId,
        retryable: true,
      ),
      Week2FailureKind.conflict => const Week2Failure(
        kind: Week2FailureKind.conflict,
        message: 'I dati sono cambiati. Rivedi la versione corrente.',
        correlationId: _correlationId,
        currentVersion: '2',
        retryable: true,
      ),
      Week2FailureKind.sessionExpired => const Week2Failure(
        kind: Week2FailureKind.sessionExpired,
        message: 'Sessione scaduta. Accedi di nuovo.',
        correlationId: _correlationId,
      ),
      Week2FailureKind.sessionRevoked => const Week2Failure(
        kind: Week2FailureKind.sessionRevoked,
        message: 'Sessione revocata. Accedi di nuovo.',
        correlationId: _correlationId,
      ),
      Week2FailureKind.sessionReuseDetected => const Week2Failure(
        kind: Week2FailureKind.sessionReuseDetected,
        message: 'Riutilizzo della sessione rilevato. Accedi di nuovo.',
        correlationId: _correlationId,
      ),
      Week2FailureKind.providerCancelled => const Week2Failure(
        kind: Week2FailureKind.providerCancelled,
        message: 'Operazione annullata. Nessuna modifica eseguita.',
        correlationId: _correlationId,
      ),
      Week2FailureKind.providerDenied => const Week2Failure(
        kind: Week2FailureKind.providerDenied,
        message: 'Autorizzazione negata. Nessun collegamento creato.',
        correlationId: _correlationId,
      ),
      Week2FailureKind.providerUnavailable => const Week2Failure(
        kind: Week2FailureKind.providerUnavailable,
        message: 'Provider demo non disponibile.',
        correlationId: _correlationId,
        retryable: true,
      ),
      Week2FailureKind.malformedResponse => const Week2Failure(
        kind: Week2FailureKind.malformedResponse,
        message: 'Risposta demo non valida.',
        correlationId: _correlationId,
        retryable: true,
      ),
    };
  }

  generated.JsonOperationRequest _request({
    Map<String, Object?> path = const {},
    Map<String, Object?> headers = const {},
    Object? body,
  }) {
    return generated.JsonOperationRequest(
      path: path,
      headers: headers,
      body: body,
    );
  }

  String? _fieldFromContractError(String message) {
    final match = RegExp(
      r'(?:body|path|headers)\.([A-Za-z0-9_]+)',
    ).firstMatch(message);
    return match?.group(1);
  }

  CustomerSession _nextSession() {
    final value = (_sessionGeneration + 1).toString().padLeft(4, '0');
    return CustomerSession(
      accessToken: 'local-access-token-demo-$value',
      refreshToken: 'local-refresh-token-demo-$value',
      expiresIn: 900,
      sessionId: _currentSessionId,
    );
  }

  Map<String, Object?> _sessionJson(CustomerSession session) => {
    'accessToken': session.accessToken,
    'refreshToken': session.refreshToken,
    'expiresIn': session.expiresIn,
    'sessionId': session.sessionId,
  };

  CustomerSession _activateSession(
    CustomerSession session, {
    required bool rotate,
  }) {
    if (rotate && _activeRefreshToken != null) {
      _usedRefreshTokens.add(_activeRefreshToken!);
    } else if (!rotate) {
      _usedRefreshTokens.clear();
    }
    _sessionGeneration += 1;
    _activeRefreshToken = session.refreshToken;
    return session;
  }

  Map<String, Object?> _profileJson(CustomerProfile value) => {
    'version': value.version,
    'displayName': value.displayName,
    'email': value.email,
    'emailVerified': value.emailVerified,
    'phone': value.phone,
    'locale': value.locale,
  };

  Map<String, Object?> _addressJson(CustomerAddress value) => {
    'label': value.label,
    'recipientName': value.recipientName,
    'addressLine': value.addressLine,
    'city': value.city,
    'province': value.province,
    'postalCode': value.postalCode,
    'countryCode': value.countryCode,
    'deliveryNotes': value.deliveryNotes,
    'isDefault': value.isDefault,
    'id': value.id,
    'version': value.version,
    'archivedAt': value.archivedAt,
  };

  Map<String, Object?> _addressInputJson(CustomerAddress value) => {
    'label': value.label,
    'recipientName': value.recipientName,
    'addressLine': value.addressLine,
    'city': value.city,
    'province': value.province,
    'postalCode': value.postalCode,
    'countryCode': value.countryCode,
    'deliveryNotes': value.deliveryNotes,
    'isDefault': value.isDefault,
  };

  Map<String, Object?> _privacyJson(PrivacyRequest value) => {
    'id': value.id,
    'kind': value.kind == PrivacyRequestKind.export ? 'export' : 'deletion',
    'state': switch (value.state) {
      PrivacyRequestState.requested => 'requested',
      PrivacyRequestState.inReview => 'in_review',
      PrivacyRequestState.completed => 'completed',
      PrivacyRequestState.cancelled => 'cancelled',
      PrivacyRequestState.retentionRequired => 'retention_required',
    },
    'requestedAt': value.requestedAt,
    'completedAt': value.completedAt,
    'recoveryAction': value.recoveryAction,
  };

  Map<String, Object?> _itemJson(MenuItemSummary value) => {
    'id': value.id,
    'version': value.version,
    'categoryId': value.categoryId,
    'name': value.name,
    'description': value.description,
    'price': value.price,
    'basePriceMinor': value.basePriceMinor,
    'note': value.note,
    'attributes': value.attributes,
    'displayOrder': value.displayOrder,
    'active': true,
    'syntheticMediaReference': value.syntheticMediaReference,
    'isBuilderProduct': value.isBuilderProduct,
    'optionGroups': value.optionGroups
        .map(
          (group) => {
            'id': group.id,
            'version': group.version,
            'name': group.name,
            'description': group.description,
            'displayOrder': group.displayOrder,
            'required': group.required,
            'minChoices': group.minChoices,
            'maxChoices': group.maxChoices,
            'appliesToItemIds': group.appliesToItemIds,
            'state': group.state,
            'choices': group.choices
                .map(
                  (choice) => {
                    'id': choice.id,
                    'version': choice.version,
                    'optionGroupId': choice.optionGroupId,
                    'name': choice.name,
                    'description': choice.description,
                    'displayOrder': choice.displayOrder,
                    'priceAdjustmentMinor': choice.priceAdjustmentMinor,
                    'allergenTags': choice.allergenTags,
                    'dietaryTags': choice.dietaryTags,
                    'available': choice.available,
                    'state': choice.state,
                  },
                )
                .toList(growable: false),
          },
        )
        .toList(growable: false),
  };

  @override
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) {
    return _perform(
      operation: Week2Operation.register,
      contract: generated.customerRegisterContract,
      request: _request(
        headers: const {'Idempotency-Key': 'lf-register-0001'},
        body: {
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      ),
      success: const {'message': 'Registration accepted'},
      result: () {},
    );
  }

  @override
  Future<CustomerSession> login({
    required String email,
    required String password,
  }) {
    final session = _nextSession();
    return _perform(
      operation: Week2Operation.login,
      contract: generated.customerLoginContract,
      request: _request(body: {'email': email, 'password': password}),
      success: _sessionJson(session),
      result: () => _activateSession(session, rotate: false),
    );
  }

  @override
  Future<void> verifyEmail(String token) {
    return _perform(
      operation: Week2Operation.verifyEmail,
      contract: generated.customerVerifyEmailContract,
      request: _request(body: {'token': token}),
      success: const {'message': 'Email verified'},
      result: () {},
    );
  }

  @override
  Future<void> resendVerification(String email) {
    return _perform(
      operation: Week2Operation.resendVerification,
      contract: generated.customerResendEmailVerificationContract,
      request: _request(body: {'email': email}),
      success: const {'message': 'Verification request accepted'},
      result: () {},
    );
  }

  @override
  Future<void> requestPasswordRecovery(String email) {
    return _perform(
      operation: Week2Operation.requestRecovery,
      contract: generated.customerPasswordRecoveryContract,
      request: _request(body: {'email': email}),
      success: const {'message': 'Recovery request accepted'},
      result: () {},
    );
  }

  @override
  Future<void> resetPassword({
    required String code,
    required String password,
  }) {
    return _perform(
      operation: Week2Operation.resetPassword,
      contract: generated.customerPasswordResetContract,
      request: _request(body: {'code': code, 'password': password}),
      success: const {'message': 'Password reset successful'},
      result: () {},
    );
  }

  @override
  Future<ProviderIntent> startFederated(String provider) {
    const result = ProviderIntent(
      provider: 'google',
      intentId: _intentId,
      nonce: _nonce,
      state: _state,
      live: false,
    );
    final value = ProviderIntent(
      provider: provider,
      intentId: result.intentId,
      nonce: result.nonce,
      state: result.state,
      live: result.live,
    );
    return _perform(
      operation: Week2Operation.startFederated,
      contract: generated.customerFederatedIntentContract,
      request: _request(
        headers: const {'Idempotency-Key': 'lf-federated-intent-0001'},
        body: {'provider': provider},
      ),
      success: {
        'provider': provider,
        'intentId': value.intentId,
        'nonce': value.nonce,
        'state': value.state,
        'live': false,
      },
      result: () => value,
    );
  }

  @override
  Future<CustomerSession> completeFederated({
    required ProviderIntent intent,
    required String result,
  }) async {
    final request = _request(
      headers: {
        'Idempotency-Key': 'lf-federated-${intent.provider}-${intent.intentId}',
      },
      body: {
        'provider': intent.provider,
        'intentId': intent.intentId,
        'nonce': intent.nonce,
        'state': intent.state,
        'result': result,
        if (result == 'success') 'credential': 'local-demo-credential-0001',
      },
    );
    final session = _nextSession();
    if (result == 'success') {
      return _perform(
        operation: Week2Operation.completeFederated,
        contract: generated.customerFederatedCompletionContract,
        request: request,
        success: _sessionJson(session),
        result: () => _activateSession(session, rotate: false),
      );
    }
    await _validateFailureRequest(
      operation: Week2Operation.completeFederated,
      contract: generated.customerFederatedCompletionContract,
      request: request,
    );
    throw switch (result) {
      'cancelled' => _failureFor(Week2FailureKind.providerCancelled),
      'denied' => _failureFor(Week2FailureKind.providerDenied),
      'timeout' => _failureFor(Week2FailureKind.timeout),
      'malformed' => _failureFor(Week2FailureKind.malformedResponse),
      'provider_failure' => _failureFor(Week2FailureKind.providerUnavailable),
      _ => _failureFor(Week2FailureKind.malformedResponse),
    };
  }

  @override
  Future<String> reauthenticate(String password) async {
    await Future<void>.delayed(latency);
    final fault = _faults[Week2Operation.reauthenticate];
    if (fault != null) throw _failureFor(fault);
    if (password.runes.length < 8) {
      throw const Week2Failure(
        kind: Week2FailureKind.validation,
        message: 'Controlla i campi indicati.',
        correlationId: _correlationId,
        field: 'password',
        fieldErrors: {'password': 'Valore non valido.'},
      );
    }
    return 'local-reauthentication-proof-0001';
  }

  @override
  Future<CustomerSession> refreshSession(String refreshToken) {
    if (_usedRefreshTokens.contains(refreshToken)) {
      return Future.error(_failureFor(Week2FailureKind.sessionReuseDetected));
    }
    if (_activeRefreshToken != refreshToken) {
      return Future.error(_failureFor(Week2FailureKind.sessionRevoked));
    }
    final session = _nextSession();
    return _perform(
      operation: Week2Operation.refreshSession,
      contract: generated.customerSessionRefreshContract,
      request: _request(body: {'refreshToken': refreshToken}),
      success: _sessionJson(session),
      result: () => _activateSession(session, rotate: true),
    );
  }

  @override
  Future<void> logout() {
    return _perform(
      operation: Week2Operation.logout,
      contract: generated.customerLogoutContract,
      request: _request(),
      success: const {'message': 'Logged out'},
      result: () {
        if (_activeRefreshToken != null) {
          _usedRefreshTokens.add(_activeRefreshToken!);
        }
        _activeRefreshToken = null;
      },
    );
  }

  @override
  Future<CustomerProfile> getProfile() {
    return _perform(
      operation: Week2Operation.getProfile,
      contract: generated.customerGetProfileContract,
      request: _request(),
      success: _profileJson(_profile),
      result: () => _profile,
    );
  }

  @override
  Future<CustomerProfile> updateProfile({
    required String displayName,
    required String? phone,
    required String expectedVersion,
  }) {
    final next = _profile.copyWith(
      version: (int.parse(_profile.version) + 1).toString(),
      displayName: displayName,
      phone: phone,
      clearPhone: phone == null,
    );
    return _perform(
      operation: Week2Operation.updateProfile,
      contract: generated.customerPatchProfileContract,
      request: _request(
        headers: const {'Idempotency-Key': 'lf-profile-update-0001'},
        body: {
          'displayName': displayName,
          'phone': phone,
          'locale': 'it-IT',
          'expectedVersion': expectedVersion,
        },
      ),
      success: _profileJson(next),
      result: () {
        _profile = next;
        return next;
      },
    );
  }

  @override
  Future<List<CustomerAddress>> getAddresses() {
    final active = _addresses
        .where((value) => value.archivedAt == null)
        .toList(growable: false);
    return _perform(
      operation: Week2Operation.getAddresses,
      contract: generated.customerGetAddressesContract,
      request: _request(),
      success: {'data': active.map(_addressJson).toList(growable: false)},
      result: () => List.unmodifiable(active),
    );
  }

  String _addressFingerprint(CustomerAddress value) => [
    value.label,
    value.recipientName,
    value.addressLine,
    value.city,
    value.province,
    value.postalCode,
    value.countryCode,
    value.deliveryNotes ?? '',
    value.isDefault.toString(),
  ].join('\u001f');

  String _nextAddressId() {
    final suffix = (_addressGeneration + 1).toString().padLeft(12, '0');
    return '33333333-3333-4333-8333-$suffix';
  }

  @override
  Future<CustomerAddress> createAddress(CustomerAddress input) {
    final fingerprint = _addressFingerprint(input);
    final prior = _createdAddresses[fingerprint];
    final next =
        prior ??
        CustomerAddress(
          id: _nextAddressId(),
          version: '1',
          label: input.label,
          recipientName: input.recipientName,
          addressLine: input.addressLine,
          city: input.city,
          province: input.province,
          postalCode: input.postalCode,
          countryCode: 'IT',
          deliveryNotes: input.deliveryNotes,
          isDefault: input.isDefault,
          archivedAt: null,
        );
    return _perform(
      operation: Week2Operation.createAddress,
      contract: generated.customerCreateAddressContract,
      request: _request(
        headers: {'Idempotency-Key': 'lf-address-create-${next.id}'},
        body: _addressInputJson(input),
      ),
      success: _addressJson(next),
      result: () {
        if (prior != null) return prior;
        if (next.isDefault) {
          for (var index = 0; index < _addresses.length; index++) {
            _addresses[index] = _addresses[index].copyWith(isDefault: false);
          }
        }
        _addressGeneration += 1;
        _addresses.add(next);
        _createdAddresses[fingerprint] = next;
        return next;
      },
    );
  }

  @override
  Future<CustomerAddress> updateAddress(CustomerAddress input) {
    final index = _addresses.indexWhere((value) => value.id == input.id);
    if (index < 0) {
      return Future.error(_failureFor(Week2FailureKind.notFound));
    }
    final next = input.copyWith(
      version: (int.parse(input.version) + 1).toString(),
    );
    return _perform(
      operation: Week2Operation.updateAddress,
      contract: generated.customerUpdateAddressContract,
      request: _request(
        path: {'id': input.id},
        headers: {'Idempotency-Key': 'lf-address-update--'},
        body: {..._addressInputJson(input), 'expectedVersion': input.version},
      ),
      success: _addressJson(next),
      result: () {
        if (next.isDefault) {
          for (var other = 0; other < _addresses.length; other++) {
            _addresses[other] = _addresses[other].copyWith(isDefault: false);
          }
        }
        _addresses[index] = next;
        return next;
      },
    );
  }

  @override
  Future<CustomerAddress> archiveAddress(CustomerAddress input) {
    final index = _addresses.indexWhere((value) => value.id == input.id);
    if (index < 0) {
      return Future.error(_failureFor(Week2FailureKind.notFound));
    }
    final next = input.copyWith(
      version: (int.parse(input.version) + 1).toString(),
      archivedAt: _fixtureDate,
      isDefault: false,
    );
    return _perform(
      operation: Week2Operation.archiveAddress,
      contract: generated.customerDeleteAddressContract,
      request: _request(
        path: {'id': input.id},
        headers: {'Idempotency-Key': 'lf-address-archive--'},
        body: {'expectedVersion': input.version},
      ),
      success: _addressJson(next),
      result: () {
        if (next.isDefault) {
          for (var other = 0; other < _addresses.length; other++) {
            _addresses[other] = _addresses[other].copyWith(isDefault: false);
          }
        }
        _addresses[index] = next;
        return next;
      },
    );
  }

  @override
  Future<CustomerPreferences> getPreferences() {
    final success = {
      'version': _preferences.version,
      'marketingEmailOptIn': _preferences.marketingEmailOptIn,
      'securityAlertsEnabled': true,
    };
    return _perform(
      operation: Week2Operation.getPreferences,
      contract: generated.customerGetPreferencesContract,
      request: _request(),
      success: success,
      result: () => _preferences,
    );
  }

  @override
  Future<CustomerPreferences> updatePreferences({
    required bool marketingEmailOptIn,
    required String expectedVersion,
  }) {
    final next = CustomerPreferences(
      version: (int.parse(_preferences.version) + 1).toString(),
      marketingEmailOptIn: marketingEmailOptIn,
      securityAlertsEnabled: true,
    );
    return _perform(
      operation: Week2Operation.updatePreferences,
      contract: generated.customerUpdatePreferencesContract,
      request: _request(
        headers: const {'Idempotency-Key': 'lf-preferences-update-0001'},
        body: {
          'marketingEmailOptIn': marketingEmailOptIn,
          'expectedVersion': expectedVersion,
        },
      ),
      success: {
        'version': next.version,
        'marketingEmailOptIn': next.marketingEmailOptIn,
        'securityAlertsEnabled': true,
      },
      result: () {
        _preferences = next;
        return next;
      },
    );
  }

  @override
  Future<List<SecuritySession>> getSecuritySessions() {
    final success = {
      'data': _sessions
          .map(
            (value) => {
              'id': value.id,
              'createdAt': value.createdAt,
              'lastUsedAt': value.lastUsedAt,
              'expiresAt': value.expiresAt,
              'deviceLabel': value.deviceLabel,
              'current': value.current,
            },
          )
          .toList(growable: false),
    };
    return _perform(
      operation: Week2Operation.getSecuritySessions,
      contract: generated.customerGetSecuritySessionsContract,
      request: _request(),
      success: success,
      result: () => List.unmodifiable(_sessions),
    );
  }

  @override
  Future<void> revokeSecuritySession(String id) {
    return _perform(
      operation: Week2Operation.revokeSecuritySession,
      contract: generated.customerRevokeSecuritySessionContract,
      request: _request(path: {'id': id}),
      success: const {'message': 'Logged out'},
      result: () {
        _sessions.removeWhere((value) => value.id == id && !value.current);
      },
    );
  }

  Future<PrivacyRequest> _requestPrivacy({
    required PrivacyRequestKind kind,
    required String proof,
  }) {
    final operation =
        kind == PrivacyRequestKind.export
            ? Week2Operation.requestPrivacyExport
            : Week2Operation.requestPrivacyDeletion;
    final contract =
        kind == PrivacyRequestKind.export
            ? generated.customerRequestPrivacyExportContract
            : generated.customerRequestPrivacyDeletionContract;
    final existing =
        _privacyRequests.where((value) => value.kind == kind).firstOrNull;
    final next =
        existing ??
        PrivacyRequest(
          id:
              kind == PrivacyRequestKind.export
                  ? _privacyExportId
                  : _privacyDeletionId,
          kind: kind,
          state:
              kind == PrivacyRequestKind.export
                  ? PrivacyRequestState.requested
                  : PrivacyRequestState.retentionRequired,
          requestedAt: _fixtureDate,
          completedAt: null,
          recoveryAction:
              kind == PrivacyRequestKind.deletion
                  ? 'Contatta il supporto dopo la revisione della conservazione.'
                  : 'Controlla lo stato della richiesta demo.',
        );
    return _perform(
      operation: operation,
      contract: contract,
      request: _request(
        headers: {
          'Idempotency-Key':
              kind == PrivacyRequestKind.export
                  ? 'lf-privacy-export-0001'
                  : 'lf-privacy-deletion-0001',
        },
        body: {'reauthenticationProof': proof},
      ),
      success: _privacyJson(next),
      result: () {
        if (existing == null) _privacyRequests.add(next);
        return next;
      },
    );
  }

  @override
  Future<PrivacyRequest> requestPrivacyExport(String reauthenticationProof) {
    return _requestPrivacy(
      kind: PrivacyRequestKind.export,
      proof: reauthenticationProof,
    );
  }

  @override
  Future<PrivacyRequest> requestPrivacyDeletion(String reauthenticationProof) {
    return _requestPrivacy(
      kind: PrivacyRequestKind.deletion,
      proof: reauthenticationProof,
    );
  }

  @override
  Future<PrivacyRequest> getPrivacyRequest(String id) {
    final index = _privacyRequests.indexWhere((request) => request.id == id);
    if (index < 0) {
      return Future.error(_failureFor(Week2FailureKind.notFound));
    }
    final value = _privacyRequests[index];
    return _perform(
      operation: Week2Operation.getPrivacyRequest,
      contract: generated.customerGetPrivacyRequestStateContract,
      request: _request(path: {'id': id}),
      success: _privacyJson(value),
      result: () => value,
    );
  }

  @override
  Future<MenuSnapshot> getMenu() {
    final categories =
        _emptyMenu
            ? const <MenuCategory>[]
            : const [
              MenuCategory(
                id: _categoryId,
                version: '1',
                parentCategoryId: null,
                name: '[CATEGORIA SINTETICA] Pizze demo',
                description: 'Struttura demo, non catalogo di produzione.',
                displayOrder: 1,
                items: [_fixtureItem, _builderItem],
              ),
            ];
    final success = {
      'catalogVersion': '1',
      'data': categories
          .map(
            (value) => {
              'id': value.id,
              'version': value.version,
              'parentCategoryId': value.parentCategoryId,
              'name': value.name,
              'description': value.description,
              'displayOrder': value.displayOrder,
              'active': true,
              'items': value.items.map(_itemJson).toList(growable: false),
            },
          )
          .toList(growable: false),
    };
    return _perform(
      operation: Week2Operation.getMenu,
      contract: generated.publicGetMenuCategoriesContract,
      request: _request(),
      success: success,
      result:
          () => MenuSnapshot(
            catalogVersion: '1',
            categories: List.unmodifiable(categories),
          ),
    );
  }

  @override
  Future<MenuItemSummary> getMenuItem(String id) {
    final item = id == _builderItem.id ? _builderItem : _fixtureItem;
    if (id != _fixtureItem.id && id != _builderItem.id) {
      return Future.error(_failureFor(Week2FailureKind.notFound));
    }
    return _perform(
      operation: Week2Operation.getMenuItem,
      contract: generated.publicGetMenuItemContract,
      request: _request(path: {'id': id}),
      success: {'catalogVersion': '1', 'data': _itemJson(item)},
      result: () => item,
    );
  }

  @override
  Future<FulfillmentAvailability> getFulfillmentAvailability({
    required FulfillmentType type,
    String? date,
    String? menuItemId,
  }) async {
    final serverNow = DateTime.utc(2026, 7, 30, 10);
    return FulfillmentAvailability(
      serverNow: serverNow.toIso8601String(),
      timezone: 'Europe/Rome',
      date: date ?? '2026-07-30',
      orderType: type,
      leadMinutes: type == FulfillmentType.delivery ? 30 : 15,
      asapAvailable: true,
      estimatedReadyAt:
          serverNow.add(const Duration(minutes: 15)).toIso8601String(),
      estimatedDeliveryAt:
          type == FulfillmentType.delivery
              ? serverNow.add(const Duration(minutes: 30)).toIso8601String()
              : null,
      slots: [
        FulfillmentSlot(
          scheduledFor: DateTime.utc(2026, 7, 30, 18).toIso8601String(),
          localTime: '20:00',
        ),
      ],
    );
  }

  @override
  Future<Quote> createQuote({
    required String locationId,
    required List<QuoteLineInput> lines,
    required FulfillmentContext fulfillmentContext,
    String? couponCode,
    bool loyaltyIntent = false,
  }) async {
    return _fixtureQuote;
  }

  @override
  Future<OrderReceipt> submitOrder(
    String quoteId,
    PaymentMethod paymentMethod,
  ) async {
    final quote = await getQuote(quoteId);
    final serverNow = DateTime.utc(2026, 7, 30, 10);
    return OrderReceipt(
      orderId: 'order-local-${quote.quoteId}',
      reference: 'LF-LOCAL-000001',
      status:
          paymentMethod == PaymentMethod.onlineCard
              ? 'pending_payment'
              : 'placed',
      totalMinor: quote.totalMinor,
      currency: quote.currency,
      createdAt: serverNow.toIso8601String(),
      fulfillmentType: 'delivery',
      paymentMethod: paymentMethod,
      paymentStatus:
          paymentMethod == PaymentMethod.onlineCard
              ? 'pending'
              : 'collection_pending',
      estimatedReadyAt:
          serverNow.add(const Duration(minutes: 15)).toIso8601String(),
      estimatedDeliveryAt:
          serverNow.add(const Duration(minutes: 30)).toIso8601String(),
      serverTime: serverNow.toIso8601String(),
    );
  }

  @override
  Future<List<OrderReceipt>> getOrders() async => [
    await submitOrder(_fixtureQuote.quoteId, PaymentMethod.cash),
  ];

  @override
  Future<OrderReceipt> getOrder(String orderId) async =>
      (await getOrders()).first;

  @override
  Future<CustomerOrderReceiptDocument> getOrderReceipt(String orderId) async {
    final order = await getOrder(orderId);
    return CustomerOrderReceiptDocument(
      documentType: 'order_receipt',
      fiscalDocument: false,
      issuedAt: order.createdAt,
      restaurant: const ReceiptRestaurant(
        name: 'La Favola',
        address: ['Brescia, Italia'],
      ),
      order: ReceiptOrder(
        number: order.reference,
        type: order.fulfillmentType,
        status: order.status,
        paymentStatus: order.paymentStatus,
        paymentMethod: 'cash',
        currency: order.currency,
        items: const [
          ReceiptOrderItem(
            name: 'Pizza Margherita',
            size: 'Classica',
            quantity: 1,
            unitPriceMinor: 1000,
            lineTotalMinor: 1000,
            options: [],
          ),
        ],
        totals: ReceiptTotals(
          subtotalMinor: order.totalMinor,
          optionChargesMinor: 0,
          discountMinor: 0,
          deliveryFeeMinor: 0,
          taxMinor: 0,
          grandTotalMinor: order.totalMinor,
        ),
      ),
      notice: 'Order receipt only.',
    );
  }

  @override
  Stream<OrderRealtimeEvent> watchOrderEvents(String orderId) =>
      const Stream<OrderRealtimeEvent>.empty();

  @override
  Future<OrderReceipt> requestOrderCancellation({
    required String orderId,
    required String expectedVersion,
    required String reason,
  }) async {
    final order = await getOrder(orderId);
    return OrderReceipt(
      orderId: order.orderId,
      reference: order.reference,
      status: 'cancelled',
      totalMinor: order.totalMinor,
      currency: order.currency,
      createdAt: order.createdAt,
      version: (int.parse(expectedVersion) + 1).toString(),
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      cancellationStatus: 'approved',
      refundStatus: order.refundStatus,
      refundMinor: order.refundMinor,
      timeline: [
        ...order.timeline,
        OrderTimelineEvent(
          type: 'customer_cancelled',
          priorStatus: order.status,
          nextStatus: 'cancelled',
          reason: reason,
          occurredAt: DateTime.utc(2026, 7, 30, 10, 5).toIso8601String(),
        ),
      ],
    );
  }

  @override
  Future<Quote> getQuote(String quoteId) async {
    return _fixtureQuote;
  }

  @override
  Future<Quote> applyPromotion(String quoteId, String code) async {
    return _fixtureQuote;
  }

  static const _fixtureQuote = Quote(
    quoteId: 'quote-demo-1',
    catalogVersion: '1',
    configurationVersion: '1',
    expiresAt: '2026-08-01T10:00:00Z',
    lines: [],
    subtotalMinor: 1000,
    discountMinor: 0,
    feeMinor: 200,
    taxMinor: 0,
    totalMinor: 1200,
    currency: 'EUR',
    appliedPromotions: [],
    warnings: [],
  );
}
