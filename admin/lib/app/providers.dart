import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';
import 'package:la_favola_admin/core/config/app_config.dart';
import 'package:la_favola_admin/core/session/secure_session_store.dart';
import 'package:la_favola_admin/features/pos/application/pos_controller.dart';
import 'package:la_favola_admin/features/pos/data/pos_repository.dart';
import 'package:la_favola_admin/features/printing/application/thermal_printer_controller.dart';

final apiClientProvider = Provider<AdminApiClient>(
  (_) => AdminApiClient(baseUrl: AppConfig.apiBaseUrl),
);

final sessionStoreProvider = Provider<SecureSessionStore>(
  (_) => SecureSessionStore(),
);

final posRepositoryProvider = Provider<PosRepository>(
  (ref) => PosRepository(ref.watch(apiClientProvider)),
);

final posControllerProvider = StateNotifierProvider<PosController, PosState>(
  (ref) => PosController(ref.watch(posRepositoryProvider)),
);

final thermalPrinterControllerProvider =
    StateNotifierProvider<ThermalPrinterController, ThermalPrinterState>((ref) {
      final controller = ThermalPrinterController();
      ref.onDispose(controller.disposePrinter);
      return controller;
    });

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);
  await for (final results in connectivity.onConnectivityChanged) {
    yield !results.contains(ConnectivityResult.none);
  }
});

enum SessionStatus { restoring, signedOut, signingIn, authenticated, failure }

class SessionState {
  const SessionState({required this.status, this.session, this.message});

  const SessionState.restoring() : this(status: SessionStatus.restoring);

  final SessionStatus status;
  final AdminSession? session;
  final String? message;

  bool get isAuthenticated => status == SessionStatus.authenticated;
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(
    this._api,
    this._store, {
    bool restoreOnCreate = true,
    SessionState initialState = const SessionState.restoring(),
  }) : super(initialState) {
    _api.setUnauthorizedHandler(_refreshAfterUnauthorized);
    if (restoreOnCreate) unawaited(restore());
  }

  final AdminApiClient _api;
  final SecureSessionStore _store;

  Future<String?> _refreshAfterUnauthorized() async {
    try {
      final token = await _store.readRefreshToken();
      if (token == null || token.isEmpty) return null;
      final refreshed = await _api.refresh(token);
      await _store.saveRefreshToken(refreshed.refreshToken);
      final current = state.session;
      state = SessionState(
        status: SessionStatus.authenticated,
        session: AdminSession(
          accessToken: refreshed.accessToken,
          refreshToken: refreshed.refreshToken,
          roleName: current?.roleName ?? refreshed.roleName,
          user: current?.user ?? refreshed.user,
        ),
      );
      return refreshed.accessToken;
    } catch (_) {
      await _store.clear();
      _api.setAccessToken(null);
      state = const SessionState(status: SessionStatus.signedOut);
      return null;
    }
  }

  Future<void> restore() async {
    try {
      final token = await _store.readRefreshToken();
      if (token == null || token.isEmpty) {
        state = const SessionState(status: SessionStatus.signedOut);
        return;
      }
      final session = await _api.refresh(token);
      await _store.saveRefreshToken(session.refreshToken);
      state = SessionState(
        status: SessionStatus.authenticated,
        session: session,
      );
    } catch (_) {
      await _store.clear();
      _api.setAccessToken(null);
      state = const SessionState(status: SessionStatus.signedOut);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = const SessionState(status: SessionStatus.signingIn);
    try {
      final session = await _api.login(email: email, password: password);
      await _store.saveRefreshToken(session.refreshToken);
      state = SessionState(
        status: SessionStatus.authenticated,
        session: session,
      );
      return true;
    } on AdminApiException catch (error) {
      state = SessionState(
        status: SessionStatus.failure,
        message: error.message,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    final refreshToken = state.session?.refreshToken;
    state = const SessionState(status: SessionStatus.signedOut);
    await _store.clear();
    if (refreshToken != null) {
      try {
        await _api.logout(refreshToken);
      } catch (_) {
        _api.setAccessToken(null);
      }
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      await _api.requestPasswordReset(email);
      return true;
    } on AdminApiException catch (error) {
      state = SessionState(
        status: SessionStatus.failure,
        message: error.message,
      );
      return false;
    }
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
      return SessionController(
        ref.watch(apiClientProvider),
        ref.watch(sessionStoreProvider),
      );
    });
