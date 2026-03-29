import 'dart:io';

class NetworkUtils {
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static String getFriendlyErrorMessage(Object e) {
    final errorStr = e.toString().toLowerCase();
    
    if (e is SocketException || 
        errorStr.contains('socketexception') || 
        errorStr.contains('failed host lookup') ||
        errorStr.contains('network_error') ||
        errorStr.contains('connection failed')) {
      return 'Sin conexión a internet. Por favor verifica tu red.';
    }
    
    if (errorStr.contains('postgrestexception')) {
      // Intentar extraer un mensaje más limpio de PostgrestException si es posible
      if (errorStr.contains('invalid login credentials') || errorStr.contains('invalid_credentials')) {
        return 'Credenciales inválidas. Por favor intenta de nuevo.';
      }
      return 'Error de base de datos. Por favor intenta más tarde.';
    }

    return e.toString().replaceAll('Exception:', '').trim();
  }
}
