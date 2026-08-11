import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

class AdminApiClient {
  AdminApiClient({
    required String baseUrl,
    Dio? dio,
    Duration requestTimeout = const Duration(seconds: 15),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: _normaliseBaseUrl(baseUrl),
               connectTimeout: requestTimeout,
               receiveTimeout: requestTimeout,
               sendTimeout: requestTimeout,
               responseType: ResponseType.json,
               validateStatus: (_) => true,
               headers: const {'Accept': 'application/json'},
             ),
           );

  final Dio _dio;
  String? _accessToken;
  Future<String?> Function()? _unauthorizedHandler;
  Future<String?>? _refreshInFlight;

  void setAccessToken(String? token) => _accessToken = token;

  void setUnauthorizedHandler(Future<String?> Function()? handler) {
    _unauthorizedHandler = handler;
  }

  Future<AdminSession> login({
    required String email,
    required String password,
  }) async {
    final object = _asMap(
      await post(
        '/auth/login',
        body: {'email': email, 'password': password},
        includeAuthorization: false,
      ),
    );
    final accessToken = object['accessToken'];
    final refreshToken = object['refreshToken'];
    final user = object['user'];
    final userMap =
        user is Map
            ? Map<String, dynamic>.from(user)
            : const <String, dynamic>{};
    final role = userMap['role'];
    final roleName =
        (role is Map ? role['name'] : role)?.toString().toLowerCase();
    if (accessToken is! String || refreshToken is! String) {
      throw const AdminApiException(
        'La risposta di accesso non è valida. Riprova.',
      );
    }
    if (roleName != 'admin') {
      throw const AdminApiException(
        'Questo tablet richiede un account amministratore autorizzato.',
        statusCode: 403,
      );
    }
    setAccessToken(accessToken);
    return AdminSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      roleName: roleName!,
      user: userMap,
    );
  }

  Future<AdminSession> refresh(String refreshToken) async {
    final object = _asMap(
      await post(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
        includeAuthorization: false,
      ),
    );
    final accessToken = object['accessToken'];
    final rotatedRefreshToken = object['refreshToken'];
    if (accessToken is! String || rotatedRefreshToken is! String) {
      throw const AdminApiException('La sessione non può essere aggiornata.');
    }
    setAccessToken(accessToken);
    return AdminSession(
      accessToken: accessToken,
      refreshToken: rotatedRefreshToken,
      roleName: 'admin',
    );
  }

  Future<void> logout(String refreshToken) async {
    try {
      await post('/auth/logout', body: {'refreshToken': refreshToken});
    } finally {
      setAccessToken(null);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await post(
      '/auth/forgot-password',
      body: {'email': email},
      includeAuthorization: false,
    );
  }

  Future<Object?> get(String path, {Map<String, dynamic>? query}) =>
      _request('GET', path, query: query);

  Future<Object?> post(
    String path, {
    Object? body,
    bool includeAuthorization = true,
    String? idempotencyKey,
  }) => _request(
    'POST',
    path,
    body: body,
    includeAuthorization: includeAuthorization,
    idempotencyKey: idempotencyKey,
  );

  Future<Object?> patch(String path, {Object? body, String? idempotencyKey}) =>
      _request('PATCH', path, body: body, idempotencyKey: idempotencyKey);

  Future<Object?> put(String path, {Object? body}) =>
      _request('PUT', path, body: body);

  Future<Object?> delete(String path) => _request('DELETE', path);

  Future<Object?> uploadFile(
    String path, {
    required String fileName,
    String? filePath,
    Uint8List? bytes,
    required Map<String, Object?> fields,
  }) async {
    if (filePath == null && bytes == null) {
      throw const AdminApiException('Il file selezionato non è disponibile.');
    }
    final file =
        filePath != null
            ? await MultipartFile.fromFile(filePath, filename: fileName)
            : MultipartFile.fromBytes(bytes!, filename: fileName);
    return _request(
      'POST',
      path,
      body: FormData.fromMap({...fields, 'file': file}),
    );
  }

  Future<Object?> _request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool includeAuthorization = true,
    String? idempotencyKey,
    bool retryAfterRefresh = true,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        path.replaceFirst(RegExp(r'^/+'), ''),
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            'X-Correlation-Id': 'admin-${const Uuid().v4()}',
            if (includeAuthorization && _accessToken != null)
              'Authorization': 'Bearer $_accessToken',
            if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
          },
        ),
      );
      final status = response.statusCode ?? 0;
      final decoded = response.data;
      if (status == 401 &&
          includeAuthorization &&
          retryAfterRefresh &&
          _unauthorizedHandler != null) {
        _refreshInFlight ??= _unauthorizedHandler!();
        String? refreshed;
        try {
          refreshed = await _refreshInFlight;
        } finally {
          _refreshInFlight = null;
        }
        if (refreshed != null && refreshed.isNotEmpty) {
          setAccessToken(refreshed);
          return _request(
            method,
            path,
            body: body,
            query: query,
            includeAuthorization: includeAuthorization,
            idempotencyKey: idempotencyKey,
            retryAfterRefresh: false,
          );
        }
      }
      if (status < 200 || status >= 300) {
        final object =
            decoded is Map ? Map<String, dynamic>.from(decoded) : null;
        throw AdminApiException(
          _italianError(status, object?['message']?.toString()),
          statusCode: status,
        );
      }
      if (decoded is Map && decoded.containsKey('data')) return decoded['data'];
      return decoded;
    } on AdminApiException {
      rethrow;
    } on DioException catch (error) {
      if ({
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      }.contains(error.type)) {
        throw const AdminApiException(
          'La richiesta ha impiegato troppo tempo. Riprova.',
        );
      }
      throw const AdminApiException(
        'Connessione non disponibile. Controlla la rete e riprova.',
      );
    } on FormatException {
      throw const AdminApiException(
        'Il server ha restituito una risposta non valida.',
      );
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const AdminApiException('La risposta del server non è valida.');
  }

  static String _normaliseBaseUrl(String raw) =>
      raw.endsWith('/') ? raw : '$raw/';

  static String _italianError(int statusCode, String? serverMessage) {
    if (statusCode == 400 || statusCode == 422) {
      return serverMessage ?? 'Controlla i dati inseriti e riprova.';
    }
    if (statusCode == 401) return 'Credenziali non valide o sessione scaduta.';
    if (statusCode == 403) return 'Non hai il permesso per questa operazione.';
    if (statusCode == 404) return 'La risorsa richiesta non è più disponibile.';
    if (statusCode == 409) {
      return 'L’operazione è in conflitto con lo stato attuale.';
    }
    if (statusCode >= 500) {
      return 'Il server non è disponibile. Riprova più tardi.';
    }
    return serverMessage ?? 'L’operazione non è riuscita. Controlla i dati.';
  }
}

class AdminSession {
  const AdminSession({
    required this.accessToken,
    required this.refreshToken,
    required this.roleName,
    this.user = const {},
  });

  final String accessToken;
  final String refreshToken;
  final String roleName;
  final Map<String, dynamic> user;
}

class AdminApiException implements Exception {
  const AdminApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract final class AdminApiRoutes {
  static const posCatalog = '/admin/pos/catalog';
  static const posOrders = '/admin/pos/orders';
  static String posCollect(String id) => '/admin/pos/orders/$id/collect';
  static String posReceipt(String id) => '/admin/pos/orders/$id/receipt';
  static const posReceipts = '/admin/pos/receipts';
  static const dashboardSummary = '/admin/dashboard/summary';
  static const reportsSales = '/reports/sales';
  static const reportsDailyRevenue = '/reports/daily-revenue';
  static const reportsPopularItems = '/reports/popular-items';
  static const orders = '/orders/admin/list';
  static String orderDetail(String id) => '/orders/admin/$id';
  static String orderStatus(String id) => '/orders/admin/$id/status';
  static const deliveriesAdmin = '/deliveries/admin';
  static String deliveryTracking(String orderId) =>
      '/deliveries/orders/$orderId/tracking';
  static String deliveryAssignment(String orderId) =>
      '/deliveries/orders/$orderId/assignment';
  static String deliveryAssign(String orderId) =>
      '/deliveries/orders/$orderId/assign';
  static String deliveryStatus(String orderId) =>
      '/deliveries/orders/$orderId/status';
  static String deliveryLocation(String orderId) =>
      '/deliveries/orders/$orderId/location';
  static const supportQueue = '/support/agent/queue';
  static String supportClaim(String id) => '/support/agent/tickets/$id/claim';
  static String supportStatus(String id) => '/support/agent/tickets/$id/status';
  static const categories = '/categories';
  static String category(String id) => '/categories/$id';
  static const ingredients = '/ingredients';
  static String ingredient(String id) => '/ingredients/$id';
  static const menu = '/menu';
  static const menuSearch = '/menu/search';
  static String menuItem(String id) => '/menu/$id';
  static const optionGroups = '/option-groups';
  static String optionGroup(String id) => '/option-groups/$id';
  static String optionChoices(String id) => '/option-groups/$id/choices';
  static String optionChoice(String groupId, String choiceId) =>
      '/option-groups/$groupId/choices/$choiceId';
  static const priceCalculate = '/pricing/calculate';
  static String pizzaBuilder(String menuItemId) => '/pizza-builder/$menuItemId';
  static const pizzaBuild = '/pizza-builder/build';
  static const pizzaBuilderRules = '/pizza-builder/admin/rules';
  static String pizzaBuilderRule(String id) => '/pizza-builder/admin/rules/$id';
  static const promotions = '/promotions';
  static String promotion(String id) => '/promotions/$id';
  static const coupons = '/coupons';
  static String coupon(String id) => '/coupons/$id';
  static const faqs = '/faq';
  static String faq(String id) => '/faq/$id';
  static const staff = '/staff';
  static String staffMember(String id) => '/staff/$id';
  static const users = '/users';
  static const usersWithPermissions = '/users/with-permissions';
  static String user(String id) => '/users/$id';
  static String userPermissions(String id) => '/users/$id/permissions';
  static const availableFeatures = '/users/available-features';
  static String featureActions(String feature) =>
      '/users/available-features/$feature/actions';
  static const roles = '/roles';
  static String role(String id) => '/roles/$id';
  static const permissions = '/permissions';
  static const permissionResources = '/permissions/resources';
  static const permissionActions = '/permissions/actions';
  static const permissionsByResource = '/permissions/by-resource';
  static String permission(String id) => '/permissions/$id';
  static String rolePermissions(String roleId) => '/role-permissions/$roleId';
  static String rolePermission(String roleId, String permissionId) =>
      '/role-permissions/$roleId/$permissionId';
  static const restaurant = '/restaurants';
  static const restaurantHours = '/restaurants/hours';
  static const notifications = '/notifications';
  static String notification(String id) => '/notifications/$id';
  static const unreadNotificationCount = '/notifications/unread-count';
  static String readNotification(String id) => '/notifications/$id/read';
  static const notificationDevices = '/notifications/devices';
  static String notificationDevice(String id) => '/notifications/devices/$id';
  static const notificationPreferences = '/notifications/preferences/me';
  static const mediaAdmin = '/media/admin';
  static const mediaUpload = '/media/upload';
  static const mediaUploads = '/media/uploads';
  static String finalizeMedia(String id) => '/media/$id/finalize';
  static String media(String id) => '/media/$id';
  static const refundsAdmin = '/refunds/admin';
  static const refunds = '/refunds';
  static String orderRefunds(String orderId) => '/refunds/orders/$orderId';
  static String refund(String id) => '/refunds/$id';
  static String approveRefund(String id) => '/refunds/$id/approve';
  static String collectPayment(String orderId) =>
      '/payments/orders/$orderId/collect';
  static const supportTickets = '/support/tickets';
  static String supportTicket(String id) => '/support/tickets/$id';
  static String supportMessages(String id) => '/support/tickets/$id/messages';
  static String readSupportTicket(String id) => '/support/tickets/$id/read';
  static String supportRealtimeAuthorization(String id) =>
      '/support/tickets/$id/realtime-authorization';
  static const audit = '/audit';
}
