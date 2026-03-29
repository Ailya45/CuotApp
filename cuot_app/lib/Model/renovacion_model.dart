/// Modelo de Renovación de Crédito
class Renovacion {
  final String? id; // UUID
  final String creditoOriginalId; // UUID
  final String? creditoNuevoId; // UUID
  final String clienteId; // UUID
  final String? motivo;
  final Map<String, dynamic> condicionesAnteriores;
  final Map<String, dynamic> condicionesNuevas;
  final int nuevoPlazo;
  final String unidadPlazo; // meses, dias, semanas, quincenas
  final double nuevaTasaInteres;
  final double nuevoMontoCuota;
  final double montoAbono;
  final bool incluirMora;
  final double montoMora;
  final DateTime fechaRenovacion;
  final String? usuarioAutoriza;
  final String estado; // solicitada, aprobada, rechazada, cancelada
  final String? observaciones;
  final DateTime? createdAt;

  Renovacion({
    this.id,
    required this.creditoOriginalId,
    this.creditoNuevoId,
    required this.clienteId,
    this.motivo,
    this.condicionesAnteriores = const {},
    this.condicionesNuevas = const {},
    required this.nuevoPlazo,
    this.unidadPlazo = 'meses',
    this.nuevaTasaInteres = 0,
    this.nuevoMontoCuota = 0,
    this.montoAbono = 0,
    this.incluirMora = false,
    this.montoMora = 0,
    DateTime? fechaRenovacion,
    this.usuarioAutoriza,
    this.estado = 'solicitada',
    this.observaciones,
    this.createdAt,
  }) : fechaRenovacion = fechaRenovacion ?? DateTime.now();

  factory Renovacion.fromJson(Map<String, dynamic> json) {
    return Renovacion(
      id: json['id']?.toString(),
      creditoOriginalId: json['credito_original_id'].toString(),
      creditoNuevoId: json['credito_nuevo_id']?.toString(),
      clienteId: json['cliente_id'].toString(),
      motivo: json['motivo'],
      condicionesAnteriores: json['condiciones_anteriores'] is Map
          ? Map<String, dynamic>.from(json['condiciones_anteriores'])
          : {},
      condicionesNuevas: json['condiciones_nuevas'] is Map
          ? Map<String, dynamic>.from(json['condiciones_nuevas'])
          : {},
      nuevoPlazo: json['nuevo_plazo'] ?? 0,
      unidadPlazo: json['unidad_plazo'] ?? 'meses',
      nuevaTasaInteres: (json['nueva_tasa_interes'] as num?)?.toDouble() ?? 0,
      nuevoMontoCuota: (json['nuevo_monto_cuota'] as num?)?.toDouble() ?? 0,
      montoAbono: (json['monto_abono'] as num?)?.toDouble() ?? 0,
      incluirMora: json['incluir_mora'] ?? false,
      montoMora: (json['monto_mora'] as num?)?.toDouble() ?? 0,
      fechaRenovacion: json['fecha_renovacion'] != null
          ? DateTime.parse(json['fecha_renovacion'])
          : DateTime.now(),
      usuarioAutoriza: json['usuario_autoriza'],
      estado: json['estado'] ?? 'solicitada',
      observaciones: json['observaciones'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'credito_original_id': creditoOriginalId,
        if (creditoNuevoId != null) 'credito_nuevo_id': creditoNuevoId,
        'cliente_id': clienteId,
        'motivo': motivo,
        'condiciones_anteriores': condicionesAnteriores,
        'condiciones_nuevas': condicionesNuevas,
        'nuevo_plazo': nuevoPlazo,
        'unidad_plazo': unidadPlazo,
        'nueva_tasa_interes': nuevaTasaInteres,
        'nuevo_monto_cuota': nuevoMontoCuota,
        'monto_abono': montoAbono,
        'incluir_mora': incluirMora,
        'monto_mora': montoMora,
        'fecha_renovacion': fechaRenovacion.toIso8601String(),
        'usuario_autoriza': usuarioAutoriza,
        'estado': estado,
        'observaciones': observaciones,
      };
}

/// Modelo de Historial de Renovación (auditoría)
class HistorialRenovacion {
  final String? id; // UUID
  final String renovacionId; // UUID
  final String? estadoAnterior;
  final String estadoNuevo;
  final DateTime fechaCambio;
  final String? usuarioId;
  final String? observaciones;

  HistorialRenovacion({
    this.id,
    required this.renovacionId,
    this.estadoAnterior,
    required this.estadoNuevo,
    DateTime? fechaCambio,
    this.usuarioId,
    this.observaciones,
  }) : fechaCambio = fechaCambio ?? DateTime.now();

  factory HistorialRenovacion.fromJson(Map<String, dynamic> json) {
    return HistorialRenovacion(
      id: json['id']?.toString(),
      renovacionId: json['renovacion_id'].toString(),
      estadoAnterior: json['estado_anterior'],
      estadoNuevo: json['estado_nuevo'],
      fechaCambio: json['fecha_cambio'] != null
          ? DateTime.parse(json['fecha_cambio'])
          : DateTime.now(),
      usuarioId: json['usuario_id'],
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() => {
        'renovacion_id': renovacionId,
        'estado_anterior': estadoAnterior,
        'estado_nuevo': estadoNuevo,
        'fecha_cambio': fechaCambio.toIso8601String(),
        'usuario_id': usuarioId,
        'observaciones': observaciones,
      };
}
