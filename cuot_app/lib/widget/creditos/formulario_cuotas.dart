// lib/widget/creditos/formulario_cuotas.dart
import 'dart:io';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';

import 'package:cuot_app/widget/creditos/custom_date_picker.dart';
import 'package:cuot_app/widget/creditos/factura_uploader.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:cuot_app/utils/validators.dart';
import 'package:cuot_app/widget/creditos/selector_fechas_cuotas_compacto.dart';
import 'package:cuot_app/utils/date_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 👈 NUEVO

class FormularioCuotas extends StatefulWidget {
  final Credito? creditoInicial;
  final double totalPagado;
  final Function(Credito) onCreditoActualizado;
  final Function() onGuardar;

  const FormularioCuotas({
    super.key,
    this.creditoInicial,
    this.totalPagado = 0.0,
    required this.onCreditoActualizado,
    required this.onGuardar,
  });

  @override
  State<FormularioCuotas> createState() => _FormularioCuotasState();
}

class _FormularioCuotasState extends State<FormularioCuotas> {
  // 📌 LLAVE DEL FORMULARIO
  final _formKey = GlobalKey<FormState>();

  // 📌 CONTROLADORES
  final _conceptoController = TextEditingController();
  final _inversionController = TextEditingController();
  final _gananciaController = TextEditingController();
  final _cuotasController = TextEditingController();
  final _clienteController = TextEditingController();
  final _telefonoController = TextEditingController();

  // 📌 VARIABLES DE ESTADO
  DateTime _fechaInicio = DateTime.now();
  ModalidadPago _modalidadSeleccionada = ModalidadPago.mensual;
  File? _facturaSeleccionada;

  // 📌 VARIABLES PARA MODO PERSONALIZADO
  List<CuotaPersonalizada>? _fechasPersonalizadas;
  bool _mostrarSelectorPersonalizado = false;
  bool _configuracionCompletada = false;
  bool _mostrarTelefono = false; // 👈 NUEVO: Estado del checkbox

  // 📌 Fecha límite calculada
  DateTime? _fechaLimiteCalculada;

  // 📌 PROPIEDADES CALCULADAS
  double get _inversion => double.tryParse(_inversionController.text) ?? 0;
  double get _ganancia => double.tryParse(_gananciaController.text) ?? 0;
  double get _precioTotal => _inversion + _ganancia;
  int get _numCuotas => int.tryParse(_cuotasController.text) ?? 0;
  double get _numCuotasPagadas =>
      _fechasPersonalizadas?.where((c) => c.pagada).length.toDouble() ?? 0;
  double get _montoPendienteReal => _precioTotal - widget.totalPagado;

  double get _valorCuotaSugerido {
    final pendientes = _numCuotas - _numCuotasPagadas.toInt();
    return pendientes > 0 ? _montoPendienteReal / pendientes : 0;
  }

  @override
  void initState() {
    super.initState();
    _inicializarDatosEdit();
    _calcularFechaLimite();
  }

  void _inicializarDatosEdit() {
    if (widget.creditoInicial != null) {
      final credito = widget.creditoInicial!;
      _conceptoController.text = credito.concepto;
      _inversionController.text = credito.costeInversion.toString();
      _gananciaController.text = credito.margenGanancia.toString();
      _cuotasController.text = credito.numeroCuotas.toString();
      _clienteController.text = credito.nombreCliente;

      if (credito.telefono != null && credito.telefono!.isNotEmpty) {
        _mostrarTelefono = true;
        _telefonoController.text = credito.telefono!;
      }

      _fechaInicio = credito.fechaInicio;
      _modalidadSeleccionada = credito.modalidadPago;

      if (credito.fechasPersonalizadas != null &&
          credito.fechasPersonalizadas!.isNotEmpty) {
        _fechasPersonalizadas = credito.fechasPersonalizadas;
        _configuracionCompletada = true;
        _mostrarSelectorPersonalizado = true;
      }
    }
  }

  // 📌 Calcular fecha límite
  void _calcularFechaLimite() {
    if (_fechasPersonalizadas != null && _fechasPersonalizadas!.isNotEmpty) {
      _fechaLimiteCalculada = _fechasPersonalizadas!.last.fechaPago;
    } else if (_numCuotas > 0) {
      switch (_modalidadSeleccionada) {
        case ModalidadPago.diario:
          _fechaLimiteCalculada = _fechaInicio.add(Duration(days: _numCuotas));
          break;
        case ModalidadPago.semanal:
          _fechaLimiteCalculada =
              _fechaInicio.add(Duration(days: _numCuotas * 7));
          break;
        case ModalidadPago.quincenal:
          _fechaLimiteCalculada =
              _fechaInicio.add(Duration(days: _numCuotas * 15));
          break;
        case ModalidadPago.mensual:
          _fechaLimiteCalculada = DateTime(
            _fechaInicio.year,
            _fechaInicio.month + _numCuotas,
            _fechaInicio.day,
          );
          break;
        case ModalidadPago.personalizado:
          _fechaLimiteCalculada = null;
          break;
      }
    } else {
      _fechaLimiteCalculada = null;
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📌 1. CONCEPTO/PRODUCTO
            _buildSeccionTitulo('Concepto', Icons.shopping_bag),
            const SizedBox(height: 8),
            TextFormField(
              controller: _conceptoController,
              decoration: _buildInputDecoration(
                label: 'Ej: Laptop, Celular, Préstamo...',
                icon: Icons.description,
              ),
              validator: (v) => Validators.required(v, 'Concepto'),
              onChanged: _actualizarCredito,
            ),
            const SizedBox(height: 20),

            // 📌 2. INVERSIÓN
            _buildSeccionTitulo('Inversión/Coste', Icons.attach_money),
            const SizedBox(height: 8),
            TextFormField(
              controller: _inversionController,
              decoration: _buildInputDecoration(
                label: 'Monto invertido',
                icon: Icons.money,
                prefix: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => Validators.positiveNumber(v, 'Inversión'),
              onChanged: _actualizarCredito,
            ),
            const SizedBox(height: 20),

            // 📌 3. FILA: GANANCIA Y CUOTAS
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ganancia
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSeccionTitulo('Ganancia', Icons.trending_up),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _gananciaController,
                        decoration: _buildInputDecoration(
                          label: 'Ganancia',
                          icon: Icons.add_chart,
                          prefix: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.positiveNumber(
                            v, 'Ganancia',
                            allowZero: true),
                        onChanged: (value) {
                          setState(() {});
                          _actualizarCredito();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Cuotas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSeccionTitulo(
                        'No. Cuotas',
                        Icons.format_list_numbered,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cuotasController,
                        decoration: _buildInputDecoration(
                          label: 'Cantidad',
                          icon: Icons.numbers,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            Validators.positiveNumber(v, 'Cuotas'),
                        onChanged: (value) {
                          setState(() {});
                          _actualizarCredito();
                          _ajustarPlanPorCambioMetadata();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📌 4. FECHAS
            _buildSeccionTitulo('Fecha de pago', Icons.date_range),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha de inicio
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.play_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Text('Fecha de inicio:'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CustomDatePicker(
                          selectedDate: _fechaInicio,
                          onDateSelected: (date) {
                            setState(() {
                              _fechaInicio = date;
                            });
                            _actualizarCredito();
                          },
                          label: 'Fecha de inicio',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Fecha límite (solo informativa)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stop_circle,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            const Text('Fecha límite:'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CustomDatePicker(
                          selectedDate: _fechaLimiteCalculada,
                          label: 'FECHA LÍMITE',
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📌 5. MODALIDAD DE COBRO
            _buildSeccionTitulo('Modalidad de cobro', Icons.payment),
            const SizedBox(height: 8),
            DropdownButtonFormField<ModalidadPago>(
              value: _modalidadSeleccionada,
              decoration: _buildInputDecoration(label: 'Seleccionar'),
              items: ModalidadPago.values.map((modalidad) {
                return DropdownMenuItem(
                  value: modalidad,
                  child: Row(
                    children: [
                      Icon(
                        _getModalidadIcon(modalidad),
                        size: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(_getModalidadText(modalidad)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (modalidad) {
                setState(() {
                  _modalidadSeleccionada = modalidad!;
                  _ajustarPlanPorCambioMetadata();
                });
                _actualizarCredito();
              },
            ),
            const SizedBox(height: 16),

            // 📌 6. CONFIGURACIÓN PERSONALIZADA (solo si aplica)
            if (_modalidadSeleccionada == ModalidadPago.personalizado) ...[
              const SizedBox(height: 8),
              _buildPersonalizadoSection(),
              const SizedBox(height: 16),
            ],

            // 📌 7. RESUMEN DE VALORES
            _buildResumenCard(),
            const SizedBox(height: 20),
            _buildSeccionTitulo('Cliente', Icons.person),
            const SizedBox(height: 8),
            TextFormField(
              controller: _clienteController,
              decoration: _buildInputDecoration(
                label: 'Nombre completo del cliente',
                icon: Icons.person_outline,
              ),
              validator: (v) => Validators.required(v, 'Cliente'),
              onChanged: _actualizarCredito,
            ),
            const SizedBox(height: 20),

            // 📌 7.5 TELEFONO OPCIONAL
            CheckboxListTile(
              title: const Text('Agregar número de teléfono'),
              value: _mostrarTelefono,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (val) {
                setState(() => _mostrarTelefono = val ?? false);
                _actualizarCredito();
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            if (_mostrarTelefono) ...[
              _buildSeccionTitulo('Teléfono', Icons.phone),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telefonoController,
                decoration: _buildInputDecoration(
                  label: 'Número de WhatsApp',
                  icon: Icons.phone_android,
                  prefix: '+',
                  suffixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                ),
                keyboardType: TextInputType.phone,
                onChanged: _actualizarCredito,
              ),
            ],
            const SizedBox(height: 20),

            // 📌 8. FACTURA (OPCIONAL)
            _buildSeccionTitulo('Factura (Opcional)', Icons.receipt),
            const SizedBox(height: 8),
            FacturaUploader(
              onFacturaSeleccionada: (File? archivo) {
                setState(() {
                  _facturaSeleccionada = archivo;
                });
                _actualizarCredito();
              },
            ),

            // 📌 9. CLIENTE

            // 📌 10. INDICADOR DE FACTURA (si hay)
            if (_facturaSeleccionada != null) _buildFacturaIndicator(),
            const SizedBox(height: 24),

            // 📌 11. BOTÓN GUARDAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _guardarCredito,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text(
                      'GUARDAR CRÉDITO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📌 SECCIÓN DE CONFIGURACIÓN PERSONALIZADA
  Widget _buildPersonalizadoSection() {
    if (_numCuotas <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Primero ingresa el número de cuotas',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      );
    }

    if (!_mostrarSelectorPersonalizado) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _iniciarConfiguracionPersonalizada,
          icon: const Icon(Icons.add_circle),
          label: const Text('CONFIGURAR FECHAS DE CUOTAS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SelectorFechasCuotasCompacto(
          numeroCuotas: _numCuotas,
          fechaInicio: _fechaInicio,
          montoPorCuota: _valorCuotaSugerido,
          precioTotalEsperado: _precioTotal,
          saldoPendienteEsperado: _montoPendienteReal,
          initialCuotas: _fechasPersonalizadas,
          onFechasSeleccionadas: (fechas) {
            setState(() {
              _fechasPersonalizadas = fechas;
              _configuracionCompletada = true;
              _calcularFechaLimite();
            });
            _actualizarCredito();
          },
        ),
        if (_configuracionCompletada) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Configuración completada (${_fechasPersonalizadas?.length ?? 0} cuotas configuradas)',
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _ajustarPlanPorCambioMetadata() {
    if (_fechasPersonalizadas == null || _fechasPersonalizadas!.isEmpty) {
      if (_modalidadSeleccionada == ModalidadPago.personalizado) {
        setState(() {
          _mostrarSelectorPersonalizado = false;
          _configuracionCompletada = false;
        });
      }
      return;
    }

    // 1. Identificar cuotas preservadas (pagadas o bloqueadas)
    final preservadas =
        _fechasPersonalizadas!.where((c) => c.pagada || c.bloqueada).toList();
    final numPreservadas = preservadas.length;

    if (numPreservadas == 0) {
      // Si no hay preservadas, podemos resetear para que se regenere
      setState(() {
        _fechasPersonalizadas = null;
        _configuracionCompletada = false;
        if (_modalidadSeleccionada != ModalidadPago.personalizado) {
          _mostrarSelectorPersonalizado = false;
        }
      });
      return;
    }

    // SI HAY CUOTAS PRESERVADAS: Debemos mantenerlas y ajustar el resto
    setState(() {
      // 2. Si el número de cuotas es menor al de preservadas, avisar y corregir
      if (_numCuotas < numPreservadas) {
        _cuotasController.text = numPreservadas.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No puedes reducir las cuotas a menos de $numPreservadas (tienen pagos o están bloqueadas)'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // 3. Actualizar lista y re-generar el resto si no es modo personalizado
      final List<CuotaPersonalizada> listaActualizada = _obtenerCuotasPreservadasAjustadas(preservadas);
      final numPreservadasAjustadas = listaActualizada.length;

      if (_modalidadSeleccionada != ModalidadPago.personalizado) {
        // Al añadir cuotas automáticamente, usamos el saldo pendiente sugerido
        final numRestantes = _numCuotas - numPreservadasAjustadas;

        if (numRestantes > 0) {
          final montoPorCuota = _valorCuotaSugerido;
          final ultimaFecha = preservadas.last.fechaPago;

          for (int i = 0; i < numRestantes; i++) {
            DateTime nuevaFecha;
            switch (_modalidadSeleccionada) {
              case ModalidadPago.diario:
                nuevaFecha = ultimaFecha.add(Duration(days: i + 1));
                break;
              case ModalidadPago.semanal:
                nuevaFecha = ultimaFecha.add(Duration(days: (i + 1) * 7));
                break;
              case ModalidadPago.quincenal:
                nuevaFecha = ultimaFecha.add(Duration(days: (i + 1) * 15));
                break;
              case ModalidadPago.mensual:
                nuevaFecha = DateTime(ultimaFecha.year,
                    ultimaFecha.month + (i + 1), ultimaFecha.day);
                break;
              default:
                nuevaFecha = ultimaFecha.add(Duration(days: (i + 1) * 30));
            }
            listaActualizada.add(CuotaPersonalizada(
              numeroCuota: listaActualizada.length + 1,
              fechaPago: nuevaFecha,
              monto: montoPorCuota,
            ));
          }
          _configuracionCompletada = true;
        } else {
          _configuracionCompletada = true;
        }
      } else {
        _configuracionCompletada = false;
      }

      _fechasPersonalizadas = listaActualizada;
      _mostrarSelectorPersonalizado = true;
    });
  }

  /// 📌 INICIAR CONFIGURACIÓN PERSONALIZADA
  void _iniciarConfiguracionPersonalizada() {
    if (_precioTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero completa los montos de inversión y ganancia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      // 1. Identificar cuotas ya PAGADAS/BLOQUEADAS para preservarlas y AJUSTARLAS al total pagado
      final List<CuotaPersonalizada> preservadasOriginales =
          _fechasPersonalizadas?.where((c) => c.pagada || c.bloqueada).toList() ?? [];
      final List<CuotaPersonalizada> preservadas = _obtenerCuotasPreservadasAjustadas(preservadasOriginales);

      // 2. Generar sugerencias de fechas para todas las cuotas
      List<DateTime> sugerencias;
      switch (_modalidadSeleccionada) {
        case ModalidadPago.diario:
          sugerencias = DateUt.sugerirFechasDiarias(_fechaInicio, _numCuotas);
          break;
        case ModalidadPago.semanal:
          sugerencias = DateUt.sugerirFechasSemanales(_fechaInicio, _numCuotas);
          break;
        case ModalidadPago.quincenal:
          sugerencias =
              DateUt.sugerirFechasQuincenales(_fechaInicio, _numCuotas);
          break;
        case ModalidadPago.mensual:
          sugerencias = DateUt.sugerirFechasMensuales(_fechaInicio, _numCuotas);
          break;
        default:
          sugerencias = DateUt.sugerirFechasMensuales(_fechaInicio, _numCuotas);
      }

      // 3. Re-construir la lista de cuotas
      // El monto sugerido se calcula sobre el saldo pendiente real
      final double montoParaRestantes = _valorCuotaSugerido;

      _fechasPersonalizadas = List.generate(_numCuotas, (index) {
        final numero = index + 1;

        // Buscar si hay una cuota preservada ajustada para este número
        final cuotaPreservada = preservadas.cast<CuotaPersonalizada?>().firstWhere(
          (c) => c?.numeroCuota == numero, 
          orElse: () => null
        );
        
        if (cuotaPreservada != null) {
          return cuotaPreservada; // Preservar monto ajustado y estado histórico
        }

        // Si es una cuota nueva o pendiente, le asignamos el saldo sugerido
        return CuotaPersonalizada(
          numeroCuota: numero,
          fechaPago: sugerencias[index],
          monto: montoParaRestantes,
        );
      });
      _mostrarSelectorPersonalizado = true;
    });
  }

  /// 📌 TARJETA DE RESUMEN (MODIFICADA con validación de total)
  Widget _buildResumenCard() {
    // 👇 NUEVO: Calcular total de cuotas y validar
    final totalCuotas =
        CuotaPersonalizada.calcularTotalCuotas(_fechasPersonalizadas);
    final diferencia = totalCuotas - _precioTotal;
    final totalValido = (diferencia).abs() <= 0.01;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              'Precio total:',
              '\$${_precioTotal.toStringAsFixed(2)}',
              color: Colors.blue.shade900,
            ),
            _buildInfoRow(
              'Duración:',
              DateUt.formatearDuracion(
                  _fechaInicio, _fechaLimiteCalculada ?? _fechaInicio),
            ),
            const Divider(),
            if (widget.totalPagado > 0) ...[
              _buildInfoRow(
                'Pagado actualmente:',
                '\$${widget.totalPagado.toStringAsFixed(2)}',
                color: Colors.green,
                icon: Icons.check_circle_outline,
              ),
              _buildInfoRow(
                'Saldo pendiente total:',
                '\$${_montoPendienteReal.toStringAsFixed(2)}',
                color: Colors.orange.shade900,
                icon: Icons.pending_actions,
              ),
              const Divider(),
            ],
            _buildInfoRow(
              'Valor cuotas pendientes:',
              '\$${_valorCuotaSugerido.toStringAsFixed(2)}',
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
            if (_fechasPersonalizadas != null) ...[
              const Divider(),
              _buildInfoRow(
                'Resumen Plan:',
                '${_fechasPersonalizadas!.length} cuotas '
                    '(${_numCuotasPagadas.toInt()} pagadas)',
              ),
              _buildInfoRow(
                'Total configurado:',
                '\$${totalCuotas.toStringAsFixed(2)}',
                color: totalValido ? Colors.green : Colors.red,
              ),
              // 👇 NUEVO: Alerta si hay diferencia
              if (!totalValido)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning,
                            color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${diferencia > 0 ? "Sobran" : "Faltan"}: \$${diferencia.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// 📌 INDICADOR DE FACTURA ADJUNTA
  Widget _buildFacturaIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Factura adjunta:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _facturaSeleccionada!.path.split('/').last,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              setState(() {
                _facturaSeleccionada = null;
              });
              _actualizarCredito();
            },
          ),
        ],
      ),
    );
  }

  /// 📌 ACTUALIZAR CRÉDITO (callback)
  void _actualizarCredito([dynamic _]) {
    _calcularFechaLimite();

    if (_formKey.currentState?.validate() ?? false) {
      final credito = Credito(
        concepto: _conceptoController.text,
        costeInversion: _inversion,
        margenGanancia: _ganancia,
        fechaInicio: _fechaInicio,
        modalidadPago: _modalidadSeleccionada,
        nombreCliente: _clienteController.text,
        telefono: _mostrarTelefono ? _telefonoController.text : '',
        numeroCuotas: _numCuotas,
        facturaPath: _facturaSeleccionada?.path,
        nombreFactura: _facturaSeleccionada?.path.split('/').last,
        fechasPersonalizadas: _fechasPersonalizadas,
      );
      widget.onCreditoActualizado(credito);
    }
  }

  /// 📌 GUARDAR CRÉDITO (con validaciones MEJORADAS)
  void _guardarCredito() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // 👇 NUEVA VALIDACIÓN: El precio total no puede ser menor a lo ya pagado
    if (_precioTotal < widget.totalPagado) {
      _mostrarError(
        'Monto inválido',
        'El precio total (${_precioTotal.toStringAsFixed(2)}) no puede ser menor al monto ya pagado (${widget.totalPagado.toStringAsFixed(2)}).',
      );
      return;
    }

    if (_modalidadSeleccionada == ModalidadPago.personalizado) {
      if (_fechasPersonalizadas == null || _fechasPersonalizadas!.isEmpty) {
        _mostrarError(
          'Configuración incompleta',
          'Debes configurar las fechas de las cuotas en modo personalizado',
        );
        return;
      }

      // 👇 NUEVA VALIDACIÓN: Verificar que el total de cuotas coincida con el precio total
      final totalCuotas =
          CuotaPersonalizada.calcularTotalCuotas(_fechasPersonalizadas);
      final diferencia = (totalCuotas - _precioTotal).abs();

      if (diferencia > 0.01) {
        _mostrarError(
          'Total de cuotas incorrecto',
          'La suma de todas las cuotas (\$${totalCuotas.toStringAsFixed(2)}) '
              'no coincide con el precio total (\$${_precioTotal.toStringAsFixed(2)}).\n\n'
              'Diferencia: \$${diferencia.toStringAsFixed(2)}',
        );
        return;
      }

      if (!_validarFechasPersonalizadas()) {
        _mostrarError(
          'Fechas inválidas',
          'Las fechas deben estar en orden cronológico y ser futuras',
        );
        return;
      }
    }

    if (_facturaSeleccionada == null &&
        widget.creditoInicial?.facturaPath == null) {
      _mostrarDialogoFacturaOpcional();
    } else {
      widget.onGuardar();
    }
  }

  /// 📌 VALIDAR FECHAS PERSONALIZADAS
  bool _validarFechasPersonalizadas() {
    if (_fechasPersonalizadas == null || _fechasPersonalizadas!.isEmpty) {
      return false;
    }

    final fechas = _fechasPersonalizadas!.map((c) => c.fechaPago).toList();

    for (int i = 0; i < fechas.length - 1; i++) {
      if (fechas[i].isAfter(fechas[i + 1])) {
        return false;
      }
    }

    final inicioSinHora =
        DateTime(_fechaInicio.year, _fechaInicio.month, _fechaInicio.day);

    for (var fecha in fechas) {
      final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
      if (fechaSinHora.isBefore(inicioSinHora)) {
        return false;
      }
    }

    return true;
  }

  /// 📌 MOSTRAR ERROR
  void _mostrarError(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }

  /// 📌 DIÁLOGO PARA FACTURA OPCIONAL
  void _mostrarDialogoFacturaOpcional() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Adjuntar factura?'),
        content: const Text(
          'No has adjuntado ninguna factura. ¿Deseas continuar sin factura?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ADJUNTAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              _actualizarCredito(); // 👈 Asegura guardar estado
              widget.onGuardar(); // Guarda y navega
            },
            child: const Text('CONTINUAR'),
          ),
        ],
      ),
    );
  }

  /// 📌 MÉTODOS DE UTILIDAD
  
  /// Ajusta las cuotas ya pagadas para que su suma coincida con widget.totalPagado
  List<CuotaPersonalizada> _obtenerCuotasPreservadasAjustadas(List<CuotaPersonalizada> originales) {
    if (originales.isEmpty) return [];
    
    // Si el total pagado es 0, nos aseguramos de que nada esté marcado como pagado
    if (widget.totalPagado <= 0) {
      return originales.map((c) => c.copyWith(pagada: false, bloqueada: false)).toList();
    }

    final List<CuotaPersonalizada> resultado = List.from(originales);
    final sumaActual = CuotaPersonalizada.calcularTotalCuotas(resultado);
    final diferencia = widget.totalPagado - sumaActual;

    // Si hay diferencia significativa (> 0.01), ajustamos la última preservada
    if (diferencia.abs() > 0.01) {
      final ultimaIndex = resultado.length - 1;
      final cuotaAjustada = resultado[ultimaIndex].copyWith(
        monto: resultado[ultimaIndex].monto + diferencia,
      );
      resultado[ultimaIndex] = cuotaAjustada;
    }

    return resultado;
  }

  Widget _buildSeccionTitulo(String titulo, IconData icono) {
    return Row(
      children: [
        Icon(icono, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    IconData? icon,
    String? prefix,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      suffixIcon: suffixIcon, // 👈 USAR
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? color,
    IconData? icon,
    FontWeight? fontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16,
                    color: color?.withOpacity(0.7) ?? Colors.grey.shade600),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: fontWeight ?? FontWeight.bold,
              color: color ?? Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  String _getModalidadText(ModalidadPago modalidad) {
    switch (modalidad) {
      case ModalidadPago.diario:
        return 'Diario';
      case ModalidadPago.semanal:
        return 'Semanal';
      case ModalidadPago.quincenal:
        return 'Quincenal';
      case ModalidadPago.mensual:
        return 'Mensual';
      case ModalidadPago.personalizado:
        return 'Personalizado';
    }
  }

  IconData _getModalidadIcon(ModalidadPago modalidad) {
    switch (modalidad) {
      case ModalidadPago.diario:
        return Icons.today;
      case ModalidadPago.semanal:
        return Icons.calendar_view_week;
      case ModalidadPago.quincenal:
        return Icons.calendar_view_month;
      case ModalidadPago.mensual:
        return Icons.calendar_month;
      case ModalidadPago.personalizado:
        return Icons.edit_calendar;
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _inversionController.dispose();
    _gananciaController.dispose();
    _cuotasController.dispose();
    _clienteController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
}
