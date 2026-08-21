import 'package:intl/intl.dart';

/// Presentation-layer formatting helpers. Kept out of widgets so every
/// screen renders prices/dates identically.
class Formatters {
  Formatters._();

  static final NumberFormat _aed = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'AED ',
    decimalDigits: 0,
  );

  static String price(num value) => _aed.format(value);

  static String priceCompact(num value) {
    if (value >= 1000000) {
      return 'AED ${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return 'AED ${(value / 1000).toStringAsFixed(0)}K';
    }
    return _aed.format(value);
  }

  static String monthYear(DateTime date) => DateFormat('MMM yyyy').format(date);

  static String fullDate(DateTime date) => DateFormat('d MMMM yyyy').format(date);

  static String handoverLabel(DateTime date) => DateFormat('MMM yyyy').format(date).toUpperCase();
}
