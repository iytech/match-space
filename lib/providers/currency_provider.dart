import 'package:flutter/foundation.dart';
import '../core/utils/formatters.dart';

class CurrencyProvider extends ChangeNotifier {
  Currency _currency = Currency.ngn;
  Currency get currency => _currency;
  bool get isNgn => _currency == Currency.ngn;

  void toggle() {
    _currency = _currency == Currency.ngn ? Currency.usd : Currency.ngn;
    notifyListeners();
  }

  String price(num ngn) => Formatters.price(ngn, _currency);
  String fullPrice(num ngn) => Formatters.fullPrice(ngn, _currency);
}
