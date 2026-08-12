import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/core/session/customer_session_controller.dart';
import 'package:la_favola/week2/week2_models.dart';

import '../week2/support/deterministic_week2_gateway.dart';

final class _MemoryStore implements RefreshTokenStore {
  _MemoryStore(this.value, {this.throwOnClear = false});
  String? value;
  final bool throwOnClear;
  @override
  Future<void> clear() async {
    if (throwOnClear) throw StateError('storage clear failed');
    value = null;
  }

  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
}

void main() {
  test(
    'refresh is single-flight and stores only the rotated refresh token',
    () async {
      final gateway = DeterministicWeek2Gateway(
        latency: const Duration(milliseconds: 20),
      );
      final initial = await gateway.login(
        email: 'client@example.com',
        password: 'password123',
      );
      var refreshCalls = 0;
      final store = _MemoryStore(initial.refreshToken);
      final controller = CustomerSessionController(
        gateway: gateway,
        tokenStore: store,
        refreshSession: (token) {
          refreshCalls += 1;
          return gateway.refreshSession(token);
        },
      );
      final values = await Future.wait([
        controller.refreshSingleFlight(),
        controller.refreshSingleFlight(),
        controller.refreshSingleFlight(),
      ]);
      expect(refreshCalls, 1);
      expect(values.every((value) => value != null), isTrue);
      expect(store.value, values.first!.refreshToken);
      expect(controller.accessToken, values.first!.accessToken);
    },
  );

  test(
    'unexpected refresh failure completes every waiter without hanging',
    () async {
      final gateway = DeterministicWeek2Gateway();
      var refreshCalls = 0;
      final controller = CustomerSessionController(
        gateway: gateway,
        tokenStore: _MemoryStore('refresh-token'),
        refreshSession: (_) async {
          refreshCalls += 1;
          throw StateError('secure element unavailable');
        },
      );
      final first = controller.refreshSingleFlight();
      final second = controller.refreshSingleFlight();
      await expectLater(
        Future.wait([first, second]),
        throwsA(isA<StateError>()),
      ).timeout(const Duration(seconds: 1));
      expect(refreshCalls, 1);
      expect(controller.state.phase, SessionPhase.signedOut);
    },
  );

  test(
    'retryable refresh failure preserves encrypted token and retry state',
    () async {
      final gateway = DeterministicWeek2Gateway();
      final store = _MemoryStore('valid-refresh-token');
      final controller = CustomerSessionController(
        gateway: gateway,
        tokenStore: store,
        refreshSession:
            (_) async =>
                throw const Week2Failure(
                  kind: Week2FailureKind.timeout,
                  message: 'Temporary outage',
                  correlationId: 'test-correlation',
                  retryable: true,
                ),
      );
      await expectLater(
        controller.refreshSingleFlight(),
        throwsA(isA<Week2Failure>()),
      );
      expect(store.value, 'valid-refresh-token');
      expect(controller.state.phase, SessionPhase.restoring);
    },
  );

  test(
    'sign out clears in-memory bearer even when secure deletion fails',
    () async {
      final gateway = DeterministicWeek2Gateway();
      final controller = CustomerSessionController(
        gateway: gateway,
        tokenStore: _MemoryStore('refresh-token', throwOnClear: true),
      );
      await controller.establish(
        await gateway.login(
          email: 'client@example.com',
          password: 'password123',
        ),
      );
      await expectLater(controller.signOut(), throwsA(isA<StateError>()));
      expect(controller.accessToken, isNull);
      expect(controller.state.phase, SessionPhase.signedOut);
    },
  );
}
