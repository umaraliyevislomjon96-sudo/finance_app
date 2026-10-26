package com.aurora.finance

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val METHOD_CHANNEL = "com.aurora.finance/notifications_control"
    private val EVENT_CHANNEL = "com.aurora.finance/notifications_stream"

    private var eventSink: EventChannel.EventSink? = null
    private var notificationReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel for checking permissions and opening settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> {
                    val enabledListeners = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                    val isGranted = enabledListeners != null && enabledListeners.contains(packageName)
                    result.success(isGranted)
                }
                "getListenerStatus" -> {
                    val enabledListeners = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                    val isGranted = enabledListeners != null && enabledListeners.contains(packageName)
                    val status = if (!isGranted) "Permission required" else "Connected"
                    result.success(status)
                }
                "openPermissionSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).apply {
                        putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME, "$packageName/${BankNotificationListenerService::class.java.name}")
                    })
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Event Channel for streaming captured bank notifications to Flutter Dart code
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerNotificationReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterNotificationReceiver()
                    eventSink = null
                }
            }
        )
    }

    private fun registerNotificationReceiver() {
        notificationReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == BankNotificationListenerService.ACTION_NOTIFICATION_POSTED) {
                    val payload = mapOf(
                        "package" to intent.getStringExtra(BankNotificationListenerService.EXTRA_PACKAGE),
                        "title" to intent.getStringExtra(BankNotificationListenerService.EXTRA_TITLE),
                        "text" to intent.getStringExtra(BankNotificationListenerService.EXTRA_TEXT),
                        "timestamp" to intent.getLongExtra(BankNotificationListenerService.EXTRA_TIMESTAMP, System.currentTimeMillis())
                    )
                    eventSink?.success(payload)
                }
            }
        }

        val filter = IntentFilter(BankNotificationListenerService.ACTION_NOTIFICATION_POSTED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(notificationReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(notificationReceiver, filter)
        }
    }

    private fun unregisterNotificationReceiver() {
        notificationReceiver?.let {
            unregisterReceiver(it)
            notificationReceiver = null
        }
    }
}
