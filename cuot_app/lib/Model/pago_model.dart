// lib/Model/pago_model.dart
class Pago {
  final String id;
  final String creditoId;
  final int numeroCuota;
  final DateTime fechaPago;
  final double monto;
  final DateTime? fechaPagoReal;
  final String estado; // 'pendiente', 'pagado', 'atrasado'
  final String? metodoPago; // 'efectivo', 'transferencia', 'tarjeta'
  final String? referencia; // 👈 NUEVO
  final String? observaciones; // 👈 NUEVO

  Pago({
    required this.id,
    required this.creditoId,
    required this.numeroCuota,
    required this.fechaPago,
    required this.monto,
    this.fechaPagoReal,
    this.estado = 'pendiente',
    this.metodoPago,
    this.referencia,
    this.observaciones,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creditoId': creditoId,
      'numeroCuota': numeroCuota,
      'fechaPago': fechaPago.toIso8601String(),
      'monto': monto,
      'fechaPagoReal': fechaPagoReal?.toIso8601String(),
      'estado': estado,
      'metodoPago': metodoPago,
      'referencia': referencia,
      'observaciones': observaciones,
    };
  }

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'].toString(),
      creditoId: json['creditoId'].toString(),
      numeroCuota: json['numeroCuota'],
      fechaPago: DateTime.parse(json['fechaPago']),
      monto: (json['monto'] as num).toDouble(),
      fechaPagoReal: json['fechaPagoReal'] != null 
          ? DateTime.parse(json['fechaPagoReal']) 
          : null,
      estado: json['estado'] ?? 'pendiente',
      metodoPago: json['metodoPago'],
      referencia: json['referencia'],
      observaciones: json['observaciones'],
    );
  }

  Pago copyWith({
    String? id,
    String? creditoId,
    int? numeroCuota,
    DateTime? fechaPago,
    double? monto,
    DateTime? fechaPagoReal,
    String? estado,
    String? metodoPago,
    String? referencia,
    String? observaciones,
  }) {
    return Pago(
      id: id ?? this.id,
      creditoId: creditoId ?? this.creditoId,
      numeroCuota: numeroCuota ?? this.numeroCuota,
      fechaPago: fechaPago ?? this.fechaPago,
      monto: monto ?? this.monto,
      fechaPagoReal: fechaPagoReal ?? this.fechaPagoReal,
      estado: estado ?? this.estado,
      metodoPago: metodoPago ?? this.metodoPago,
      referencia: referencia ?? this.referencia,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  String get fechaFormateada => 
      '${fechaPago.day.toString().padLeft(2, '0')}/'
      '${fechaPago.month.toString().padLeft(2, '0')}/'
      '${fechaPago.year}';

  bool get estaPagado => estado == 'pagado';
  bool get estaAtrasado => estado == 'atrasado' && !estaPagado;
}