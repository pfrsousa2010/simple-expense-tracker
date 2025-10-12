import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static String formatCurrency(double value) {
    return _currencyFormat.format(value);
  }

  static String formatMonth(DateTime date) {
    final format = DateFormat('MMMM yyyy', 'pt_BR');
    return format
        .format(date)
        .replaceFirst(
          format.format(date)[0],
          format.format(date)[0].toUpperCase(),
        );
  }

  static String formatMonthShort(DateTime date) {
    final format = DateFormat('MMM yyyy', 'pt_BR');
    return format
        .format(date)
        .replaceFirst(
          format.format(date)[0],
          format.format(date)[0].toUpperCase(),
        );
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  static String formatDay(int day) {
    return 'Dia $day';
  }

  static String getStatusText(int statusIndex) {
    switch (statusIndex) {
      case 0:
        return 'Pago';
      case 1:
        return 'Agendado';
      case 2:
        return 'Débito Automático';
      case 3:
        return 'A pagar';
      default:
        return 'Desconhecido';
    }
  }
}
