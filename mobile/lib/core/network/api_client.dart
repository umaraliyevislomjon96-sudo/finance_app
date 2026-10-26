import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/session_store.dart';
import '../config/api_config.dart';

/// The one HTTP client for the app. Attaches the access token to every
/// request, refreshes it once on 401 (shared by concurrent requests) and
/// retries the original call. If refresh fails, [onSessionExpired] fires.
class ApiClient {
  static final ApiClient instance = ApiClient._();

  ApiClient._() {
    dio = Dio(_options());
    _refreshDio = Dio(_options());
    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  late final Dio dio;
  late final Dio _refreshDio;
  final SessionStore _store = SessionStore.instance;
  Future<bool>? _refreshing;

  /// Set by the auth layer; called when the session cannot be renewed.
  void Function()? onSessionExpired;

  @visibleForTesting
  set httpClientAdapter(HttpClientAdapter adapter) {
    dio.httpClientAdapter = adapter;
    _refreshDio.httpClientAdapter = adapter;
  }

  /// Paths that must never carry or refresh a token.
  static const _publicPaths = ['/auth/otp/', '/auth/refresh', '/auth/oauth/'];

  static BaseOptions _options() => BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
      );

  bool _isPublic(RequestOptions o) => _publicPaths.any(o.path.startsWith);

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _store.current?.accessToken;
    if (token != null && !_isPublic(options)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    final request = error.requestOptions;
    final unauthorized = error.response?.statusCode == 401;
    if (!unauthorized || _isPublic(request) || request.extra['retried'] == true || _store.current == null) {
      return handler.next(error);
    }

    // Errors are handled one at a time; if another request already renewed
    // the token while this one was in flight, just retry with the new one.
    final sentWith = request.headers['Authorization'];
    final alreadyRenewed = sentWith != null && sentWith != 'Bearer ${_store.current!.accessToken}';
    final renewed = alreadyRenewed || await refreshSession();
    if (!renewed) {
      // A cleared store means the server rejected the refresh token.
      if (_store.current == null) onSessionExpired?.call();
      return handler.next(error);
    }

    try {
      request.extra['retried'] = true;
      request.headers['Authorization'] = 'Bearer ${_store.current!.accessToken}';
      handler.resolve(await dio.fetch(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Exchanges the refresh token for a new pair. Concurrent callers share one
  /// network call. Returns false when the session is gone (sign-in required).
  Future<bool> refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final session = _store.current;
    if (session == null) return false;
    try {
      final res = await _refreshDio.post('/auth/refresh', data: {
        'refresh_token': session.refreshToken,
        'device_id': await _store.deviceId(),
      });
      await _store.save(Session.fromTokenResponse(Map<String, dynamic>.from(res.data), fallbackPhone: session.phone));
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Only a definitive rejection ends the session; network trouble keeps it.
      if (status == 401 || status == 403) await _store.clear();
      return false;
    }
  }
}
