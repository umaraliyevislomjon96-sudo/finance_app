import 'package:dio/dio.dart';

enum ApiErrorKind { offline, timeout, unauthorized, rateLimited, server, client, unknown }

/// User-facing error produced by [ApiClient]. [message] is ready to show in UI.
class ApiException implements Exception {
  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  const ApiException(this.kind, this.message, {this.statusCode});

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is! DioException) {
      return const ApiException(ApiErrorKind.unknown, 'Что-то пошло не так. Попробуйте ещё раз.');
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException(
          ApiErrorKind.timeout,
          'Сервер долго не отвечает — возможно, он просыпается. Повторите через минуту.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(ApiErrorKind.offline, 'Нет соединения с интернетом.');
      case DioExceptionType.cancel:
        return const ApiException(ApiErrorKind.unknown, 'Запрос отменён.');
      default:
        break;
    }
    final status = error.response?.statusCode;
    final detail = _detail(error.response?.data);
    if (status == 401) {
      return ApiException(ApiErrorKind.unauthorized, detail ?? 'Сессия истекла. Войдите заново.', statusCode: status);
    }
    if (status == 429) {
      return ApiException(ApiErrorKind.rateLimited, detail ?? 'Слишком много попыток. Подождите немного.', statusCode: status);
    }
    if (status != null && status >= 500) {
      return ApiException(ApiErrorKind.server, 'Ошибка на сервере. Мы уже разбираемся — попробуйте позже.', statusCode: status);
    }
    if (status != null) {
      return ApiException(ApiErrorKind.client, detail ?? 'Запрос не выполнен ($status).', statusCode: status);
    }
    return const ApiException(ApiErrorKind.unknown, 'Что-то пошло не так. Попробуйте ещё раз.');
  }

  /// FastAPI returns `{"detail": "..."}` or a validation list.
  static String? _detail(Object? data) {
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    if (data is Map && data['detail'] is List && (data['detail'] as List).isNotEmpty) {
      final first = (data['detail'] as List).first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
    }
    return null;
  }

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}
