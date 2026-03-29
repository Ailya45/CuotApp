import 'package:cuot_app/Model/renovacion_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';

class RenovacionService {
  final SupabaseService _supabase = SupabaseService();

  /// Crear una nueva renovación + primer registro de historial
  Future<Renovacion> crearRenovacion(Renovacion renovacion) async {
    try {
      // 1. Insertar la renovación
      final data = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .insert(renovacion.toJson())
          .select()
          .single();

      final nuevaRenovacion = Renovacion.fromJson(data);

      // 2. Si hay un abono registrado al momento de la renovación, inyectarlo en Pagos para mantener el historial
      if (renovacion.montoAbono > 0) {
        await _supabase.client
            .schema('Financiamientos')
            .from('Pagos')
            .insert({
              'credito_id': renovacion.creditoOriginalId,
              'numero_cuota': 1, // Se aloja genéricamente acá
              'monto': renovacion.montoAbono,
              'fecha_pago_real': DateTime.now().toUtc().toIso8601String(),
              'metodo_pago': 'efectivo',
              'referencia': 'Abono en Renovación',
              'observaciones': 'Abono inyectado y cobrado durante procedimiento de Renovación',
            });
      }

      // 3. Si está aprobada, actualizar el crédito original
      if (renovacion.estado == 'aprobada') {
        await _aplicarRenovacionAlCredito(renovacion);
      }

      // 4. Registrar en historial
      await _supabase.client
          .schema('Financiamientos')
          .from('Historial_Renovaciones')
          .insert(HistorialRenovacion(
            renovacionId: nuevaRenovacion.id!,
            estadoAnterior: null,
            estadoNuevo: renovacion.estado,
            usuarioId: renovacion.usuarioAutoriza,
            observaciones: 'Renovación creada y aplicada',
          ).toJson());

      return nuevaRenovacion;
    } catch (e) {
      print('Error al crear renovación: $e');
      rethrow;
    }
  }

  Future<void> _aplicarRenovacionAlCredito(Renovacion renovacion) async {
    final condicionesNuevas = renovacion.condicionesNuevas;
    final tipoCredito = condicionesNuevas['tipo_credito'] ?? 'cuotas';
    
    // EL MONTO "TOTAL" QUE LLEGA DESDE EL FORMULARIO ES REALMENTE EL "SALDO PENDIENTE DESEADO" (EJ: $36)
    final double nuevoSaldoPendienteDeseado = (condicionesNuevas['monto_total'] as num).toDouble();
    
    final double saldoPendienteOriginal = (renovacion.condicionesAnteriores['saldo_pendiente'] ?? 0).toDouble();
    final double montoTotalOriginal = (renovacion.condicionesAnteriores['monto_total'] ?? 0).toDouble();
    final double abonoEnRenovacion = (condicionesNuevas['abono'] ?? 0).toDouble();
    
    // Extraemos qué cantidad de dinero había ingresado antes de esta renovación en este mismo crédito.
    final double totalPagadoHistorico = montoTotalOriginal - saldoPendienteOriginal;
    
    // 1. Calcular el Verdadero Gross Total
    // El Precio Etiqueta (Gross Contract Sum) de la Base de Datos debe ser el Saldo Deseado + Todo lo ya pagado + lo pagado ahora.
    // Esto asegura que Seguimiento (Total - Sum(Pagos)) siga igual al saldo deseado.
    final double verdaderoGrossTotal = nuevoSaldoPendienteDeseado + totalPagadoHistorico + abonoEnRenovacion;

    final double costoInversionOriginal = (renovacion.condicionesAnteriores['costo_inversion'] ?? 0).toDouble();
    final double nuevoMargen = verdaderoGrossTotal - costoInversionOriginal;

    Map<String, dynamic> updateData = {
      'margen_ganancia': nuevoMargen,
      'numero_cuotas': renovacion.nuevoPlazo,
    };

    if (tipoCredito == 'unico' && condicionesNuevas['fecha_pago_nueva'] != null) {
      // Nota: Si la tabla tiene un campo fecha_vencimiento, usarlo. 
      // Si no, se actualiza solo en la cuota.
    }

    await _supabase.client
        .schema('Financiamientos')
        .from('Creditos')
        .update(updateData)
        .eq('id', renovacion.creditoOriginalId);

    // 2. Gestionar Cuotas
    if (tipoCredito == 'unico') {
      // Actualizar la cuota única existente o crearla si no hay
      await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .update({
            'monto': nuevoSaldoPendienteDeseado,
            'pagada': false,
            if (condicionesNuevas['fecha_pago_nueva'] != null) 
              'fecha_pago': condicionesNuevas['fecha_pago_nueva'],
          })
          .eq('credito_id', renovacion.creditoOriginalId)
          .eq('numero_cuota', 1);
    } else {
      // Eliminar cuotas NO PAGADAS
      await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .delete()
          .eq('credito_id', renovacion.creditoOriginalId)
          .eq('pagada', false);

      // Insertar las nuevas cuotas editadas
      final List<dynamic> cuotasRenovadas = condicionesNuevas['cuotas_renovadas'] ?? [];
      // Obtener el número de la última cuota pagada para no duplicar índices
      final List<dynamic> pagadas = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .select('numero_cuota')
          .eq('credito_id', renovacion.creditoOriginalId)
          .eq('pagada', true)
          .order('numero_cuota', ascending: false)
          .limit(1);

      int contador = 1;
      if (pagadas.isNotEmpty) {
        contador = (pagadas[0]['numero_cuota'] as int) + 1;
      }
      
      final List<Map<String, dynamic>> cuotasParaInsertar = [];
      for (var c in cuotasRenovadas) {
        cuotasParaInsertar.add({
          'credito_id': renovacion.creditoOriginalId,
          'numero_cuota': contador++, // Re-numeramos para mantener orden
          'monto': c['monto'],
          'fecha_pago': c['fecha'],
          'pagada': false,
        });
      }

      if (cuotasParaInsertar.isNotEmpty) {
        await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas')
            .insert(cuotasParaInsertar);
      }
    }
  }

  /// Obtener todas las renovaciones (con datos de cliente y crédito)
  Future<List<Renovacion>> getRenovaciones(String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .select('''
            *,
            Creditos!credito_original_id(concepto, Clientes(nombre))
          ''')
          .eq('usuario_autoriza', usuarioNombre)
          .order('fecha_renovacion', ascending: false);

      return List<Map<String, dynamic>>.from(response).map((json) {
        return Renovacion.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error al obtener renovaciones: $e');
      return [];
    }
  }

  /// Obtener renovaciones con datos raw para la UI
  Future<List<Map<String, dynamic>>> getRenovacionesRaw(String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .select('''
            *,
            Creditos!credito_original_id(concepto, costo_inversion, margen_ganancia, numero_cuotas, modalidad_pago, Clientes(nombre, telefono))
          ''')
          .eq('usuario_autoriza', usuarioNombre)
          .order('fecha_renovacion', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener renovaciones raw: $e');
      return [];
    }
  }

  /// Obtener renovaciones de un crédito específico
  Future<List<Renovacion>> getRenovacionesPorCredito(String creditoId) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .select()
          .eq('credito_original_id', creditoId)
          .order('fecha_renovacion', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => Renovacion.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al obtener renovaciones del crédito: $e');
      return [];
    }
  }

  /// Contar renovaciones de un crédito
  Future<int> contarRenovaciones(String creditoId) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .select('id')
          .eq('credito_original_id', creditoId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Actualizar estado de una renovación + registrar historial
  Future<void> actualizarEstado({
    required String renovacionId,
    required String estadoAnterior,
    required String estadoNuevo,
    String? usuarioId,
    String? observaciones,
  }) async {
    try {
      // 1. Actualizar estado
      await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .update({'estado': estadoNuevo})
          .eq('id', renovacionId);

      // 2. Registrar en historial
      await _supabase.client
          .schema('Financiamientos')
          .from('Historial_Renovaciones')
          .insert(HistorialRenovacion(
            renovacionId: renovacionId,
            estadoAnterior: estadoAnterior,
            estadoNuevo: estadoNuevo,
            usuarioId: usuarioId,
            observaciones: observaciones,
          ).toJson());
    } catch (e) {
      print('Error al actualizar estado de renovación: $e');
      rethrow;
    }
  }

  /// Obtener historial de cambios de una renovación
  Future<List<HistorialRenovacion>> getHistorialRenovacion(String renovacionId) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Historial_Renovaciones')
          .select()
          .eq('renovacion_id', renovacionId)
          .order('fecha_cambio', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => HistorialRenovacion.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al obtener historial: $e');
      return [];
    }
  }
}
