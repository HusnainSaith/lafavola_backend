import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:la_favola/week2/week2_http_gateway.dart';
import 'package:la_favola/week2/week2_models.dart';

abstract interface class RefreshTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

final class SecureRefreshTokenStore implements RefreshTokenStore {
  const SecureRefreshTokenStore([this.storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage storage;
  static const _key = 'la_favola_customer_refresh_token';

  @override
  Future<String?> read() => storage.read(key: _key);
  @override
  Future<void> write(String token) => storage.write(key: _key, value: token);
  @override
  Future<void> clear() => storage.delete(key: _key);
}

enum SessionPhase { restoring, signedOut, authenticated }

final class CustomerSessionState {
  const CustomerSessionState({required this.phase, this.session, this.notice});
  const CustomerSessionState.restoring() : this(phase: SessionPhase.restoring);
  const CustomerSessionState.signedOut([String? notice])
    : this(phase: SessionPhase.signedOut, notice: notice);
  const CustomerSessionState.authenticated(CustomerSession session)
    : this(phase: SessionPhase.authenticated, session: session);

  final SessionPhase phase;
  final CustomerSession? session;
  final String? notice;
  bool get isAuthenticated => phase == SessionPhase.authenticated;
}

final customerGatewayProvider = Provider<Week2Gateway>(
  (ref) => HttpWeek2Gateway.fromEnvironment(),
);
final refreshTokenStoreProvider = Provider<RefreshTokenStore>(
  (ref) => const SecureRefreshTokenStore(),
);

final customerSessionProvider =
    StateNotifierProvider<CustomerSessionController, CustomerSessionState>((
      ref,
    ) {
      final controller = CustomerSessionController(
        gateway: ref.watch(customerGatewayProvider),
        tokenStore: ref.watch(refreshTokenStoreProvider),
      );
      unawaited(controller.restore());
      return controller;
    });

final class CustomerSessionController
    extends StateNotifier<CustomerSessionState> {
  CustomerSessionController({
    required this.gateway,
    required this.tokenStore,
    Future<CustomerSession> Function(String token)? refreshSession,
  }) : _refreshSession = refreshSession ?? gateway.refreshSession,
       super(const CustomerSessionState.restoring()) {
    if (gateway is HttpWeek2Gateway) {
      (gateway as HttpWeek2Gateway).configureSessionCoordinator(
        refreshSingleFlight,
      );
    }
  }

  final Week2Gateway gateway;
  final RefreshTokenStore tokenStore;
  final Future<CustomerSession> Function(String token) _refreshSession;
  Future<CustomerSession?>? _refreshInFlight;

  String? get accessToken => state.session?.accessToken;

  Future<void> restore() async {
    final refreshToken = await tokenStore.read();
    if (refreshToken == null || refreshToken.isEmpty) {
      state = const CustomerSessionState.signedOut();
      return;
    }
    try {
      final session = await _refresh(refreshToken);
      if (session == null) {
        state = const CustomerSessionState.signedOut();
      }
    } on Week2Failure catch (failure) {
      if (_invalidatesSession(failure)) {
        state = CustomerSessionState.signedOut(failure.message);
      } else {
        state = CustomerSessionState(
          phase: SessionPhase.restoring,
          notice: failure.message,
        );
      }
    } catch (_) {
      // Secure storage can be temporarily unavailable while the device is locked.
      // Keep the user signed out without exposing implementation details.
      state = const CustomerSessionState.signedOut();
    }
  }

  Future<void> establish(CustomerSession session) async {
    await tokenStore.write(session.refreshToken);
    state = CustomerSessionState.authenticated(session);
  }

  Future<CustomerSession?> refreshSingleFlight() async {
    final token = state.session?.refreshToken ?? await tokenStore.read();
    if (token == null || token.isEmpty) return null;
    return _refresh(token);
  }

  Future<CustomerSession?> _refresh(String token) {
    final active = _refreshInFlight;
    if (active != null) return active;
    final completer = Completer<CustomerSession?>();
    _refreshInFlight = completer.future;
    () async {
      try {
        final session = await _refreshSession(token);
        await tokenStore.write(session.refreshToken);
        state = CustomerSessionState.authenticated(session);
        completer.complete(session);
      } on Week2Failure catch (failure, stackTrace) {
        if (_invalidatesSession(failure)) {
          try {
            await tokenStore.clear();
          } catch (_) {
            // In-memory invalidation still wins when secure cleanup fails.
          }
          state = CustomerSessionState.signedOut(failure.message);
        } else {
          state = CustomerSessionState(
            phase: SessionPhase.restoring,
            session: state.session,
            notice: failure.message,
          );
        }
        completer.completeError(failure, stackTrace);
      } catch (error, stackTrace) {
        state = const CustomerSessionState.signedOut();
        completer.completeError(error, stackTrace);
      } finally {
        _refreshInFlight = null;
      }
    }();
    return completer.future;
  }

  bool _invalidatesSession(Week2Failure failure) =>
      !failure.retryable &&
      const {
        Week2FailureKind.unauthenticated,
        Week2FailureKind.sessionExpired,
        Week2FailureKind.sessionRevoked,
        Week2FailureKind.sessionReuseDetected,
      }.contains(failure.kind);

  Future<void> signOut() async {
    state = const CustomerSessionState.signedOut();
    try {
      try {
        await gateway.logout();
      } on Week2Failure {
        // Remote revocation is best effort after local bearer removal.
      }
      await tokenStore.clear();
    } finally {
      state = const CustomerSessionState.signedOut();
    }
  }
}
