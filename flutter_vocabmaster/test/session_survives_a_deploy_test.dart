import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabmaster/services/api_service.dart';
import 'package:vocabmaster/services/auth_service.dart';

/// What ends a session, and what merely fails a request.
///
/// The access token lives fifteen minutes, so at any moment somebody is
/// refreshing. The refresh treated every non-200 as "signed out": a backend
/// deploy, a 502 from the proxy in front of a restarting container, a tunnel
/// dropping mid-request — each of them threw a live session away and put the
/// learner back on the login screen, with their words and streak apparently
/// gone. Only the server actually refusing the token should do that.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const String testBaseUrl = 'http://localhost:8080/api';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await AuthService().saveSession('expired_token', 'refresh_token', {
      'id': 7,
      'userId': 7,
      'email': 'session@test.local',
      'displayName': 'Session',
      'userTag': '#00007',
      'role': 'USER',
    });
  });

  tearDown(() => ApiService.onSessionExpired = null);

  /// A client whose protected call always 401s, and whose refresh answers with
  /// [refreshStatus] — or throws, when it is null.
  http.Client clientWhereRefresh(int? refreshStatus, {Object? throwing}) {
    return MockClient((http.Request request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        if (throwing != null) throw throwing;
        if (refreshStatus == 200) {
          return http.Response(
            json.encode(<String, dynamic>{
              'accessToken': 'fresh_token',
              'refreshToken': 'fresh_refresh',
              'userId': 7,
            }),
            200,
          );
        }
        return http.Response('{"error":"nope"}', refreshStatus!);
      }
      return http.Response('{"error":"Unauthorized"}', 401);
    });
  }

  Future<bool> signedOutAfterCall(http.Client client) async {
    var signedOut = false;
    ApiService.onSessionExpired = () => signedOut = true;
    final ApiService api = ApiService(client: client, baseUrl: testBaseUrl);
    try {
      await api.getAllWords();
    } catch (_) {
      // Every one of these fails the call; the question is only what it did to
      // the session on the way out.
    }
    return signedOut;
  }

  test('a refused refresh token ends the session', () async {
    // The one case that should: the server looked and said no.
    expect(await signedOutAfterCall(clientWhereRefresh(401)), isTrue);
    expect(await signedOutAfterCall(clientWhereRefresh(403)), isTrue);
  });

  test('a backend restarting does not end the session', () async {
    for (final int status in <int>[500, 502, 503, 504]) {
      expect(
        await signedOutAfterCall(clientWhereRefresh(status)),
        isFalse,
        reason: '$status signed a live session out',
      );
    }
  });

  test('losing the network mid-refresh does not end the session', () async {
    expect(
      await signedOutAfterCall(
        clientWhereRefresh(null, throwing: const SocketishFailure()),
      ),
      isFalse,
    );
  });

  test('a 200 carrying no token is a server fault, not a dead session', () async {
    final http.Client client = MockClient((http.Request request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        return http.Response('{"userId":7}', 200);
      }
      return http.Response('{"error":"Unauthorized"}', 401);
    });

    expect(await signedOutAfterCall(client), isFalse);
  });

  test('a token that is refreshed and still refused ends the session', () async {
    // Fresh token, still 401: nothing else to try.
    expect(await signedOutAfterCall(clientWhereRefresh(200)), isTrue);
  });
}

/// Stands in for the connection failures package:http throws.
class SocketishFailure implements Exception {
  const SocketishFailure();
  @override
  String toString() => 'Connection closed before full header was received';
}
