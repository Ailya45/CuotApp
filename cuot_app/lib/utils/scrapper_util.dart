import 'package:http/io_client.dart';
import 'dart:io';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

class ScrapperUtil {
  /// Fetches the current USD exchange rate from the BCV website.
  /// Returns null if the rate cannot be fetched or parsed.
  static Future<double?> getDolarBcv() async {
    try {
      // 🛡️ SOLUCIÓN PARA ERROR DE CERTIFICADO SSL (CERTIFICATE_VERIFY_FAILED)
      // Creamos un cliente que ignore la validación de certificados para el BCV
      final HttpClient httpClient = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      final IOClient ioClient = IOClient(httpClient);

      // BCV website URL
      final response = await ioClient.get(Uri.parse('https://www.bcv.org.ve/'));
      
      if (response.statusCode == 200) {
        Document document = parser.parse(response.body);
        
        // Target the USD rate container
        final dolarElement = document.querySelector('#dolar strong');
        
        if (dolarElement != null) {
          String rateString = dolarElement.text.trim();
          rateString = rateString.replaceAll(',', '.');
          return double.tryParse(rateString);
        }
      }
      return null;
    } catch (e) {
      print('❌ Error fetching BCV rate: $e');
      return null;
    }
  }
}