// lib/Model/credito_unico_model.dart
import 'dart:ui';

import 'package:cuot_app/Model/pago_model.dart';
import 'package:flutter/material.dart';

enum TipoPagoUnico {
  unico,      // Pago único en una fecha específica
  parcial,    // Pago parcial con fecha límite
}

class CreditoUnico {
  final String id;
  final String nombreCliente;
  final String telefono;
  final String concepto;
  final double montoTotal;
  final DateTime fechaLimite;
  final DateTime? fechaInicio;
  final TipoPagoUnico tipoPago;
  final List<Pago> pagosRealizados;
  
  // Campos adicionales
  final String? descripcion;
  final String? notas;

  CreditoUnico({
    required this.id,
    required this.nombreCliente,
    required this.telefono,
    required this.concepto,
    required this.montoTotal,
    required this.fechaLimite,
    this.fechaInicio,
    required this.tipoPago,
    this.pagosRealizados = const [],
    this.descripcion,
    this.notas,
  });

  double get totalPagado => 
      pagosRealizados.fold(0, (sum, pago) => sum + pago.monto);

  double get saldoPendiente => montoTotal - totalPagado;

  double get progreso => montoTotal > 0 ? totalPagado / montoTotal : 0;

  bool get estaPagado => (saldoPendiente).abs() < 0.01;

  bool get estaVencido {
    if (estaPagado) return false;
    final hoy = DateTime.now();
    final fechaLimiteSinHora = DateTime(
      fechaLimite.year, 
      fechaLimite.month, 
      fechaLimite.day
    );
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    return hoySinHora.isAfter(fechaLimiteSinHora);
  }

  String get estado {
    if (estaPagado) return 'Pagado';
    if (estaVencido) return 'Vencido';
    return 'Al día';
  }

  Color get estadoColor {
    if (estaPagado) return Colors.green;
    if (estaVencido) return Colors.red;
    if (progreso > 0.7) return Colors.orange;
    return Colors.blue;
  }

  IconData get estadoIcon {
    if (estaPagado) return Icons.check_circle;
    if (estaVencido) return Icons.warning;
    return Icons.access_time;
  }
}