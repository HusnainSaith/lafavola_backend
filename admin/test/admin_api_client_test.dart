import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

void main() {
  group('AdminApiClient authentication', () {
    test('accepts an administrator and omits authorization on login', () async {
      final server = await _TestServer.start((request) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/auth/login');
        expect(request.headers.value(HttpHeaders.authorizationHeader), isNull);
        expect(jsonDecode(await utf8.decoder.bind(request).join()), {
          'email': 'admin@lafavola.it',
          'password': 'password',
        });
        return {
          'data': {
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
            'user': {
              'role': {'name': 'ADMIN'},
            },
          },
        };
      });
      addTearDown(server.close);

      final session = await AdminApiClient(
        baseUrl: server.baseUrl,
      ).login(email: 'admin@lafavola.it', password: 'password');

      expect(session.accessToken, 'access-token');
      expect(session.refreshToken, 'refresh-token');
      expect(session.roleName, 'admin');
    });

    test(
      'rejects a non-admin account before creating a local session',
      () async {
        final server = await _TestServer.start(
          (_) async => {
            'data': {
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
              'user': {
                'role': {'name': 'CLIENT'},
              },
            },
          },
        );
        addTearDown(server.close);

        expect(
          () => AdminApiClient(
            baseUrl: server.baseUrl,
          ).login(email: 'customer@lafavola.it', password: 'password'),
          throwsA(
            isA<AdminApiException>().having(
              (error) => error.statusCode,
              'status code',
              403,
            ),
          ),
        );
      },
    );

    test('uses the rotated refresh token returned by the API', () async {
      final server = await _TestServer.start((request) async {
        expect(request.uri.path, '/auth/refresh');
        expect(jsonDecode(await utf8.decoder.bind(request).join()), {
          'refreshToken': 'old-token',
        });
        return {
          'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
        };
      });
      addTearDown(server.close);

      final session = await AdminApiClient(
        baseUrl: server.baseUrl,
      ).refresh('old-token');

      expect(session.accessToken, 'new-access');
      expect(session.refreshToken, 'new-refresh');
    });

    test(
      'refreshes once and replays an authenticated request after 401',
      () async {
        var orderAttempts = 0;
        final server = await _TestServer.start((request) async {
          if (request.uri.path == '/auth/refresh') {
            return {
              'data': {
                'accessToken': 'new-access',
                'refreshToken': 'new-refresh',
              },
            };
          }
          expect(request.uri.path, '/orders/admin/list');
          orderAttempts += 1;
          if (orderAttempts == 1) {
            expect(
              request.headers.value(HttpHeaders.authorizationHeader),
              'Bearer old-access',
            );
            request.response.statusCode = HttpStatus.unauthorized;
            return {'message': 'expired'};
          }
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            'Bearer new-access',
          );
          return {'data': <Object>[]};
        });
        addTearDown(server.close);

        final client = AdminApiClient(baseUrl: server.baseUrl)
          ..setAccessToken('old-access');
        client.setUnauthorizedHandler(() async {
          final refreshed = await client.refresh('old-refresh');
          return refreshed.accessToken;
        });

        await expectLater(client.get(AdminApiRoutes.orders), completes);
        expect(orderAttempts, 2);
      },
    );

    test('sends password reset requests without a bearer token', () async {
      final server = await _TestServer.start((request) async {
        expect(request.uri.path, '/auth/forgot-password');
        expect(request.headers.value(HttpHeaders.authorizationHeader), isNull);
        expect(jsonDecode(await utf8.decoder.bind(request).join()), {
          'email': 'admin@lafavolabrescia.it',
        });
        return {
          'data': {'success': true},
        };
      });
      addTearDown(server.close);

      await AdminApiClient(
        baseUrl: server.baseUrl,
      ).requestPasswordReset('admin@lafavolabrescia.it');
    });

    test('maps a transport timeout to an actionable Italian message', () async {
      final server = await _TestServer.start((_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return {'data': {}};
      });
      addTearDown(server.close);

      expect(
        () => AdminApiClient(
          baseUrl: server.baseUrl,
          requestTimeout: const Duration(milliseconds: 20),
        ).get('/reports/sales'),
        throwsA(
          isA<AdminApiException>().having(
            (error) => error.message,
            'message',
            contains('troppo tempo'),
          ),
        ),
      );
    });
  });
}

typedef _RequestHandler =
    Future<Map<String, Object?>> Function(HttpRequest request);

class _TestServer {
  _TestServer._(this._server);

  final HttpServer _server;

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<_TestServer> start(_RequestHandler handler) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      try {
        final responseBody = await handler(request);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBody));
      } finally {
        await request.response.close();
      }
    });
    return _TestServer._(server);
  }

  Future<void> close() => _server.close(force: true);
}
