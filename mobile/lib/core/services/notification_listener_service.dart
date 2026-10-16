import 'dart:async';
import 'dart:collection';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

enum NotificationListenerState {
  connected,
  permissionRequired,
  disabled,
  error,
}

class NotificationListenerService {
  static final NotificationListenerService instance = NotificationListenerService._();
  NotificationListenerService._();

  static const MethodChannel _methodChannel = MethodChannel('com.aurora.finance/notifications_control');
  static const EventChannel _eventChannel = EventChannel('com.aurora.finance/notifications_stream');

  StreamSubscription? _subscription;
  NotificationListenerState _currentState = NotificationListenerState.permissionRequired;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  // Stream of successfully processed transactions for reactive UI updates
  final StreamController<Map<String, dynamic>> _onTransactionIngested = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onTransactionIngested => _onTransactionIngested.stream;

  // Stream of listener connection status
  final StreamController<NotificationListenerState> _onStateChanged = StreamController.broadcast();
  Stream<NotificationListenerState> get onStateChanged => _onStateChanged.stream;
  NotificationListenerState get currentState => _currentState;

  // Local deduplication buffer (keys seen in last 5 minutes)
  final Set<String> _recentIdempotencyKeys = {};
  
  // Offline fallback queue for offline processing resilience
  final Queue<Map<String, dynamic>> _offlineQueue = Queue();
  bool _isProcessingOfflineQueue = false;

  Future<bool> isPermissionGranted() async {
    try {
      final bool granted = await _methodChannel.invokeMethod('isPermissionGranted');
      _updateState(granted ? NotificationListenerState.connected : NotificationListenerState.permissionRequired);
      return granted;
    } catch (e) {
      debugPrint('Error checking notification listener permission: $e');
      _updateState(NotificationListenerState.error);
      return false;
    }
  }

  Future<NotificationListenerState> checkStatus() async {
    try {
      final String? statusStr = await _methodChannel.invokeMethod('getListenerStatus');
      if (statusStr == 'Connected') {
        _updateState(NotificationListenerState.connected);
      } else if (statusStr == 'Permission required') {
        _updateState(NotificationListenerState.permissionRequired);
      } else {
        final bool granted = await isPermissionGranted();
        _updateState(granted ? NotificationListenerState.connected : NotificationListenerState.permissionRequired);
      }
    } catch (e) {
      debugPrint('Error querying listener status: $e');
      _updateState(NotificationListenerState.error);
    }
    return _currentState;
  }

  void _updateState(NotificationListenerState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _onStateChanged.add(_currentState);
    }
  }

  Future<void> openPermissionSettings() async {
    try {
      await _methodChannel.invokeMethod('openPermissionSettings');
    } catch (e) {
      debugPrint('Error opening permission settings: $e');
    }
  }

  void startListening({String? authToken}) {
    _subscription?.cancel();
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) async {
        if (event is Map) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(event);
          await _processAndIngest(data, authToken: authToken);
        }
      },
      onError: (dynamic error) {
        debugPrint('Notification stream error: $error');
        _updateState(NotificationListenerState.error);
      },
    );
    checkStatus();
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _updateState(NotificationListenerState.disabled);
  }

  Future<Map<String, dynamic>?> _processAndIngest(
    Map<String, dynamic> rawNotification, {
    String? authToken,
  }) async {
    final String text = rawNotification['text'] ?? '';
    final String package = rawNotification['package'] ?? 'unknown_app';
    final int timestamp = rawNotification['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;

    if (text.trim().isEmpty) return null;

    final String idempotencyKey = 'push_${package}_${timestamp}_${text.hashCode.abs()}';

    // Local client-side deduplication check
    if (_recentIdempotencyKeys.contains(idempotencyKey)) {
      debugPrint('Client duplicate detected for $idempotencyKey. Skipping network dispatch.');
      return null;
    }
    _recentIdempotencyKeys.add(idempotencyKey);
    if (_recentIdempotencyKeys.length > 200) {
      _recentIdempotencyKeys.remove(_recentIdempotencyKeys.first);
    }

    final Map<String, dynamic> payload = {
      'text': text,
      'package_name': package,
      'source': 'push',
      'idempotency_key': idempotencyKey,
    };

    try {
      final response = await _dio.post(
        '/transactions/ingest',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = Map<String, dynamic>.from(response.data);
        if (result['status'] == 'processed' || result['status'] == 'needs_review') {
          _onTransactionIngested.add(result);
          debugPrint('Successfully ingested push transaction: ${result['merchant']} - ${result['amount_formatted']}');
        }
        // Flush any queued offline notifications
        _flushOfflineQueue(authToken: authToken);
        return result;
      }
    } catch (e) {
      debugPrint('Failed to ingest notification to backend (offline or network error): $e');
      // Enqueue for offline resilience
      _offlineQueue.add(payload);
    }
    return null;
  }

  Future<void> _flushOfflineQueue({String? authToken}) async {
    if (_isProcessingOfflineQueue || _offlineQueue.isEmpty) return;
    _isProcessingOfflineQueue = true;

    while (_offlineQueue.isNotEmpty) {
      final payload = _offlineQueue.first;
      try {
        final response = await _dio.post(
          '/transactions/ingest',
          data: payload,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              if (authToken != null) 'Authorization': 'Bearer $authToken',
            },
          ),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          _offlineQueue.removeFirst();
          final Map<String, dynamic> result = Map<String, dynamic>.from(response.data);
          _onTransactionIngested.add(result);
        } else {
          break;
        }
      } catch (e) {
        // Still offline, stop flushing
        break;
      }
    }
    _isProcessingOfflineQueue = false;
  }

  // Method for manual or simulator testing
  Future<Map<String, dynamic>?> simulatePush({
    required String packageName,
    required String text,
    String? authToken,
  }) async {
    return await _processAndIngest({
      'package': packageName,
      'title': 'Bank Push',
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, authToken: authToken);
  }
}
