import 'package:intl/intl.dart';

class Formatters {
  // 🔧 LÓGICA: Formatear bolívares
  static String formatBolivares(double value) {
    final formatter = NumberFormat.currency(
      locale: 'es_VE',
      symbol: 'Bs.',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  // 🔧 LÓGICA: Formatear moneda
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  // 🔧 LÓGICA: Formatear número con separadores de miles
  static String formatNumber(double value) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(value);
  }

  // 🔧 LÓGICA: Formatear teléfono (XXX) XXX-XXXX
  static String formatPhone(String phone) {
    // Eliminar caracteres no numéricos
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    return phone;
  }

  // 🔧 LÓGICA: Formatear cédula (con puntos)
  static String formatCedula(String cedula) {
    final digits = cedula.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)}.${digits.substring(3)}';
    }
    if (digits.length <= 9) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6)}';
    }
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }

  // 🔧 LÓGICA: Formatear fecha
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    final formatter = DateFormat(format, 'es');
    return formatter.format(date);
  }

  // 🔧 LÓGICA: Formatear fecha y hora
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'es');
    return formatter.format(date);
  }

  // 🔧 LÓGICA: Formatear porcentaje
  static String formatPercent(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  // 🔧 LÓGICA: Formatear tiempo relativo (hace X minutos)
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return 'hace ${(difference.inDays / 365).floor()} años';
    } else if (difference.inDays > 30) {
      return 'hace ${(difference.inDays / 30).floor()} meses';
    } else if (difference.inDays > 0) {
      return 'hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minutos';
    } else {
      return 'ahora mismo';
    }
  }

  // 🔧 LÓGICA: Truncar texto con puntos suspensivos
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // 🔧 LÓGICA: Capitalizar primera letra
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // 🔧 LÓGICA: Capitalizar cada palabra
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // 🔧 LÓGICA: Limpiar texto (eliminar espacios extras)
  static String cleanText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // 🔧 LÓGICA: Formatear número de cuenta bancaria
  static String formatBankAccount(String account) {
    final digits = account.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return digits;
    
    // Agrupar de 4 en 4
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i += 4) {
      if (i + 4 < digits.length) {
        buffer.write('${digits.substring(i, i + 4)} ');
      } else {
        buffer.write(digits.substring(i));
      }
    }
    return buffer.toString();
  }
}

// 🔧 LÓGICA: Extensiones para DateTime
extension DateTimeExtension on DateTime {
  String toFormattedString({String format = 'dd/MM/yyyy'}) {
    return Formatters.formatDate(this, format: format);
  }

  String toRelativeString() {
    return Formatters.formatRelativeTime(this);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

// 🔧 LÓGICA: Extensiones para String
extension StringExtension on String {
  String capitalize() {
    return Formatters.capitalize(this);
  }

  String capitalizeWords() {
    return Formatters.capitalizeWords(this);
  }

  String clean() {
    return Formatters.cleanText(this);
  }

  String truncate(int maxLength) {
    return Formatters.truncate(this, maxLength);
  }

  String toPhoneFormat() {
    return Formatters.formatPhone(this);
  }

  String toCedulaFormat() {
    return Formatters.formatCedula(this);
  }
}

// 🔧 LÓGICA: Extensiones para double/num
extension NumberExtension on num {
  String toCurrency() {
    return Formatters.formatCurrency(toDouble());
  }

  String toFormattedNumber() {
    return Formatters.formatNumber(toDouble());
  }

  String toPercent() {
    return Formatters.formatPercent(toDouble());
  }
}