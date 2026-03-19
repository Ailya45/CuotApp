import 'package:cuot_app/Model/payment_model.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier {
  final CreditService _creditService = CreditService();
  String? userName;

  // 🔴 AQUÍ SE ALMACENARÁN LOS DATOS DEL DASHBOARD
  int totalCredits = 0; // 1. Cantidad de Créditos
  double totalPaid = 0.0; // 2. Dinero abonado
  int pendingWeeklyQuotas = 0; // 3. Cuotas pendientes por semana
  double pendingBalance = 0.0; // 4. Saldo de Cuotas Pendiente
  List<PaymentModel> upcomingPayments = []; // 5. Próximos Vencimientos
  List<PaymentModel> latePayments = []; // 6. Cuotas Atrasadas

  bool isLoading = true;
  String? errorMessage;

  DashboardController({String? userName, String? correo}) {
    this.userName = userName;
    loadDashboardData();
  }

  // 🔴 MÉTODO PRINCIPAL OPTIMIZADO: Carga todo en una sola consulta
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 🚀 Una sola consulta para traer todo lo relacionado al usuario
      final creditsData =
          await _creditService.getFullCreditsData(
            userName ?? '',
            forceRefresh: forceRefresh,
          );

      _processData(creditsData);
    } catch (e) {
      print('Error en loadDashboardData: $e');
      errorMessage = 'Error al cargar datos: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _processData(List<Map<String, dynamic>> credits) {
    final now = DateTime.now();

    // Configurar rangos de fechas (mismos que en CreditService original)
    final inicioSemana = now.subtract(Duration(days: now.weekday - 1)).copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final finSemana = inicioSemana.add(const Duration(days: 7));
    final sevenDaysLater = now.add(const Duration(days: 7));
    final lateThreshold = now.subtract(const Duration(hours: 24));

    // Reiniciar contadores
    totalCredits = 0;
    totalPaid = 0.0;
    pendingWeeklyQuotas = 0;
    pendingBalance = 0.0;
    upcomingPayments = [];
    latePayments = [];

    for (var credit in credits) {
      // 1. Créditos activos
      if (credit['estado'] != 'Pagado') {
        totalCredits++;
      }

      final clienteData = credit['Clientes'];
      final clienteNombre =
          clienteData != null ? clienteData['nombre'] : 'Cliente';
      final concepto = credit['concepto'] ?? 'Crédito';
      final creditId = credit['id'].toString();

      // 2. Dinero abonado (sumar todos los pagos del crédito)
      final List<dynamic> pagosRaw = credit['Pagos'] ?? [];
      for (var p in pagosRaw) {
        totalPaid += (p['monto'] as num).toDouble();
      }

      // 3, 4, 5, 6. Analizar cuotas
      final List<dynamic> cuotasRaw = credit['Cuotas'] ?? [];
      for (var c in cuotasRaw) {
        final double monto = (c['monto'] as num).toDouble();
        final bool pagada = c['pagada'] ?? false;
        final DateTime fechaPago = DateTime.parse(c['fecha_pago']);

        if (!pagada) {
          // 4. Saldo pendiente
          pendingBalance += monto;

          // 3. Cuotas de la semana actual
          if (fechaPago.isAfter(inicioSemana) &&
              fechaPago.isBefore(finSemana)) {
            pendingWeeklyQuotas++;
          }

          // 5. Próximos vencimientos (next 7 days)
          if (fechaPago.isAfter(now) && fechaPago.isBefore(sevenDaysLater)) {
            upcomingPayments.add(PaymentModel(
              id: c['id'].toString(),
              creditId: creditId,
              amount: monto,
              date: fechaPago,
              installmentNumber: c['numero_cuota'] as int,
              status: 'pending',
              clientName: clienteNombre,
              concept: concepto,
            ));
          }

          // 6. Cuotas atrasadas
          if (fechaPago.isBefore(lateThreshold)) {
            latePayments.add(PaymentModel(
              id: c['id'].toString(),
              creditId: creditId,
              amount: monto,
              date: fechaPago,
              installmentNumber: c['numero_cuota'] as int,
              status: 'late',
              clientName: clienteNombre,
              concept: concepto,
            ));
          }
        }
      }
    }

    // Ordenar listas por fecha
    upcomingPayments.sort((a, b) => a.date.compareTo(b.date));
    latePayments.sort((a, b) => a.date.compareTo(b.date));
  }

  // Método para refrescar manualmente (pull-to-refresh)
  Future<void> refreshData() async {
    await loadDashboardData(forceRefresh: true);
  }

  String getName() {
    return userName ?? 'Usuario indefinido';
  }

  String getFirstName() {
    final name = userName ?? 'Usuario';
    return name.split(' ').first;
  }
}
