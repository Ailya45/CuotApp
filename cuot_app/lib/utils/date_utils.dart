/// Utilidades para manejo de fechas
class DateUt {
  
  /// Formatea una fecha a string dd/mm/yyyy
  static String formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
           '${fecha.month.toString().padLeft(2, '0')}/'
           '${fecha.year}';
  }

  /// Valida que las fechas estén en orden cronológico
  static bool fechasEnOrden(List<DateTime> fechas) {
    for (int i = 0; i < fechas.length - 1; i++) {
      if (fechas[i].isAfter(fechas[i + 1])) {
        return false;
      }
    }
    return true;
  }

  /// Calcula fechas sugeridas para cuotas diarias
  static List<DateTime> sugerirFechasDiarias(
    DateTime fechaInicio, 
    int cantidad
  ) {
    return List.generate(
      cantidad,
      (index) => fechaInicio.add(Duration(days: index + 1)),
    );
  }

  /// Calcula fechas sugeridas para cuotas semanales
  static List<DateTime> sugerirFechasSemanales(
    DateTime fechaInicio, 
    int cantidad
  ) {
    return List.generate(
      cantidad,
      (index) => fechaInicio.add(Duration(days: (index + 1) * 7)),
    );
  }

  /// Calcula fechas sugeridas para cuotas quincenales
  static List<DateTime> sugerirFechasQuincenales(
    DateTime fechaInicio, 
    int cantidad
  ) {
    return List.generate(
      cantidad,
      (index) => fechaInicio.add(Duration(days: (index + 1) * 15)),
    );
  }

  /// Calcula fechas sugeridas para cuotas mensuales
  static List<DateTime> sugerirFechasMensuales(
    DateTime fechaInicio, 
    int cantidad
  ) {
    return List.generate(
      cantidad,
      (index) => DateTime(
        fechaInicio.year,
        fechaInicio.month + index + 1,
        fechaInicio.day,
      ),
    );
  }

  /// Calcula la diferencia en meses entre dos fechas para el resumen
  static int calcularDiferenciaMeses(DateTime inicio, DateTime fin) {
    if (fin.isBefore(inicio)) return 0;
    int meses = (fin.year - inicio.year) * 12 + (fin.month - inicio.month);
    return meses < 0 ? 0 : meses;
  }

  /// Formatea la duración legiblemente (Ej: "15 días", "1 mes" o "2 meses y 5 días")
  /// AHORA: Conteo inclusive (incluye el día inicial y final)
  static String formatearDuracion(DateTime inicio, DateTime fin) {
    // Normalizar a medianoche para evitar problemas con horas/minutos
    final start = DateTime(inicio.year, inicio.month, inicio.day);
    final end = DateTime(fin.year, fin.month, fin.day);
    
    if (end.isBefore(start)) return '0 días';
    
    final diferenciaTotalDias = end.difference(start).inDays + 1; // +1 para ser inclusivo (27 Mar a 10 Abr = 15 días)
    
    if (diferenciaTotalDias < 30) {
      return '$diferenciaTotalDias días';
    }

    int meses = (fin.year - inicio.year) * 12 + (fin.month - inicio.month);
    
    // Ajustar los meses si el día del mes de fin es menor al de inicio
    DateTime fechaMesesCompletos = DateTime(inicio.year, inicio.month + meses, inicio.day);
    if (fechaMesesCompletos.isAfter(fin)) {
      meses--;
      fechaMesesCompletos = DateTime(inicio.year, inicio.month + meses, inicio.day);
    }
    
    // El cálculo de días restantes también debe considerar la normalización
    final startNormalized = DateTime(fechaMesesCompletos.year, fechaMesesCompletos.month, fechaMesesCompletos.day);
    final endNormalized = DateTime(fin.year, fin.month, fin.day);
    final diasRestantes = endNormalized.difference(startNormalized).inDays; // Aquí no sumamos 1 porque ya sumamos los meses
    
    // Si no hay meses completos, solo mostrar días
    if (meses == 0) {
      final totalInclusive = endNormalized.difference(DateTime(inicio.year, inicio.month, inicio.day)).inDays + 1;
      return '$totalInclusive ${totalInclusive == 1 ? 'día' : 'días'}';
    }

    String resultado = '$meses ${meses == 1 ? 'mes' : 'meses'}';
    if (diasRestantes > 0) {
      resultado += ' y $diasRestantes ${diasRestantes == 1 ? 'día' : 'días'}';
    }
    
    return resultado;
  }
}