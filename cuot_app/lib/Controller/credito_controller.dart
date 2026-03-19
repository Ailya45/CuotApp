import 'dart:io';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';
import 'package:cuot_app/utils/date_utils.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:flutter/material.dart';

class CreditoController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final CreditService _creditService = CreditService();
  
  TipoCredito? _tipoCreditoSeleccionado;
  Credito? _creditoEnProceso;
  final List<Credito> _creditos = [];

  // Modo edición
  String? _creditoIdEditar;
  bool get isEditing => _creditoIdEditar != null;
  double _totalPagado = 0.0;
  double get totalPagado => _totalPagado;

  // Getters
  TipoCredito? get tipoCreditoSeleccionado => _tipoCreditoSeleccionado;
  Credito? get creditoEnProceso => _creditoEnProceso;
  List<Credito> get creditos => List.unmodifiable(_creditos);
  
  // Métodos para manejar el flujo
  void seleccionarTipoCredito(TipoCredito tipo) {
    _tipoCreditoSeleccionado = tipo;
    _creditoEnProceso = null;
    notifyListeners();
  }
  
  void iniciarNuevoCredito() {
    _tipoCreditoSeleccionado = null;
    _creditoEnProceso = null;
    _creditoIdEditar = null;
    _totalPagado = 0.0;
    notifyListeners();
  }

  Future<void> cargarCreditoParaEdicion(String id) async {
    _creditoIdEditar = id;
    final data = await _creditService.getCreditById(id);
    if (data == null) return;

    final esUnico = data['tipo_credito'] == 'unico';
    _tipoCreditoSeleccionado = esUnico ? TipoCredito.unPago : TipoCredito.cuotas;

    // Calcular pagos
    final pagos = data['Pagos'] as List<dynamic>;
    _totalPagado = pagos.fold(0.0, (sum, p) => sum + (p['monto'] as num));

    // Extraer cliente
    final cliente = data['Clientes'] ?? {};
    final String nombreCliente = cliente['nombre'] ?? '';
    final String telefono = cliente['telefono'] ?? '';

    // Reconstruir cuotas
    List<CuotaPersonalizada> cuotasParsed = [];
    if (!esUnico) {
      final List<dynamic> cuotasData = data['Cuotas'] ?? [];
      cuotasData.sort((a, b) => (a['numero_cuota'] as int).compareTo(b['numero_cuota']));
      cuotasParsed = cuotasData.map((c) => CuotaPersonalizada(
        numeroCuota: c['numero_cuota'],
        fechaPago: DateTime.parse(c['fecha_pago']),
        monto: (c['monto'] as num).toDouble(),
        pagada: c['pagada'] ?? false,
      )).toList();
    }

    // Modalidad
    ModalidadPago modalidadPago = ModalidadPago.mensual; // fallback
    if (data['modalidad_pago'] != null) {
      modalidadPago = ModalidadPago.values[data['modalidad_pago']];
    }

    _creditoEnProceso = Credito(
      concepto: data['concepto'] ?? '',
      costeInversion: (data['costo_inversion'] as num).toDouble(),
      margenGanancia: (data['margen_ganancia'] as num).toDouble(),
      fechaInicio: DateTime.parse(data['fecha_inicio']),
      modalidadPago: modalidadPago,
      nombreCliente: nombreCliente,
      numeroCuotas: data['numero_cuotas'] ?? 1,
      telefono: telefono,
      fechasPersonalizadas: cuotasParsed,
      fechaLimite: data['fecha_vencimiento'] != null ? DateTime.parse(data['fecha_vencimiento']) : null,
      facturaPath: data['factura_url'],
    );

    notifyListeners();
  }
  
  Future<void> guardarCredito(Credito credito, String usuarioNombre, {File? facturaArchivo}) async {
    try {
      // 1. Subir factura si existe
      String? facturaUrl;
      if (facturaArchivo != null) {
        facturaUrl = await _supabaseService.uploadFile(
          folder: 'facturas',
          fileName: 'factura_${DateTime.now().millisecondsSinceEpoch}.jpg',
          file: facturaArchivo,
        );
      }

      // 2. Buscar o crear cliente
      final clientes = await _supabaseService.client
          .schema('Financiamientos')
          .from('Clientes')
          .select()
          .eq('nombre', credito.nombreCliente)
          .eq('usuario_creador', usuarioNombre);
      
      String clienteId;
      if (clientes.isNotEmpty) {
        clienteId = clientes[0]['id'];
        // Opcional: actualizar teléfono si cambió
        if (credito.telefono != null && credito.telefono!.isNotEmpty) {
          await _supabaseService.client
              .schema('Financiamientos')
              .from('Clientes')
              .update({'telefono': credito.telefono})
              .eq('id', clienteId);
        }
      } else {
        final nuevoCliente = await _supabaseService.insert('Clientes', {
          'nombre': credito.nombreCliente,
          'telefono': credito.telefono,
          'usuario_creador': usuarioNombre,
        });
        clienteId = nuevoCliente['id'];
      }

      // 3. Determinar tipo de crédito
      final bool esPagoUnico = _tipoCreditoSeleccionado == TipoCredito.unPago;

      // MODIFICACIÓN PARA EDICIÓN
      if (isEditing) {
        final updateData = {
          'concepto': credito.concepto,
          'costo_inversion': credito.costeInversion,
          'margen_ganancia': credito.margenGanancia,
          'numero_cuotas': credito.numeroCuotas,
          'cliente_id': clienteId,
          if (esPagoUnico && credito.fechaLimite != null)
            'fecha_vencimiento': credito.fechaLimite!.toIso8601String(),
        };

        if (esPagoUnico) {
          await _creditService.updateCreditUnico(_creditoIdEditar!, updateData);
        } else {
          // Extraer las cuotas pendientes que se actualizarán
          // Si el usuario generó nuevas fechas, estarán en `credito.fechasPersonalizadas`
          List<Map<String, dynamic>> nuevasCuotasPendientes = [];
          
          if (credito.fechasPersonalizadas != null) {
            
            // Filtrar cuotas que el usuario editó o dejó (asumiremos que todo `fechasPersonalizadas` 
            // que nos llegue del form que NO esté pagado, representa la nueva distribución).
            // Pero en `FormularioCuotas` debemos asegurarnos de marcar "pagada" en las históricas.
            // Para simplificar, insertaremos solo las cuotas no pagadas
            for (var cuota in credito.fechasPersonalizadas!) {
              if (!cuota.pagada) {
                nuevasCuotasPendientes.add({
                  'numero_cuota': cuota.numeroCuota,
                  'fecha_pago': cuota.fechaPago.toIso8601String(),
                  'monto': cuota.monto,
                  'pagada': false,
                });
              }
            }
          }
          await _creditService.updateCreditCuotas(_creditoIdEditar!, updateData, nuevasCuotasPendientes);
        }

      } else {
        // [CÓDIGO ORIGINAL PARA INSERTAR UN NUEVO CRÉDITO...]
        final dataCredito = {
        'cliente_id': clienteId,
        'concepto': credito.concepto,
        'costo_inversion': credito.costeInversion,
        'margen_ganancia': credito.margenGanancia,
        'fecha_inicio': credito.fechaInicio.toIso8601String(),
        'modalidad_pago': credito.modalidadPago.index,
        'numero_cuotas': credito.numeroCuotas,
        'tipo_credito': esPagoUnico ? 'unico' : 'cuotas',
        'factura_url': facturaUrl,
        'usuario_nombre': usuarioNombre,
        'estado': 'Pendiente',
        if (esPagoUnico && credito.fechaLimite != null)
          'fecha_vencimiento': credito.fechaLimite!.toIso8601String(),
      };

      final creditoInsertado = await _supabaseService.insert('Creditos', dataCredito);
      final String creditId = creditoInsertado['id'];

      // 5. Insertar cuotas
      if (esPagoUnico) {
        // Para pago único: 1 cuota con el monto total y la fecha límite
        await _supabaseService.client
            .schema('Financiamientos')
            .from('Cuotas')
            .insert({
              'credito_id': creditId,
              'numero_cuota': 1,
              'fecha_pago': (credito.fechaLimite ?? credito.fechaInicio).toIso8601String(),
              'monto': credito.precioTotal,
              'pagada': false,
            });
      } else {
        // [NUEVO] Generar cuotas para crédito en cuotas
        final List<Map<String, dynamic>> cuotasData = [];
        
        if (credito.fechasPersonalizadas != null && credito.fechasPersonalizadas!.isNotEmpty) {
          // Usar fechas configuradas manualmente
          for (int i = 0; i < credito.fechasPersonalizadas!.length; i++) {
            final cuota = credito.fechasPersonalizadas![i];
            cuotasData.add({
              'credito_id': creditId,
              'numero_cuota': i + 1,
              'fecha_pago': cuota.fechaPago.toIso8601String(),
              'monto': cuota.monto,
              'pagada': false,
            });
          }
        } else {
          // Generar automáticamente según la modalidad
          List<DateTime> fechas;
          switch (credito.modalidadPago) {
            case ModalidadPago.diario:
              fechas = DateUt.sugerirFechasDiarias(credito.fechaInicio, credito.numeroCuotas);
              break;
            case ModalidadPago.semanal:
              fechas = DateUt.sugerirFechasSemanales(credito.fechaInicio, credito.numeroCuotas);
              break;
            case ModalidadPago.quincenal:
              fechas = DateUt.sugerirFechasQuincenales(credito.fechaInicio, credito.numeroCuotas);
              break;
            case ModalidadPago.mensual:
              fechas = DateUt.sugerirFechasMensuales(credito.fechaInicio, credito.numeroCuotas);
              break;
            default:
              fechas = [];
          }
          
          for (int i = 0; i < fechas.length; i++) {
            cuotasData.add({
              'credito_id': creditId,
              'numero_cuota': i + 1,
              'fecha_pago': fechas[i].toIso8601String(),
              'monto': credito.valorPorCuota,
              'pagada': false,
            });
          }
        }
        
        if (cuotasData.isNotEmpty) {
          await _supabaseService.client
              .schema('Financiamientos')
              .from('Cuotas')
              .insert(cuotasData);
        }
      }
      } // Fin de if(isEditing) else {...}

      // Limpiar estado local
      _creditoEnProceso = null;
      _tipoCreditoSeleccionado = null;
      _creditoIdEditar = null;
      _totalPagado = 0.0;
      notifyListeners();
    } catch (e) {
      print('❌ Error al guardar crédito en Supabase: $e');
      rethrow;
    }
  }
  
  void actualizarCreditoParcial(Credito credito) {
    _creditoEnProceso = credito;
    notifyListeners();
  }
  
  // Validaciones de negocio
  Future<bool> clienteExisteYEsDiferenteAlActual(String nombreCliente, String usuarioNombre) async {
    // Si estamos editando y el nombre no ha cambiado, no avisar
    if (isEditing && _creditoEnProceso != null && _creditoEnProceso!.nombreCliente.trim().toLowerCase() == nombreCliente.trim().toLowerCase()) {
      return false;
    }

    final clientes = await _supabaseService.client
        .schema('Financiamientos')
        .from('Clientes')
        .select('id')
        .eq('nombre', nombreCliente.trim())
        .eq('usuario_creador', usuarioNombre);
        
    return clientes.isNotEmpty;
  }

  bool validarCredito(Credito credito) {
    if (credito.concepto.isEmpty) return false;
    if (credito.costeInversion <= 0) return false;
    if (credito.margenGanancia < 0) return false;
    if (credito.nombreCliente.isEmpty) return false;
    
    if (_tipoCreditoSeleccionado == TipoCredito.cuotas) {
      if (credito.numeroCuotas < 1) return false;
    }
    
    return true;
  }
}