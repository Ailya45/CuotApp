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

      // 2. Si está aprobada, actualizar el crédito original
      if (renovacion.estado == 'aprobada') {
        await _aplicarRenovacionAlCredito(renovacion);
      }

      // 3. Registrar en historial
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

  /// Aplica los cambios de la renovación al crédito original
  Future<void> _aplicarRenovacionAlCredito(Renovacion renovacion) async {
    final condicionesNuevas = renovacion.condicionesNuevas;
    final tipoCredito = condicionesNuevas['tipo_credito'] ?? 'cuotas';
    final double nuevoMontoTotal = (condicionesNuevas['monto_total'] as num).toDouble();
    
    // 1. Actualizar el crédito principal
    // Para simplificar, ajustamos el margen_ganancia para que la suma cuadre con el nuevo total
    // Asumiendo que costo_inversion se mantiene (o podrías ajustarlo también)
    final double costoInversionOriginal = (renovacion.condicionesAnteriores['costo_inversion'] ?? 0).toDouble();
    final double nuevoMargen = nuevoMontoTotal - costoInversionOriginal;

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
            'monto': nuevoMontoTotal,
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
