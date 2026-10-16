import 'package:flutter/material.dart';

enum AppCurrency { uzs, usd }

class CurrencyController extends ChangeNotifier {
  static final CurrencyController instance = CurrencyController._();
  CurrencyController._();

  AppCurrency _currency = AppCurrency.uzs;
  final double _usdRate = 12850.0;

  AppCurrency get currency => _currency;
  bool get isUzs => _currency == AppCurrency.uzs;
  bool get isUsd => _currency == AppCurrency.usd;
  double get usdRate => _usdRate;

  String get symbol => _currency == AppCurrency.uzs ? 'UZS' : '\$';

  void toggleCurrency() {
    _currency = _currency == AppCurrency.uzs ? AppCurrency.usd : AppCurrency.uzs;
    notifyListeners();
  }

  void setCurrency(AppCurrency curr) {
    if (_currency != curr) {
      _currency = curr;
      notifyListeners();
    }
  }

  /// Formats amount passed in base currency (UZS) into active currency display string.
  String format(double amountInUzs, {bool compact = false, int decimals = 0}) {
    if (_currency == AppCurrency.usd) {
      final inUsd = amountInUzs / _usdRate;
      if (compact && inUsd >= 1000) {
        return '\$${(inUsd / 1000).toStringAsFixed(1)}k';
      }
      final formatted = _formatThousands(inUsd.toStringAsFixed(decimals));
      return '\$$formatted';
    } else {
      if (compact && amountInUzs >= 1000000) {
        return '${(amountInUzs / 1000000).toStringAsFixed(1)} млн UZS';
      }
      final formatted = _formatThousands(amountInUzs.toStringAsFixed(0));
      return '$formatted UZS';
    }
  }

  /// Converts UZS amount to double in current currency
  double toActiveCurrency(double amountInUzs) {
    if (_currency == AppCurrency.usd) {
      return amountInUzs / _usdRate;
    }
    return amountInUzs;
  }

  String _formatThousands(String numStr) {
    final parts = numStr.split('.');
    final integerPart = parts[0];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      buffer.write(integerPart[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(' ');
      }
    }
    final reversed = buffer.toString().split('').reversed.join();
    return parts.length > 1 ? '$reversed.${parts[1]}' : reversed;
  }
}
