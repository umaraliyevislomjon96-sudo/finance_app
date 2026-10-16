import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'notification_listener_service.dart';

class ClipboardParserService {
  static final ClipboardParserService instance = ClipboardParserService._();
  ClipboardParserService._();

  String _lastProcessedText = '';

  // Regex signatures for Uzbek banking SMS / Pushes
  static final List<RegExp> _bankingSignatures = [
    RegExp(r'(oplata|spisanie|pokupka|zachislenie|perevod|karta|uzs|sum)', caseSensitive: false),
    RegExp(r'(to[\x27\x60]?lov|tushum|o[\x27\x60]?tkazma|kartadan|yechildi)', caseSensitive: false),
    RegExp(r'(payme|click|uzum|kapital|tbc|anor|ipak\s*yuli)', caseSensitive: false),
    RegExp(r'\b\d{1,3}(?:[\s,]\d{3})*(?:\.\d{2})?\s*(?:uzs|sum|so[\x27\x60]?m)\b', caseSensitive: false),
  ];

  bool isPotentialBankingText(String text) {
    if (text.length < 15 || text.length > 500) return false;
    int matches = 0;
    for (final reg in _bankingSignatures) {
      if (reg.hasMatch(text)) {
        matches++;
      }
    }
    // If it matches at least 2 banking keywords/signatures, it's very likely a transaction
    return matches >= 2;
  }

  Future<Map<String, dynamic>?> checkClipboardAndIngest({String? authToken}) async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data == null || data.text == null) return null;

      final String text = data.text!.trim();
      if (text.isEmpty || text == _lastProcessedText) return null;

      if (isPotentialBankingText(text)) {
        _lastProcessedText = text;
        debugPrint('Detected banking message in clipboard: $text');
        return await NotificationListenerService.instance.simulatePush(
          packageName: 'smart_clipboard_ios',
          text: text,
          authToken: authToken,
        );
      }
    } catch (e) {
      debugPrint('Error inspecting clipboard: $e');
    }
    return null;
  }
}
