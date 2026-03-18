import 'package:cuot_app/Model/payment_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreditService {
  final SupabaseService _supabase = SupabaseService();

  // 1. Obtener cantidad total de créditos activos
  Future<int> getTotalCredits(String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Creditos')
          .select('id')
          .eq('usuario_nombre', usuarioNombre)
          .neq('estado', 'Pagado');
      
      return (response as List).length;
    } catch (e) {
      print('Error obteniendo total de créditos: $e');
      return 0;
    }
  }

  // 2. Obtener dinero total abonado (Suma de todos los registros en la tabla Pagos)
  Future<double> getTotalPaidAmount(String usuarioNombre) async {
    try {
      // Necesitamos unir con Creditos para filtrar por usuario
      final List<dynamic> data = await _supabase.client
          .schema('Financiamientos')
          .from('Pagos')
          .select('monto, Creditos!inner(usuario_nombre)')
          .eq('Creditos.usuario_nombre', usuarioNombre);
      
      double total = 0;
      for (var row in data) {
        total += (row['monto'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Error obteniendo total abonado: $e');
      return 0.0;
    }
  }

  // 3. Obtener cuotas pendientes por semana (Próximas 4 semanas)
  Future<Map<String, int>> getPendingInstallmentsByWeek(String usuarioNombre) async {
    try {
      final now = DateTime.now();
      // Ajustar al inicio de la semana (Lunes)
      final inicioSemana = now.subtract(Duration(days: now.weekday - 1)).copyWith(hour: 0, minute: 0, second: 0);
      final finSemana = inicioSemana.add(const Duration(days: 7));

      final data = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .select('fecha_pago, Creditos!inner(usuario_nombre)')
          .eq('pagada', false)
          .eq('Creditos.usuario_nombre', usuarioNombre)
          .gte('fecha_pago', inicioSemana.toIso8601String())
          .lt('fecha_pago', finSemana.toIso8601String());

      return {'actual': data.length};
    } catch (e) {
      print('Error obteniendo cuotas por semana: $e');
      return {'actual': 0};
    }
  }

  // 4. Obtener saldo total pendiente de cuotas
  Future<double> getTotalPendingAmount(String usuarioNombre) async {
    try {
      final data = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .select('monto, Creditos!inner(usuario_nombre)')
          .eq('pagada', false)
          .eq('Creditos.usuario_nombre', usuarioNombre);
      
      double total = 0;
      for (var row in data) {
        total += (row['monto'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Error obteniendo saldo pendiente: $e');
      return 0.0;
    }
  }

  // 5. Obtener próximos vencimientos (próximos 7 días)
  Future<List<PaymentModel>> getUpcomingPayments(String usuarioNombre) async {
    try {
      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));
      
      final data = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .select('*, Creditos!inner(concepto, usuario_nombre, Clientes(nombre))')
          .eq('pagada', false)
          .eq('Creditos.usuario_nombre', usuarioNombre)
          .gte('fecha_pago', now.toIso8601String())
          .lte('fecha_pago', sevenDaysLater.toIso8601String())
          .order('fecha_pago');
      
      return (data as List).map((json) {
        final credit = json['Creditos'];
        final clienteNombre = credit['Clientes']['nombre'] ?? 'Cliente';
        final concepto = credit['concepto'] ?? 'Crédito';
        
        return PaymentModel(
          id: json['id'].toString(),
          creditId: json['credito_id'].toString(),
          amount: (json['monto'] as num).toDouble(),
          date: DateTime.parse(json['fecha_pago'] as String),
          installmentNumber: json['numero_cuota'] as int,
          status: 'pending',
          clientName: clienteNombre,
          concept: concepto,
        );
      }).toList();
    } catch (e) {
      print('Error obteniendo próximos vencimientos: $e');
      return [];
    }
  }

  // 6. Obtener cuotas atrasadas
  Future<List<PaymentModel>> getLatePayments(String usuarioNombre) async {
    try {
      final now = DateTime.now();
      
      final data = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .select('*, Creditos!inner(concepto, usuario_nombre, Clientes(nombre))')
          .eq('pagada', false)
          .eq('Creditos.usuario_nombre', usuarioNombre)
          .lt('fecha_pago', now.subtract(const Duration(hours: 24)).toIso8601String()) // Margen de un día
          .order('fecha_pago');
      
      return (data as List).map((json) {
        final credit = json['Creditos'];
        final clienteNombre = credit['Clientes']['nombre'] ?? 'Cliente';
        final concepto = credit['concepto'] ?? 'Crédito';

        return PaymentModel(
          id: json['id'].toString(),
          creditId: json['credito_id'].toString(),
          amount: (json['monto'] as num).toDouble(),
          date: DateTime.parse(json['fecha_pago'] as String),
          installmentNumber: json['numero_cuota'] as int,
          status: 'late',
          clientName: clienteNombre,
          concept: concepto,
        );
      }).toList();
    } catch (e) {
      print('Error obteniendo cuotas atrasadas: $e');
      return [];
    }
  }

  // Obtener todos los créditos con sus clientes
  Future<List<Map<String, dynamic>>> getCreditsWithClients(String usuarioNombre) async {
    try {
      return await _supabase.client
          .schema('Financiamientos')
          .from('Creditos')
          .select('*, Clientes(*)')
          .eq('usuario_nombre', usuarioNombre);
    } catch (e) {
      print('Error obteniendo créditos con clientes: $e');
      return [];
    }
  }

  // 🚀 OPTIMIZADO: Obtener TODO en una sola consulta (Créditos + Clientes + Cuotas + Pagos)
  // Esto resuelve el problema N+1 y reduce drásticamente el tiempo de carga.
  Future<List<Map<String, dynamic>>> getFullCreditsData(String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Creditos')
          .select('''
            *,
            Clientes(*),
            Cuotas(*),
            Pagos(*)
          ''')
          .eq('usuario_nombre', usuarioNombre)
          .order('id', ascending: false); // Ver más recientes primero
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en getFullCreditsData: $e');
      return [];
    }
  }

  // Obtener cuotas de un crédito específico
  Future<List<Map<String, dynamic>>> getInstallments(String creditId) async {
    try {
      return await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .select('*')
          .eq('credito_id', creditId)
          .order('numero_cuota');
    } catch (e) {
      print('Error obteniendo cuotas: $e');
      return [];
    }
  }

  // Obtener pagos de un crédito específico
  Future<List<Map<String, dynamic>>> getPayments(String creditId) async {
    try {
      return await _supabase.client
          .schema('Financiamientos')
          .from('Pagos')
          .select('*')
          .eq('credito_id', creditId)
          .order('fecha_pago_real');
    } catch (e) {
      print('Error obteniendo pagos: $e');
      return [];
    }
  }

  // 7. Guardar un pago y actualizar la cuota correspondiente
  Future<void> savePayment({
    required String creditId,
    required int numeroCuota,
    required double montoPagado,
    required DateTime fechaPago,
    required String metodoPago,
    String? referencia,
    String? observaciones,
    bool esPagoParcial = false,
  }) async {
    try {
      // 1. Insertar el registro de pago
      await _supabase.client
          .schema('Financiamientos')
          .from('Pagos')
          .insert({
            'credito_id': creditId,
            'numero_cuota': numeroCuota,
            'monto': montoPagado,
            'fecha_pago_real': fechaPago.toIso8601String(),
            'metodo_pago': metodoPago,
            'referencia': referencia,
            'observaciones': observaciones,
          });

      // 2. Obtener la cuota actual
      final List<dynamic> cuotas = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .select('monto')
          .eq('credito_id', creditId)
          .eq('numero_cuota', numeroCuota);

      if (cuotas.isNotEmpty) {
        final double montoActual = (cuotas[0]['monto'] as num).toDouble();
        final double nuevoMonto = montoActual - montoPagado;
        final bool pagada = nuevoMonto <= 0.01; // Tolerancia para punto flotante

        // 3. Actualizar la cuota
        await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas')
            .update({
              'monto': nuevoMonto > 0 ? nuevoMonto : 0,
              'pagada': pagada,
            })
            .eq('credito_id', creditId)
            .eq('numero_cuota', numeroCuota);
      }
    } catch (e) {
      print('Error al guardar pago: $e');
      rethrow;
    }
  }
}