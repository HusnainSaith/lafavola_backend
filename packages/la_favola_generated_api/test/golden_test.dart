// GENERATED CODE - DO NOT MODIFY BY HAND.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:test/test.dart';
import '../lib/la_favola_api.dart';

Never _fail(String message) => throw StateError(message);
void _expect(bool condition, String message) {
  if (!condition) _fail(message);
}

late final Directory _fixtureDirectory;
Object? _fixture(String name) => jsonDecode(
  File.fromUri(_fixtureDirectory.uri.resolve(name)).readAsStringSync(),
);
void _reject(void Function() action, String message) {
  try {
    action();
  } on JsonContractException {
    return;
  }
  _fail(message);
}

void main() {
  test('generated customer operation contracts', () async {
    final libraryUri = await Isolate.resolvePackageUri(
      Uri.parse('package:la_favola_generated_api/la_favola_api.dart'),
    );
    _expect(libraryUri != null, 'generated package location resolves');
    _fixtureDirectory = Directory.fromUri(
      libraryUri!.resolve('../test/fixtures/'),
    );
    _expect(
      kPublicCustomerOperations.length == 35,
      'complete customer contract inventory',
    );
    _expect(
      kPublicCustomerOperations.keys
              .where((id) => id != 'getApiMetadata')
              .length ==
          34,
      'complete customer surface',
    );
    final inventory = _fixture('operation-inventory.json') as List<Object?>;
    for (final raw in inventory) {
      final item = raw as Map<String, Object?>;
      final operation = kPublicCustomerOperations[item['operationId']];
      _expect(operation != null, 'inventory operation exists');
      _expect(
        operation!.method == item['method'] &&
            operation.path == item['path'] &&
            operation.audience == item['audience'],
        'inventory metadata matches',
      );
    }

    getApiMetadataContract.validateSuccess(_fixture('canonical-success.json'));
    final register =
        _fixture('customer-register-request.json') as Map<String, Object?>;
    customerRegisterContract.requestFromJson(register);
    final unknown = jsonDecode(jsonEncode(register)) as Map<String, Object?>;
    (unknown['body'] as Map<String, Object?>)['unknown'] = true;
    _reject(
      () => customerRegisterContract.requestFromJson(unknown),
      'unknown body field must fail',
    );
    final constrained =
        jsonDecode(jsonEncode(register)) as Map<String, Object?>;
    (constrained['body'] as Map<String, Object?>)['password'] = 'short';
    _reject(
      () => customerRegisterContract.requestFromJson(constrained),
      'password constraint must fail',
    );
    final sevenUnicode =
        jsonDecode(jsonEncode(register)) as Map<String, Object?>;
    (sevenUnicode['body'] as Map<String, Object?>)['password'] =
        '😀😀😀😀😀😀😀';
    _reject(
      () => customerRegisterContract.requestFromJson(sevenUnicode),
      'seven supplementary Unicode code points must fail',
    );
    final eightUnicode =
        jsonDecode(jsonEncode(register)) as Map<String, Object?>;
    (eightUnicode['body'] as Map<String, Object?>)['password'] =
        '😀😀😀😀😀😀😀😀';
    customerRegisterContract.requestFromJson(eightUnicode);
    final nineteenUnicode =
        jsonDecode(jsonEncode(register)) as Map<String, Object?>;
    (nineteenUnicode['body'] as Map<String, Object?>)['password'] =
        '😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀';
    _reject(
      () => customerRegisterContract.requestFromJson(nineteenUnicode),
      'passwords above 72 UTF-8 bytes must fail',
    );

    customerGetAddressContract.validateRequest(
      JsonOperationRequest(
        path: const {'id': '00000000-0000-4000-8000-000000000001'},
        headers: const {'X-Correlation-Id': 'golden-correlation-003'},
      ),
    );
    _reject(
      () => customerGetAddressContract.validateRequest(
        const JsonOperationRequest(path: {'id': '../escape'}),
      ),
      'path identifier must be validated',
    );
    _reject(
      () => customerFederatedIntentContract.validateRequest(
        const JsonOperationRequest(body: {'provider': 'google'}),
      ),
      'federated intent requires Idempotency-Key',
    );
    _expect(
      customerSessionRefreshContract.audience == 'customer_refresh',
      'refresh authority is separate',
    );
    _expect(
      jsonEncode(
        customerSessionRefreshContract.security,
      ).contains('customerRefresh'),
      'refresh scheme is separate',
    );

    final errorJson = _fixture('version-conflict-error.json');
    final error = StableErrorEnvelope.fromJson(errorJson);
    _expect(
      error.error.versionConflict?.currentVersion == '3',
      'version conflict is preserved',
    );
    _expect(
      jsonEncode(error.toJson()) == jsonEncode(errorJson),
      'version conflict round trip',
    );
    for (final required in const {
      'VALIDATION_ERROR',
      'FORBIDDEN',
      'AUTH_CONFLICT',
      'AUTH_RATE_LIMITED',
    }) {
      _expect(
        KnownStableErrorCode.values.any((value) => value.wireValue == required),
        'required alias $required',
      );
    }
    for (final unapproved in const [
      'Account exists for customer@example.test',
      'duplicate key constraint users_email_key',
      'SQLSTATE internal exception',
      'Messaggio arbitrario.',
    ]) {
      final leaked = jsonDecode(jsonEncode(errorJson)) as Map<String, Object?>;
      (leaked['error'] as Map<String, Object?>)['message'] = unapproved;
      _reject(
        () => StableErrorEnvelope.fromJson(leaked),
        'unapproved stable message must fail',
      );
    }
    final mismatched =
        jsonDecode(jsonEncode(errorJson)) as Map<String, Object?>;
    final mismatchedError = mismatched['error'] as Map<String, Object?>;
    mismatchedError['code'] = 'AUTH_INVALID_CREDENTIALS';
    _reject(
      () => StableErrorEnvelope.fromJson(mismatched),
      'message key/literal must be bound to stable code',
    );
    final operationMismatch =
        jsonDecode(jsonEncode(errorJson)) as Map<String, Object?>;
    final operationMismatchError =
        operationMismatch['error'] as Map<String, Object?>;
    operationMismatchError['code'] = 'AUTH_INVALID_CREDENTIALS';
    operationMismatchError['messageKey'] = 'resource.not_found';
    operationMismatchError['message'] = 'Risorsa non trovata.';
    _reject(
      () => customerLoginContract.validateError(operationMismatch),
      'per-operation validateError must enforce the stable message tuple',
    );

    final menuItem = {
      'catalogVersion': '1',
      'data': {
        'id': '00000000-0000-4000-8000-000000000001',
        'version': '1',
        'categoryId': '00000000-0000-4000-8000-000000000002',
        'name': 'Voce sintetica',
        'description': null,
        'displayOrder': 0,
        'active': true,
        'syntheticMediaReference': 'local-media:menu/item-1.webp',
      },
    };
    publicGetMenuItemContract.validateSuccess(menuItem);
    (menuItem['data'] as Map<String, Object?>)['syntheticMediaReference'] =
        'local-media:../secret';
    _reject(
      () => publicGetMenuItemContract.validateSuccess(menuItem),
      'media traversal must fail',
    );

    stdout.writeln(
      'PASS: 26 operation contracts plus metadata and 24 golden/negative assertions',
    );
  });
}
