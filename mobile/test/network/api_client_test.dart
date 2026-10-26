import 'dart:convert';
import 'dart:typed_data';
import 'package:aurora_finance/core/auth/session_store.dart';
import 'package:aurora_finance/core/network/api_client.dart';
import 'package:aurora_finance/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Routes requests to a handler and records them.
class FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  late Future<(int, Object)> Function(RequestOptions) handler;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final (status, body) = await handler(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object> tokens(String access, String refresh) =>
    {'access_token': access, 'refresh_token': refresh, 'user_id': 'u1', 'phone': '+998901234567'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = SessionStore.instance;
  final api = ApiClient.instance;
  late FakeAdapter adapter;
  late int expiredCalls;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await store.save(const Session(accessToken: 'old', refreshToken: 'r1', userId: 'u1', phone: '+998901234567'));
    adapter = FakeAdapter();
    api.httpClientAdapter = adapter;
    expiredCalls = 0;
    api.onSessionExpired = () => expiredCalls++;
  });

  test('attaches bearer token but not on public auth paths', () async {
    adapter.handler = (_) async => (200, {'ok': true});
    await api.dio.get('/cards');
    await api.dio.post('/auth/otp/request', data: {});
    expect(adapter.requests[0].headers['Authorization'], 'Bearer old');
    expect(adapter.requests[1].headers.containsKey('Authorization'), isFalse);
  });

  test('refreshes once on 401 and retries with the new token', () async {
    adapter.handler = (o) async {
      if (o.path == '/auth/refresh') return (200, tokens('new', 'r2'));
      final auth = o.headers['Authorization'];
      return auth == 'Bearer new' ? (200, {'ok': true}) : (401, {'detail': 'expired'});
    };

    final res = await api.dio.get('/cards');

    expect(res.data, {'ok': true});
    expect(adapter.requests.map((r) => r.path), ['/cards', '/auth/refresh', '/cards']);
    expect(store.current!.accessToken, 'new');
    expect(store.current!.refreshToken, 'r2');
    expect(expiredCalls, 0);
  });

  test('concurrent 401s share a single refresh call', () async {
    adapter.handler = (o) async {
      if (o.path == '/auth/refresh') {
        await Future.delayed(const Duration(milliseconds: 20));
        return (200, tokens('new', 'r2'));
      }
      return o.headers['Authorization'] == 'Bearer new' ? (200, {'ok': true}) : (401, {});
    };

    await Future.wait([api.dio.get('/a'), api.dio.get('/b'), api.dio.get('/c')]);

    expect(adapter.requests.where((r) => r.path == '/auth/refresh').length, 1);
  });

  test('rejected refresh clears the session and reports expiry', () async {
    adapter.handler = (o) async => o.path == '/auth/refresh' ? (401, {'detail': 'nope'}) : (401, {});

    await expectLater(api.dio.get('/cards'), throwsA(isA<DioException>()));

    expect(store.current, isNull);
    expect(expiredCalls, 1);
  });

  test('network failure during refresh keeps the session', () async {
    adapter.handler = (o) async {
      if (o.path == '/auth/refresh') {
        throw DioException(requestOptions: o, type: DioExceptionType.connectionError);
      }
      return (401, {});
    };

    await expectLater(api.dio.get('/cards'), throwsA(isA<DioException>()));

    expect(store.current, isNotNull);
    expect(expiredCalls, 0);
  });

  test('ApiException maps server detail and timeouts to readable messages', () {
    final ro = RequestOptions(path: '/x');
    final bad = DioException(
      requestOptions: ro,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: ro, statusCode: 400, data: {'detail': 'Неверный код'}),
    );
    expect(ApiException.from(bad).message, 'Неверный код');
    expect(ApiException.from(DioException(requestOptions: ro, type: DioExceptionType.receiveTimeout)).kind, ApiErrorKind.timeout);
  });
}
