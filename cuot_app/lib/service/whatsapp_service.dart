import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  /// Genera la ficha de préstamo en formato WhatsApp
  static String generarFichaPrestamo({
    required String creditoId,
    required String nombreCliente,
    required String modalidadPago,
    required int plazoDias,
    required int totalPrestamos,
    required int totalRenovaciones,
    required int aTiempo,
    required int retrasado,
    required double cantidadMaxima,
    required double montoPrestamo,
    required double interes,
    required double montoTotal,
    required int cantidadAbonos,
    required double montoAbonado,
    required double resta,
    required String fechaLimite,
    required String diasRestantes,
  }) {
    // Build modalidad checkmarks
    final modalidades = {
      'Diario': modalidadPago.toLowerCase() == 'diario',
      'Semanal': modalidadPago.toLowerCase() == 'semanal',
      'Quincenal': modalidadPago.toLowerCase() == 'quincenal',
      'Trisemanal': modalidadPago.toLowerCase() == 'trisemanal',
      'Mensual': modalidadPago.toLowerCase() == 'mensual',
      'Pago Simple': modalidadPago.toLowerCase() == 'unico' || 
                     modalidadPago.toLowerCase() == 'pago único' ||
                     modalidadPago.toLowerCase() == 'pago simple',
    };

    String modalidadSection = '';
    for (var entry in modalidades.entries) {
      final check = entry.value ? '✅' : '';
      modalidadSection += '* ${entry.key}$check\n';
    }

    return '''*Ficha de Préstamo*

Cliente: *$nombreCliente*

*Modalidad de pago*💸
$modalidadSection
*Tiempo* ⏱️
* $plazoDias Días

*Historial*📇
Prestamos: *$totalPrestamos*
Renovación: *$totalRenovaciones*
A tiempo: *$aTiempo*
Retrasado: *$retrasado*
Cantidad máxima: *\$${cantidadMaxima.toStringAsFixed(1)}*

*Registro 💰:*
Préstamo: *\$${montoPrestamo.toStringAsFixed(1)}*
Interés: *\$${interes.toStringAsFixed(1)}*
Monto: *\$${montoTotal.toStringAsFixed(1)}*
Cant. Abonos: *$cantidadAbonos*
Monto Abonado: *\$${montoAbonado.toStringAsFixed(1)}*
Resta: *\$${resta.toStringAsFixed(1)}*
Fecha límite: *$fechaLimite*
Días restantes: *$diasRestantes*''';
  }

  /// Genera una ficha simplificada para créditos en cuotas
  static String generarFichaCuotas({
    required String creditoId,
    required String nombreCliente,
    required String concepto,
    required String modalidadPago,
    required double montoTotal,
    required double totalPagado,
    required double saldoPendiente,
    required int totalCuotas,
    required int cuotasPagadas,
    required int cuotasVencidas,
    required double montoCuota,
  }) {
    return '''*Ficha de Préstamo*

Cliente: *$nombreCliente*
Concepto: *$concepto*

*Modalidad de pago*💸: $modalidadPago

*Registro 💰:*
Monto Total: *\$${montoTotal.toStringAsFixed(2)}*
Total Pagado: *\$${totalPagado.toStringAsFixed(2)}*
Saldo Pendiente: *\$${saldoPendiente.toStringAsFixed(2)}*
Cuota: *\$${montoCuota.toStringAsFixed(2)}*

*Cuotas*📇:
Total: *$totalCuotas*
Pagadas: *$cuotasPagadas*
Vencidas: *$cuotasVencidas*
Pendientes: *${totalCuotas - cuotasPagadas}*''';
  }

  /// Genera una ficha simplificada para crédito único
  static String generarFichaUnico({
    required String creditoId,
    required String nombreCliente,
    required String concepto,
    required double montoTotal,
    required double totalPagado,
    required double saldoPendiente,
    required int cantidadAbonos,
    required String fechaLimite,
    required String diasRestantes,
  }) {
    return '''*Ficha de Préstamo*

Cliente: *$nombreCliente*
Concepto: *$concepto*

*Modalidad de pago*💸: Pago Simple

*Registro 💰:*
Monto Total: *\$${montoTotal.toStringAsFixed(2)}*
Cant. Abonos: *$cantidadAbonos*
Monto Abonado: *\$${totalPagado.toStringAsFixed(2)}*
Resta: *\$${saldoPendiente.toStringAsFixed(2)}*
Fecha límite: *$fechaLimite*
Días restantes: *$diasRestantes*''';
  }

  /// Abre WhatsApp con el mensaje dado
  static Future<void> abrirWhatsApp({
    required String telefono,
    required String mensaje,
  }) async {
    // Limpiar el número de teléfono
    String numero = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Si no tiene código de país, agregar código de Venezuela
    if (!numero.startsWith('+') && !numero.startsWith('58')) {
      if (numero.startsWith('0')) {
        numero = '58${numero.substring(1)}';
      } else {
        numero = '58$numero';
      }
    }
    if (numero.startsWith('+')) {
      numero = numero.substring(1);
    }

    final encodedMessage = Uri.encodeComponent(mensaje);
    final webUrl = Uri.parse('https://wa.me/$numero?text=$encodedMessage');
    
    try {
      // Intentar primero con el esquema de la app si fuera posible (opcional), 
      // pero wa.me es el estándar más compatible.
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error al abrir WhatsApp: $e');
      // Fallback a lanzamiento simple en navegador si el anterior falla
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.platformDefault);
      } else {
        throw Exception('No se pudo abrir WhatsApp');
      }
    }
  }
}
