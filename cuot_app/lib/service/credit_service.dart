import 'package:cuot_app/core/supabase/supabase_service.dart';

class CreditService {
  final SupabaseService _supabase = SupabaseService();

  // 🚀 CACHE: Evita consultas repetidas al navegar entre pantallas
  static List<Map<String, dynamic>>? _cachedData;
  static String? _cachedUser;
  static DateTime? _cacheTime;
  static const Duration _cacheTTL = Duration(seconds: 30);

  /// Invalida el caché (llamar después de guardar pagos o crear créditos)
  static void invalidateCache() {
    _cachedData = null;
    _cachedUser = null;
    _cacheTime = null;
  }

  bool get _isCacheValid {
    return _cachedData != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheTTL;
  }

  /// Obtener TODO en una sola consulta (con caché)
  /// [forceRefresh] = true para ignorar caché (pull-to-refresh)
  Future<List<Map<String, dynamic>>> getFullCreditsData(
    String usuarioNombre, {
    bool forceRefresh = false,
  }) async {
    // Retornar caché si es válido y del mismo usuario
    if (!forceRefresh &&
        _isCacheValid &&
        _cachedUser == usuarioNombre) {
      return _cachedData!;
    }

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
          .order('id', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);

      // Guardar en caché
      _cachedData = data;
      _cachedUser = usuarioNombre;
      _cacheTime = DateTime.now();

      return data;
    } catch (e) {
      print('Error en getFullCreditsData: $e');
      // Si hay caché viejo, retornarlo como fallback
      if (_cachedData != null && _cachedUser == usuarioNombre) {
        return _cachedData!;
      }
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

        // 4. Sincronizar estado del crédito si está totalmente pagado
        if (pagada) {
          final List<dynamic> allCuotas = await _supabase.client
              .schema('Financiamientos')
              .from('Cuotas')
              .select('pagada')
              .eq('credito_id', creditId);
          
          final bool todoPagado = allCuotas.every((c) => c['pagada'] == true);
          
          if (todoPagado) {
            await _supabase.client
                .schema('Financiamientos')
                .from('Creditos')
                .update({'estado': 'Pagado'})
                .eq('id', creditId);
          }
        }
      }

      // Invalidar caché para que la próxima carga traiga datos frescos
      invalidateCache();
    } catch (e) {
      print('Error al guardar pago: $e');
      rethrow;
    }
  }

  /// Obtiene un crédito por su ID con todos sus detalles (cliente, cuotas, pagos)
  Future<Map<String, dynamic>?> getCreditById(String id) async {
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
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      print('Error en getCreditById: $e');
      return null;
    }
  }

  /// Actualiza un crédito de pago único
  Future<void> updateCreditUnico(String creditId, Map<String, dynamic> data) async {
    try {
      // 1. Actualizar datos maestros
      await _supabase.client
          .schema('Financiamientos')
          .from('Creditos')
          .update({
            'concepto': data['concepto'],
            'costo_inversion': data['costo_inversion'],
            'margen_ganancia': data['margen_ganancia'],
            if (data.containsKey('cliente_id')) 'cliente_id': data['cliente_id'],
            if (data['fecha_vencimiento'] != null) 'fecha_vencimiento': data['fecha_vencimiento'],
          })
          .eq('id', creditId);

      // 2. Actualizar la cuota única (la 1) con el nuevo total restando lo pagado
      final pagos = await _supabase.client
          .schema('Financiamientos')
          .from('Pagos')
          .select('monto')
          .eq('credito_id', creditId);
          
      final double totalPagado = pagos.fold(0.0, (sum, pago) => sum + (pago['monto'] as num));
      final double nuevoTotal = ((data['costo_inversion'] as num) + (data['margen_ganancia'] as num)).toDouble();
      final double nuevoSaldo = nuevoTotal - totalPagado;

      await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .update({
            'monto': nuevoSaldo > 0 ? nuevoSaldo : 0,
            'pagada': nuevoSaldo <= 0,
            if (data['fecha_vencimiento'] != null) 'fecha_pago': data['fecha_vencimiento'],
          })
          .eq('credito_id', creditId)
          .eq('numero_cuota', 1);

      // 3. Sincronizar estado del crédito
      if (nuevoSaldo <= 0) {
        await _supabase.client
            .schema('Financiamientos')
            .from('Creditos')
            .update({'estado': 'Pagado'})
            .eq('id', creditId);
      }

      // 3. Sincronizar estado del crédito
      if (nuevoSaldo <= 0) {
        await _supabase.client
            .schema('Financiamientos')
            .from('Creditos')
            .update({'estado': 'Pagado'})
            .eq('id', creditId);
      }

      invalidateCache();
    } catch (e) {
      print('Error en updateCreditUnico: $e');
      rethrow;
    }
  }

  /// Actualiza un crédito en cuotas
  /// Se recrean las cuotas NO PAGADAS con la nueva distribución.
  Future<void> updateCreditCuotas(String creditId, Map<String, dynamic> data, List<Map<String, dynamic>> nuevasCuotasPendientes) async {
    try {
      // 1. Actualizar datos maestros
      await _supabase.client
          .schema('Financiamientos')
          .from('Creditos')
          .update({
            'concepto': data['concepto'],
            'costo_inversion': data['costo_inversion'],
            'margen_ganancia': data['margen_ganancia'],
            'numero_cuotas': data['numero_cuotas'],
            if (data.containsKey('cliente_id')) 'cliente_id': data['cliente_id'],
          })
          .eq('id', creditId);

      // 2. Eliminar cuotas que NO estén pagadas
      await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .delete()
          .eq('credito_id', creditId)
          .eq('pagada', false);

      // 3. Insertar las nuevas cuotas pendientes
      if (nuevasCuotasPendientes.isNotEmpty) {
        // Asegurarse de que el credit_id está en todas las cuotas
        final cuotasToInsert = nuevasCuotasPendientes.map((c) => {
          ...c,
          'credito_id': creditId,
        }).toList();
        
        await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas')
            .insert(cuotasToInsert);
      }

      // 4. Verificar si quedó totalmente pagado (por si acaso el monto fue 0)
      final todasCuotas = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .select('pagada')
          .eq('credito_id', creditId);
      
      final bool estaPagado = todasCuotas.isEmpty || todasCuotas.every((c) => c['pagada'] == true);
      if (estaPagado) {
        await _supabase.client
            .schema('Financiamientos')
            .from('Creditos')
            .update({'estado': 'Pagado'})
            .eq('id', creditId);
      }

      invalidateCache();
    } catch (e) {
      print('Error en updateCreditCuotas: $e');
      rethrow;
    }
  }

  /// 🛠️ MÉDICO DE DATOS: Repara duplicados y descuadres en las cuotas
  /// Busca cuotas con el mismo número para un crédito y elimina las redundantes.
  Future<void> repairDuplicateCuotas(String usuarioNombre) async {
    try {
      // 1. Obtener todos los créditos del usuario (datos frescos)
      final rawCredits = await getFullCreditsData(usuarioNombre, forceRefresh: true);
      
      bool huboCambios = false;

      for (var credit in rawCredits) {
        final creditId = credit['id'].toString();
        final List<dynamic> cuotas = List.from(credit['Cuotas'] ?? []);
        if (cuotas.isEmpty) continue;
        
        // Agrupar por numero_cuota
        final Map<int, List<dynamic>> grouped = {};
        for (var c in cuotas) {
          final n = c['numero_cuota'] as int;
          grouped.putIfAbsent(n, () => []).add(c);
        }
        
        // Identificar y limpiar duplicados
        for (var numeroCuota in grouped.keys) {
          final list = grouped[numeroCuota]!;
          if (list.length > 1) {
            print('--- REPARANDO: Crédito $creditId, Cuota $numeroCuota ---');
            
            // Decidir cuál conservar:
            // 1. La que esté pagada (prioridad absoluta)
            // 2. La que tenga mayor monto (si ninguna está pagada)
            // 3. Si una tiene monto 0 y es duplicada de una con monto, borrar la de 0
            list.sort((a, b) {
              if (a['pagada'] == true && b['pagada'] == false) return -1;
              if (a['pagada'] == false && b['pagada'] == true) return 1;
              // Si ambas son pagadas o ambas no, preferir mayor monto
              return (b['monto'] as num).compareTo(a['monto'] as num);
            });
            
            // Los ids de las cuotas a eliminar (todas menos la primera de la lista sorted)
            final idsToDelete = list.skip(1).map((c) => c['id']).toList();
            
            for (var cuotaId in idsToDelete) {
              await _supabase.client
                  .schema('Financiamientos')
                  .from('Cuotas')
                  .delete()
                  .eq('id', cuotaId);
              huboCambios = true;
            }
          }
        }

        // 2. Sincronizar el campo 'numero_cuotas' del crédito maestro
        // Si el usuario editó y quedaron cuotas huérfanas o duplicadas, 
        // el total de cuotas reales podría ser distinto al guardado.
        final response = await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas')
            .select('id')
            .eq('credito_id', creditId);
        
        final totalReal = response.length;
        if (totalReal != (credit['numero_cuotas'] as int)) {
          await _supabase.client
              .schema('Financiamientos')
              .from('Creditos')
              .update({'numero_cuotas': totalReal})
              .eq('id', creditId);
          huboCambios = true;
        }
      }

      if (huboCambios) {
        invalidateCache();
      }
    } catch (e) {
      print('Error en repairDuplicateCuotas: $e');
    }
  }

  /// Eliminar un crédito y todos sus datos asociados (pagos y cuotas)
  Future<void> deleteCredit(String creditId) async {
    try {
      // 0. Obtener cliente_id
      final creditoData = await _supabase.client
          .schema('Financiamientos')
          .from('Creditos')
          .select('cliente_id')
          .eq('id', creditId)
          .single();
      final String? clienteId = creditoData['cliente_id'];

      // 1. Eliminar pagos asociados
      await _supabase.client
          .schema('Financiamientos')
          .from('Pagos')
          .delete()
          .eq('credito_id', creditId);

      // 2. Eliminar cuotas asociadas
      await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .delete()
          .eq('credito_id', creditId);

      // 3. Eliminar el crédito
      await _supabase.client
          .schema('Financiamientos')
          .from('Creditos')
          .delete()
          .eq('id', creditId);

      // 4. Limpiar cliente huérfano si aplica
      if (clienteId != null) {
        final otherCredits = await _supabase.client
            .schema('Financiamientos')
            .from('Creditos')
            .select('id')
            .eq('cliente_id', clienteId);
            
        if (otherCredits.isEmpty) {
          await _supabase.client
              .schema('Financiamientos')
              .from('Clientes')
              .delete()
              .eq('id', clienteId);
        }
      }

      // Invalidar caché
      invalidateCache();
    } catch (e) {
      print('Error al eliminar crédito: $e');
      rethrow;
    }
  }
}