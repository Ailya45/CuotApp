import 'package:cuot_app/Model/cuota_personalizada.dart';

enum TipoCredito { cuotas, unPago }
enum ModalidadPago { diario, semanal, quincenal, mensual, personalizado }
/// Modelo principal de Crédito
class Credito {
  
  // 📌 CAMPOS BÁSICOS
  final String concepto;
  final double costeInversion;
  final double margenGanancia;
  final DateTime fechaInicio;
  final ModalidadPago modalidadPago;
  final String nombreCliente;
  final int numeroCuotas;
  
  // 📌 CAMPOS OPCIONALES
  final String? facturaPath;
  final String? nombreFactura;
  final String? telefono;
  final DateTime? fechaLimite; // Solo para pago único

  String? id;
  List<Cuota>? cuotasPersonalizadas;
  List<CuotaPersonalizada>? fechasPersonalizadas;
  
  // Campos calculados
  double get precioTotal => costeInversion + margenGanancia;
  double get valorCuota {
    if (numeroCuotas == null || numeroCuotas == 0) return 0;
    return precioTotal / numeroCuotas;
  }
  
  // 📌 NUEVO: Lista de fechas personalizadas para cada cuota

  Credito({
    required this.concepto,
    required this.costeInversion,
    required this.margenGanancia,
    required this.fechaInicio,
    required this.modalidadPago,
    required this.nombreCliente,
    required this.numeroCuotas,
    this.telefono,
    this.facturaPath,
    this.nombreFactura,
    this.fechasPersonalizadas,
    this.fechaLimite,
  });

  /// Propiedades calculadas
  double get valorPorCuota => numeroCuotas > 0 ? precioTotal / numeroCuotas : 0;

  /// Fecha de finalización estimada (última cuota)
  DateTime? get fechaFinEstimada {
    if (fechasPersonalizadas != null && fechasPersonalizadas!.isNotEmpty) {
      return fechasPersonalizadas!.last.fechaPago;
    }
    
    // Si no hay fechas personalizadas, calcular según modalidad
    if (numeroCuotas <= 0) return null;
    
    switch (modalidadPago) {
      case ModalidadPago.diario:
        return fechaInicio.add(Duration(days: numeroCuotas));
      case ModalidadPago.semanal:
        return fechaInicio.add(Duration(days: numeroCuotas * 7));
      case ModalidadPago.quincenal:
        return fechaInicio.add(Duration(days: numeroCuotas * 15));
      case ModalidadPago.mensual:
        return DateTime(
          fechaInicio.year,
          fechaInicio.month + numeroCuotas,
          fechaInicio.day,
        );
      case ModalidadPago.personalizado:
        return null; // No se puede calcular automáticamente
    }
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() => {
    'concepto': concepto,
    'costeInversion': costeInversion,
    'margenGanancia': margenGanancia,
    'fechaInicio': fechaInicio.toIso8601String(),
    'modalidadPago': modalidadPago.index,
    'nombreCliente': nombreCliente,
    'telefono': telefono,
    'numeroCuotas': numeroCuotas,
    'facturaPath': facturaPath,
    'nombreFactura': nombreFactura,
    'fechaLimite': fechaLimite?.toIso8601String(),
    'fechasPersonalizadas': fechasPersonalizadas?.map((c) => c.toJson()).toList(),
  };

  /// Crea desde JSON
  factory Credito.fromJson(Map<String, dynamic> json) {
    return Credito(
      concepto: json['concepto'],
      costeInversion: json['costeInversion'].toDouble(),
      margenGanancia: json['margenGanancia'].toDouble(),
      fechaInicio: DateTime.parse(json['fechaInicio']),
      modalidadPago: ModalidadPago.values[json['modalidadPago']],
      nombreCliente: json['nombreCliente'],
      telefono: json['telefono'],
      numeroCuotas: json['numeroCuotas'],
      facturaPath: json['facturaPath'],
      fechaLimite: json['fechaLimite'] != null ? DateTime.parse(json['fechaLimite']) : null,
      nombreFactura: json['nombreFactura'],
      fechasPersonalizadas: json['fechasPersonalizadas'] != null
          ? (json['fechasPersonalizadas'] as List)
              .map((c) => CuotaPersonalizada.fromJson(c))
              .toList()
          : null,
    );
  }

  bool get estaVencido => false;
}

class Cuota {
  int numero;
  DateTime fechaPago;
  double monto;
  bool pagada;

  Cuota({
    required this.numero,
    required this.fechaPago,
    required this.monto,
    this.pagada = false,
  });
}

