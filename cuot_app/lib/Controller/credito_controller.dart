import 'dart:io';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';
import 'package:cuot_app/utils/date_utils.dart';
import 'package:flutter/material.dart';

class CreditoController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  TipoCredito? _tipoCreditoSeleccionado;
  Credito? _creditoEnProceso;
  final List<Credito> _creditos = [];

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

      // 4. Insertar Crédito maestro
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

      // Limpiar estado local
      _creditoEnProceso = null;
      _tipoCreditoSeleccionado = null;
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