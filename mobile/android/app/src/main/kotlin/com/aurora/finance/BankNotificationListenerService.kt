package com.aurora.finance

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Intent
import android.os.Bundle
import android.util.Log
import java.util.regex.Pattern

class BankNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "BankNotificationListener"
        const val ACTION_NOTIFICATION_POSTED = "com.aurora.finance.NOTIFICATION_POSTED"
        const val EXTRA_PACKAGE = "extra_package"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_TEXT = "extra_text"
        const val EXTRA_TIMESTAMP = "extra_timestamp"

        @Volatile
        var isServiceConnected: Boolean = false

        // Non-financial social & media apps to ignore immediately
        val BLACKLISTED_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
            "org.telegram.messenger",
            "org.telegram.plus",
            "com.instagram.android",
            "com.google.android.youtube",
            "com.zhiliaoapp.musically",
            "com.facebook.katana",
            "com.facebook.orca",
            "com.twitter.android",
            "com.snapchat.android",
            "com.viber.voip",
            "com.discord"
        )

        // Known banking & payment package prefixes
        val WHITELISTED_PACKAGES = setOf(
            "uz.click.app",           // Click Evolution
            "uz.dida.payme",          // Payme Uzbekistan
            "app.bank.uzum",          // Uzum Bank
            "com.kapitalbank",        // Kapitalbank
            "com.tbcbank.uz",         // TBC Bank UZ
            "com.fido.anorbank",      // Anorbank
            "com.fido.ipakyulibank",  // Ipak Yuli Mobile
            "com.hamkorbank.mobile",  // Hamkorbank
            "com.kdb",                // KDB Bank UZ
            "com.ipotekabank",        // Ipoteka Mobile
            "uz.agrobank.mobile",     // Agrobank
            "uz.sqb.mobile",          // Sanoat Qurilish Bank
            "com.revolut"             // Revolut
        )

        // Patterns to reject non-transactional notices (even from banks)
        private val NON_TRANSACTION_REGEX = Pattern.compile(
            "(kod\\s+dlya\\s+vhoda|код\\s+для\\s+входа|tasdiqlash\\s+kodi|parol\\s+izmenen|пароль\\s+изменен|uspeshnyy\\s+vhod|успешный\\s+вход|skidk|акция|chegirma|promokod|промокод|reklama|реклама)",
            Pattern.CASE_INSENSITIVE
        )

        // Patterns confirming financial operations
        private val FINANCIAL_KEYWORDS_REGEX = Pattern.compile(
            "(oplata|оплата|spisanie|списание|pokupka|покупка|postuplenie|поступление|zachislenie|зачисление|popolnenie|пополнение|perevod|перевод|vozvrat|возврат|снятие\\s+наличных|snyatie\\s+nalichnyh|зарплат|zarplata|kredit|кредит|komissiya|комиссия|terminal:)",
            Pattern.CASE_INSENSITIVE
        )

        private val AMOUNT_REGEX = Pattern.compile(
            "(\\d[\\d\\s,.]*\\s*(UZS|USD|EUR|RUB|сум|so['`]?m|\\$|€|£|₽)|([\\$€£₽]|USD|EUR|GBP|RUB|UZS)\\s*\\d)",
            Pattern.CASE_INSENSITIVE
        )

        fun isFinancialNotification(text: String, packageName: String): Boolean {
            if (BLACKLISTED_PACKAGES.contains(packageName.lowercase())) {
                return false
            }
            if (NON_TRANSACTION_REGEX.matcher(text).find()) {
                return false
            }
            val hasKeywords = FINANCIAL_KEYWORDS_REGEX.matcher(text).find()
            val hasAmount = AMOUNT_REGEX.matcher(text).find()

            // Must have transaction intent keyword AND monetary amount to be treated as a transaction
            return hasKeywords && hasAmount
        }

        // Sanitizes sensitive OTP/PIN tokens for privacy compliance
        fun sanitizeText(text: String): String {
            return text.replace(Regex("(?i)(kod|код|code|otp|pin|пин)\\s*(?::|=)?\\s*(\\d{4,8})"), "$1 [CONFIDENTIAL]")
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isServiceConnected = true
        Log.i(TAG, "BankNotificationListenerService successfully connected and active")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isServiceConnected = false
        Log.w(TAG, "BankNotificationListenerService disconnected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName ?: return

        val extras: Bundle = sbn.notification.extras ?: return
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""
        val fullContent = if (bigText.isNotEmpty()) bigText else text

        if (fullContent.isBlank()) return

        // Lightweight pre-filtering: determine if notification is financial
        if (!isFinancialNotification(fullContent, packageName)) {
            return
        }

        val sanitized = sanitizeText(fullContent)
        Log.d(TAG, "Captured verified financial notification from $packageName: $sanitized")

        // Broadcast to Flutter Native Bridge
        val intent = Intent(ACTION_NOTIFICATION_POSTED).apply {
            putExtra(EXTRA_PACKAGE, packageName)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_TEXT, sanitized)
            putExtra(EXTRA_TIMESTAMP, sbn.postTime)
        }
        sendBroadcast(intent)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
