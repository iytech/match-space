import 'package:characters/characters.dart';
import 'package:intl/intl.dart';

/// Currency + date/number formatting helpers.
enum Currency { ngn, usd }

class Formatters {
  Formatters._();

  // Approx static rate for display toggle; real apps should fetch live rates.
  static const double usdRate = 1600.0; // 1 USD = ₦1600 (adjust as needed)

  static String price(num amountNgn, Currency currency) {
    if (currency == Currency.usd) {
      final usd = amountNgn / usdRate;
      return '\$${_compact(usd)}';
    }
    return '₦${_compact(amountNgn)}';
  }

  static String _compact(num v) {
    final f = NumberFormat.decimalPattern('en_US');
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    return f.format(v.round());
  }

  static String fullPrice(num amountNgn, Currency currency) {
    final f = NumberFormat.decimalPattern('en_US');
    if (currency == Currency.usd) {
      return '\$${f.format((amountNgn / usdRate).round())}';
    }
    return '₦${f.format(amountNgn.round())}';
  }

  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);
  static String dateTime(DateTime d) => DateFormat('d MMM, h:mm a').format(d);

  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(d);
  }
}

/// Safe first-initial helper — never throws on empty/null names.
String initialOf(String? name, [String fallback = 'U']) {
  final n = (name ?? '').trim();
  if (n.isEmpty) return fallback;
  return n.characters.first.toUpperCase();
}
