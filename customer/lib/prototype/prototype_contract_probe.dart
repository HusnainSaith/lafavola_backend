import 'package:la_favola_generated_api/la_favola_api.dart';

/// Compile-only proof that the visual prototype parses the accepted generated
/// Dart contract without creating a transport or making a network request.
final class PrototypeContractProbe {
  const PrototypeContractProbe._();

  static ApiMetadata get metadata =>
      ApiMetadata.fromJson(const <String, Object?>{
        'service': 'la-favola-api',
        'apiVersion': 'v1',
        'contractVersion': '0.1.0',
        'transports': <String, Object?>{'rest': '/api/v1', 'trpc': '/trpc'},
      });

  static StableErrorEnvelope get knownEnvelope =>
      StableErrorEnvelope.fromJson(const <String, Object?>{
        'error': <String, Object?>{
          'code': 'VALIDATION_FAILED',
          'messageKey': 'request.invalid',
          'message': 'Richiesta non valida.',
          'correlationId': 'prototype-known-correlation',
          'retryable': false,
          'fieldErrors': <Object?>[
            <String, Object?>{'path': 'campoRichiesto', 'code': 'REQUIRED'},
          ],
        },
      });

  static StableErrorEnvelope get unknownEnvelope => StableErrorEnvelope(
    error: StableApiError(
      code: StableErrorCode.fromJson('PROTOTYPE_FUTURE_CODE'),
      messageKey: 'operation.failed',
      message: 'Operazione non riuscita.',
      correlationId: 'prototype-unknown-correlation',
      retryable: true,
    ),
  );

  static bool get preservesKnownError =>
      knownEnvelope.error.code.known ==
          KnownStableErrorCode.codeValidationFailed &&
      knownEnvelope.error.fieldErrors?.single.path == 'campoRichiesto';

  static bool get preservesUnknownError =>
      !unknownEnvelope.error.code.isKnown &&
      unknownEnvelope.error.code.toJson() == 'PROTOTYPE_FUTURE_CODE';

  static ContractRecoverySpecimen get knownRecovery => ContractRecoverySpecimen(
    wireCode: knownEnvelope.error.code.toJson(),
    title: 'Controlla i campi richiesti',
    message:
        'La configurazione non è stata confermata. Correggi i campi '
        'e riprova nel prototipo.',
    retryable: knownEnvelope.error.retryable,
  );

  static ContractRecoverySpecimen get unknownRecovery =>
      ContractRecoverySpecimen(
        wireCode: unknownEnvelope.error.code.toJson(),
        title: 'Risposta non riconosciuta',
        message:
            'Nessuna operazione è stata completata. Conserva le scelte locali '
            'e riprova soltanto quando il servizio è disponibile.',
        retryable: unknownEnvelope.error.retryable,
      );
}

final class ContractRecoverySpecimen {
  const ContractRecoverySpecimen({
    required this.wireCode,
    required this.title,
    required this.message,
    required this.retryable,
  });

  final String wireCode;
  final String title;
  final String message;
  final bool retryable;
}
