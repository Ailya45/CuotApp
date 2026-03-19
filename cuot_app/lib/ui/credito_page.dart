import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cuot_app/Controller/credito_controller.dart';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/widget/creditos/formulario_cuotas.dart';
import 'package:cuot_app/widget/creditos/formulario_pagounico.dart';
import 'package:cuot_app/widget/creditos/tipo_credito_selector.dart';
import 'package:cuot_app/ui/pages/seguimiento_creditos_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreditoPage extends StatefulWidget {
  final String nombreUsuario;
  final String? creditoIdEditar;

  const CreditoPage({
    super.key,
    required this.nombreUsuario,
    this.creditoIdEditar,
  });

  @override
  State<CreditoPage> createState() => _CreditoPageState();
}

class _CreditoPageState extends State<CreditoPage> {
  final CreditoController _controller = CreditoController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.creditoIdEditar != null) {
      _cargarDatosEdicion();
    }
  }

  Future<void> _cargarDatosEdicion() async {
    setState(() => _isLoading = true);
    await _controller.cargarCreditoParaEdicion(widget.creditoIdEditar!);
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.creditoIdEditar != null ? 'Editar Financiamiento' : 'Gestión de Financiamientos'),
          centerTitle: true,
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Consumer<CreditoController>(
          builder: (context, controller, child) {
            // Si no hay tipo seleccionado, mostrar selector
            if (controller.tipoCreditoSeleccionado == null) {
              return TipoCreditoSelector(
                onTipoSeleccionado: controller.seleccionarTipoCredito,
              );
            }
            
            // Mostrar formulario según tipo
            return controller.tipoCreditoSeleccionado == TipoCredito.cuotas
                ? FormularioCuotas(
                    creditoInicial: controller.creditoEnProceso,
                    totalPagado: controller.totalPagado,
                    onCreditoActualizado: controller.actualizarCreditoParcial,
                    onGuardar: () => _guardarCredito(context, controller),
                  )
                : FormularioPagounico(
                    creditoInicial: controller.creditoEnProceso,
                    totalPagado: controller.totalPagado,
                    onCreditoActualizado: controller.actualizarCreditoParcial,
                    onGuardar: () => _guardarCredito(context, controller),
                  );
          },
        ),
      ),
    );
  }
  
  Future<void> _guardarCredito(
    BuildContext context,
    CreditoController controller,
  ) async {
    // Aquí se validaría y guardaría el crédito
    try {
      if (controller.creditoEnProceso != null) {
        final credito = controller.creditoEnProceso!;
        File? facturaFile;
        if (credito.facturaPath != null && !credito.facturaPath!.startsWith('http')) {
          facturaFile = File(credito.facturaPath!);
        }

        bool existe = await controller.clienteExisteYEsDiferenteAlActual(credito.nombreCliente, widget.nombreUsuario);
        if (existe) {
          bool? continuar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cliente ya registrado'),
              content: Text('Ya tienes un registro con el nombre "${credito.nombreCliente}".\n\n¿Deseas continuar y asignarle este crédito a ese cliente?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('MODIFICAR NOMBRE'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('SÍ, ASIGNAR'),
                ),
              ],
            ),
          );
          if (continuar != true) return;
        }

        await controller.guardarCredito(
          credito, 
          widget.nombreUsuario, 
          facturaArchivo: facturaFile,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Crédito guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a SeguimientoCreditosPage
      
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SeguimientoCreditosPage(nombreUsuario: widget.nombreUsuario),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Por favor, completa todos los campos primero'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}