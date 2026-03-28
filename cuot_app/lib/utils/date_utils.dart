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
      (index) => fechaInicio.add(Duration(days: index)),
    );
  }

  /// Calcula fechas sugeridas para cuotas semanales
  static List<DateTime> sugerirFechasSemanales(
    DateTime fechaInicio, 
    int cantidad
  ) {
    return List.generate(
      cantidad,
      (index) => fechaInicio.add(Duration(days: index * 7)),
    );
  }

  /// Calcula fechas sugeridas para cuotas quincenales
  static List<DateTime> sugerirFechasQuincenales(
    DateTime fechaInicio, 
    int cantidad
  ) {
    return List.generate(
      cantidad,
      (index) => fechaInicio.add(Duration(days: index * 15)),
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
        fechaInicio.month + index,
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
    // Normalizar a UTC para evitar problemas con DST/Horarios de verano
    final start = DateTime.utc(inicio.year, inicio.month, inicio.day);
    final end = DateTime.utc(fin.year, fin.month, fin.day);
    
    if (end.isBefore(start)) return '0 días';
    
    // Diferencia total de días inclusive
    final diferenciaTotalDias = end.difference(start).inDays + 1;
    
    // Si es menos de 30 días, mostrar solo días
    if (diferenciaTotalDias < 30) {
      return '$diferenciaTotalDias ${diferenciaTotalDias == 1 ? 'día' : 'días'}';
    }

    // Cálculo de meses completos
    int meses = (fin.year - inicio.year) * 12 + (fin.month - inicio.month);
    
    // Fecha tentativa después de 'meses' completos
    DateTime fechaMesesCompletos = DateTime(inicio.year, inicio.month + meses, inicio.day);
    
    // Si la fecha tentativa se pasa de la fecha fin, retroceder un mes
    if (fechaMesesCompletos.isAfter(fin)) {
      meses--;
      fechaMesesCompletos = DateTime(inicio.year, inicio.month + meses, inicio.day);
    }
    
    // Calcular días restantes después de meses completos
    final startNormalized = DateTime.utc(fechaMesesCompletos.year, fechaMesesCompletos.month, fechaMesesCompletos.day);
    final endNormalized = DateTime.utc(fin.year, fin.month, fin.day);
    
    // En el conteo de meses "1 mes y 0 días" es un mes exacto.
    // El "+1" de lo inclusivo ya está absorbido en la lógica de meses si coincide el día,
    // pero si no, queremos los días restantes inclusive también.
    // Si inicio 27 y fin 31, meses = 0, totalInclusive = 5.
    
    if (meses == 0) {
      return '$diferenciaTotalDias ${diferenciaTotalDias == 1 ? 'día' : 'días'}';
    }

    // Días restantes inclusive desde la fecha de meses completos
    // Si inicio 20 y fin 20 del mes siguiente, meses = 1, diasRestantes = 0.
    final diasRestantes = endNormalized.difference(startNormalized).inDays;
    
    String resultado = '$meses ${meses == 1 ? 'mes' : 'meses'}';
    if (diasRestantes > 0) {
      // Si sumamos días a una cuenta de meses, esos días ya son el "resto"
      resultado += ' y $diasRestantes ${diasRestantes == 1 ? 'día' : 'días'}';
    }
    
    return resultado;
  }
}