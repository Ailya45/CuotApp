import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/service/renovacion_service.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/Model/renovacion_model.dart';
import 'package:intl/intl.dart';

class FormularioRenovacionPage extends StatefulWidget {
  final String creditoId;
  final String nombreUsuario;

  const FormularioRenovacionPage({
    super.key,
    required this.creditoId,
    required this.nombreUsuario,
  });

  @override
  State<FormularioRenovacionPage> createState() =>
      _FormularioRenovacionPageState();
}

class _FormularioRenovacionPageState extends State<FormularioRenovacionPage> {
  final _formKey = GlobalKey<FormState>();
  final CreditService _creditService = CreditService();
  final RenovacionService _renovacionService = RenovacionService();

  // Datos del crédito original
  Map<String, dynamic>? _credito;
  bool _isLoading = true;
  bool _isSaving = false;

  // Campos del formulario
  // Campos del formulario
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _abonoController =
      TextEditingController(text: '0');
  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _moraManualController =
      TextEditingController(text: '0');
  bool _incluirMora = false;

  // Para Pago Único
  DateTime? _fechaLimiteNueva;

  // Fecha de renovación (global para cálculo de mora)
  DateTime? _fechaRenovacion;

  // Ganancia diaria original para cálculo de mora
  double _gananciaDiariaOriginal = 0;

  // Para Cuotas (Editables)
  List<Map<String, dynamic>> _cuotasEditables = [];

  // Datos calculados
  double _costoInversion = 0;
  double _saldoPendiente = 0;
  double _montoOriginal = 0;
  double _cuotaActual = 0;
  int _plazoOriginal = 0;
  int _plazoDiasOriginal = 0;
  double _moraCalculada = 0;
  String _modalidadOriginal = '';
  String _tipoCredito = ''; // 'unico' o 'cuotas'

  @override
  void initState() {
    super.initState();
    _loadCreditData();

    // Listeners para auto-ajuste de cuotas
    _abonoController.addListener(_onParametroCambiado);
    _moraManualController.addListener(_onParametroCambiado);
  }

  void _onParametroCambiado() {
    if (_tipoCredito == 'cuotas' && _cuotasEditables.isNotEmpty) {
      _repartirMontoEntreCuotas();
    } else {
      setState(() {});
    }
  }

  void _repartirMontoEntreCuotas() {
    if (_cuotasEditables.isEmpty) return;

    final double totalTotal = _montoTotalCalculado;

    // 1. Calcular cunto ya está "ocupado" por cuotas bloqueadas
    double montoBloqueado = 0;
    int numNoBloqueadas = 0;
    for (var c in _cuotasEditables) {
      if (c['bloqueada'] == true) {
        montoBloqueado += (double.tryParse(c['controller'].text) ?? 0);
      } else {
        numNoBloqueadas++;
      }
    }

    if (numNoBloqueadas == 0) return; // No hay donde repartir

    final double montoRestante = totalTotal - montoBloqueado;
    final double montoPorCuota =
        (montoRestante > 0 ? montoRestante : 0) / numNoBloqueadas;

    setState(() {
      for (var cuota in _cuotasEditables) {
        if (cuota['bloqueada'] != true) {
          cuota['controller'].text = montoPorCuota.toStringAsFixed(2);
        }
      }
    });
  }

  void _agregarCuota() {
    DateTime nuevaFecha;
    if (_cuotasEditables.isNotEmpty) {
      final ultimaFecha = _cuotasEditables.last['fecha'] as DateTime;
      nuevaFecha = ultimaFecha.add(_getModalityDuration(_modalidadOriginal));
    } else {
      nuevaFecha = DateTime.now().add(_getModalityDuration(_modalidadOriginal));
    }

    setState(() {
      _cuotasEditables.add({
        'id': null, // Nueva cuota no tiene ID de DB
        'monto': 0.0,
        'fecha': nuevaFecha,
        'controller': TextEditingController(text: '0.00'),
      });
      _repartirMontoEntreCuotas();
    });
  }

  void _quitarCuota() {
    if (_cuotasEditables.length > 1) {
      final last = _cuotasEditables.last;
      if (last['bloqueada'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No puedes eliminar una cuota que ya tiene abonos'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _cuotasEditables.removeLast();
        last['controller'].dispose();
        _repartirMontoEntreCuotas();
      });
    }
  }

  Duration _getModalityDuration(String modality) {
    switch (modality.toLowerCase()) {
      case 'diario':
        return const Duration(days: 1);
      case 'semanal':
        return const Duration(days: 7);
      case 'quincenal':
        return const Duration(days: 15);
      case 'mensual':
      default:
        return const Duration(days: 30);
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _abonoController.dispose();
    _observacionesController.dispose();
    _moraManualController.dispose();
    for (var c in _cuotasEditables) {
      c['controller'].dispose();
    }
    super.dispose();
  }

  Future<void> _loadCreditData() async {
    try {
      final data = await _creditService.getCreditById(widget.creditoId);
      if (data != null) {
        final double costoInversion =
            (data['costo_inversion'] as num).toDouble();
        final double margenGanancia =
            (data['margen_ganancia'] as num).toDouble();
        final double totalCredito = costoInversion + margenGanancia;

        final List<dynamic> rawPagos = data['Pagos'] ?? [];
        double totalPagado = 0;
        for (var pago in rawPagos) {
          totalPagado += (pago['monto'] as num).toDouble();
        }

        final List<dynamic> rawCuotas = data['Cuotas'] ?? [];
        // Calcular mora (cuotas vencidas no pagadas)
        double mora = 0;
        final hoy = DateTime.now();
        final List<Map<String, dynamic>> pendingCuotas = [];

        for (var cuota in rawCuotas) {
          if (cuota['pagada'] != true) {
            final numeroCuota = cuota['numero_cuota'];
            final bool tieneAbonos =
                rawPagos.any((p) => p['numero_cuota'] == numeroCuota);

            final fecha = DateTime.parse(cuota['fecha_pago']);
            if (fecha.isBefore(hoy)) {
              mora += (cuota['monto'] as num).toDouble() *
                  0.05; // 5% de mora estimado
            }
            pendingCuotas.add({
              'id': cuota['id'],
              'monto': (cuota['monto'] as num).toDouble(),
              'fecha': fecha,
              'bloqueada': tieneAbonos,
              'numero': numeroCuota,
              'controller': TextEditingController(
                  text: (cuota['monto'] as num).toStringAsFixed(2)),
            });
          }
        }

        setState(() {
          _credito = data;
          _costoInversion = costoInversion;
          _tipoCredito = data['tipo_credito'] ?? 'cuotas';
          _montoOriginal = totalCredito;
          _saldoPendiente = totalCredito - totalPagado;
          _plazoOriginal = data['numero_cuotas'] ?? 1;

          // Calcular días originales si es pago único
          if (_tipoCredito == 'unico' &&
              data['fecha_inicio'] != null &&
              data['fecha_limite'] != null) {
            final start = DateTime.parse(data['fecha_inicio']);
            final end = DateTime.parse(data['fecha_limite']);
            _plazoDiasOriginal = end.difference(start).inDays;
          } else {
            _plazoDiasOriginal = 30; // Default
          }

          _gananciaDiariaOriginal =
              _plazoDiasOriginal > 0 ? margenGanancia / _plazoDiasOriginal : 0;
          _fechaRenovacion =
              _fechaLimiteNueva ?? DateTime.now().add(const Duration(days: 1));

          _cuotaActual =
              _plazoOriginal > 0 ? totalCredito / _plazoOriginal : totalCredito;
          _moraCalculada = mora;
          _moraManualController.text = mora.toStringAsFixed(2);
          _modalidadOriginal = data['modalidad_pago']?.toString() ?? 'mensual';
          _cuotasEditables = pendingCuotas;

          if (_tipoCredito == 'unico') {
            final fechaLimiteStr =
                data['fecha_inicio'] ?? DateTime.now().toIso8601String();
            _fechaLimiteNueva =
                DateTime.parse(fechaLimiteStr).add(const Duration(days: 30));
            _fechaRenovacion = _fechaLimiteNueva;
          }

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error cargando crédito: $e');
      setState(() => _isLoading = false);
    }
  }

  double get _abono {
    return double.tryParse(_abonoController.text) ?? 0;
  }

  double get _montoMora {
    return double.tryParse(_moraManualController.text) ?? 0;
  }

  double get _montoCuotasEditadas {
    double total = 0;
    for (var cuota in _cuotasEditables) {
      total += double.tryParse(cuota['controller'].text) ?? 0;
    }
    return total;
  }

  double get _moraSugerida {
    if (_fechaRenovacion == null || _credito == null) {
      return _moraCalculada;
    }

    try {
      DateTime fechaOriginal;
      if (_tipoCredito == 'unico' && _credito?['fecha_limite'] != null) {
        fechaOriginal = DateTime.parse(
            _credito?['fecha_limite'] ?? DateTime.now().toIso8601String());
      } else if (_credito?['fecha_inicio'] != null) {
        fechaOriginal = DateTime.parse(
            _credito?['fecha_inicio'] ?? DateTime.now().toIso8601String());
      } else {
        fechaOriginal = DateTime.now();
      }

      final int diasRetraso =
          _fechaRenovacion!.difference(fechaOriginal).inDays;
      return diasRetraso > 0 ? diasRetraso * _gananciaDiariaOriginal : 0;
    } catch (e, stackTrace) {
      debugPrint('Error calculando mora sugerida: $e');
      debugPrint('$stackTrace');
      return 0;
    }
  }

  double get _montoTotalCalculado {
    double total = _saldoPendiente + (_incluirMora ? _montoMora : 0) - _abono;
    return total > 0 ? total : 0;
  }

  double get _nuevoMontoTotal {
    return _montoTotalCalculado;
  }

  double get _nuevaCuota {
    if (_tipoCredito == 'unico') return _nuevoMontoTotal;
    if (_cuotasEditables.isEmpty) return 0;
    // En cuotas, la "cuota" es variable, pero para el resumen mostramos el promedio
    // o simplemente quitamos este concepto si el usuario edita cada una.
    return _nuevoMontoTotal / _cuotasEditables.length;
  }

  double get _totalPagarActual {
    return _saldoPendiente;
  }

  double get _totalPagarNuevo {
    return _nuevoMontoTotal;
  }

  Future<void> _seleccionarFechaLimite() async {
    try {
      Locale pickerLocale;
      try {
        pickerLocale = Localizations.localeOf(context);
      } catch (_) {
        pickerLocale = const Locale('es', 'ES');
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _fechaLimiteNueva ?? DateTime.now(),
        firstDate: DateTime(2000), // 👈 CAMBIADO: Permitir fechas pasadas
        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        locale: pickerLocale,
      );
      if (picked != null) {
        setState(() {
          _fechaLimiteNueva = picked;
          _fechaRenovacion = picked;
        });
      }
    } catch (e) {
      debugPrint('Error en selector de fecha límite: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al seleccionar fecha. Intente de nuevo.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _seleccionarFechaCuota(int index) async {
    try {
      Locale pickerLocale;
      try {
        pickerLocale = Localizations.localeOf(context);
      } catch (_) {
        pickerLocale = const Locale('es', 'ES');
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _cuotasEditables[index]['fecha'],
        firstDate: DateTime(2000), // 👈 CAMBIADO: Permitir fechas pasadas
        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        locale: pickerLocale,
      );
      if (picked != null) {
        setState(() {
          _cuotasEditables[index]['fecha'] = picked;
        });
      }
    } catch (e, stack) {
      debugPrint('Error en selector de fecha cuota: $e');
      debugPrint('$stack');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al seleccionar fecha. Intente de nuevo.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _guardarRenovacion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar un motivo de renovación'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_tipoCredito == 'cuotas') {
      final double totalCuotas = _montoCuotasEditadas;
      final double totalEsperado = _montoTotalCalculado;

      if ((totalCuotas - totalEsperado).abs() > 0.01) {
        final diff = totalCuotas - totalEsperado;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'La suma no coincide: ${diff > 0 ? "Sobran" : "Faltan"} \$${diff.abs().toStringAsFixed(2)} del nuevo total (\$${totalEsperado.toStringAsFixed(2)})'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final cliente = _credito!['Clientes'];
      final clienteId = cliente['id'];

      final List<Map<String, dynamic>> cuotasParaGuardar =
          _cuotasEditables.map((c) {
        return {
          'id': c['id'],
          'monto': double.tryParse(c['controller'].text) ?? 0,
          'fecha': (c['fecha'] as DateTime).toIso8601String(),
        };
      }).toList();

      final renovacion = Renovacion(
        creditoOriginalId: widget.creditoId,
        clienteId: clienteId,
        motivo: _motivoController.text.trim(),
        condicionesAnteriores: {
          'plazo': _plazoOriginal,
          'plazo_dias': _plazoDiasOriginal,
          'cuota': _tipoCredito == 'unico' ? null : _cuotaActual,
          'saldo_pendiente': _saldoPendiente,
          'monto_total': _montoOriginal,
          'costo_inversion': _costoInversion,
          'modalidad': _modalidadOriginal,
          'tipo_credito': _tipoCredito,
        },
        condicionesNuevas: {
          'tipo_credito': _tipoCredito,
          'monto_total': _nuevoMontoTotal,
          'abono': _abono,
          'plazo': _tipoCredito == 'unico' ? 1 : _cuotasEditables.length,
          'incluye_mora': _incluirMora,
          'monto_mora': _incluirMora ? _montoMora : 0,
          'fecha_renovacion': DateTime.now().toIso8601String(),
          if (_tipoCredito == 'unico')
            'fecha_pago_nueva': _fechaLimiteNueva?.toIso8601String(),
          if (_tipoCredito == 'cuotas') 'cuotas_renovadas': cuotasParaGuardar,
        },
        nuevoPlazo: _tipoCredito == 'unico' ? 1 : _cuotasEditables.length,
        unidadPlazo: _tipoCredito == 'unico' ? 'pago_unico' : 'cuotas',
        nuevaTasaInteres: 0,
        nuevoMontoCuota: _nuevaCuota,
        montoAbono: _abono,
        incluirMora: _incluirMora,
        montoMora: _incluirMora ? _montoMora : 0,
        usuarioAutoriza: widget.nombreUsuario,
        estado: 'aprobada',
        observaciones: _observacionesController.text.trim(),
      );

      await _renovacionService.crearRenovacion(renovacion);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Renovación registrada exitosamente'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar renovación: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Renovación de Crédito'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_credito == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Renovación de Crédito'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Error al cargar el crédito')),
      );
    }

    final cliente = _credito!['Clientes'] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Renovación de Crédito'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === DATOS DEL CRÉDITO ORIGINAL (Solo lectura) ===
              _buildSectionTitle('📋 Crédito Original', AppColors.info),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildReadOnlyRow(
                          Icons.person, 'Cliente', cliente['nombre'] ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(Icons.inventory, 'Producto',
                          _credito!['concepto'] ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(Icons.attach_money, 'Monto Original',
                          '\$${_montoOriginal.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(Icons.warning_amber, 'Saldo Pendiente',
                          '\$${_saldoPendiente.toStringAsFixed(2)}',
                          color: AppColors.warning),
                      if (_tipoCredito != 'unico') ...[
                        const SizedBox(height: 8),
                        _buildReadOnlyRow(Icons.payments, 'Cuota Actual',
                            '\$${_cuotaActual.toStringAsFixed(2)}'),
                      ],
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(
                          Icons.calendar_today,
                          'Plazo Original',
                          _tipoCredito == 'unico'
                              ? 'Pago Único'
                              : '$_plazoOriginal cuotas'),
                      if (_moraCalculada > 0) ...[
                        const SizedBox(height: 8),
                        _buildReadOnlyRow(Icons.report_problem, 'Mora Sugerida',
                            '\$${_moraCalculada.toStringAsFixed(2)}',
                            color: AppColors.error),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // === CONDICIONES DE RENOVACIÓN ===
              _buildSectionTitle(
                  '⚙️ Nuevas Condiciones', AppColors.primaryGreen),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === SECCIÓN DINÁMICA SEGÚN TIPO ===
                      if (_tipoCredito == 'unico') ...[
                        const Text('Nueva Fecha de Pago Final',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _seleccionarFechaLimite,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month,
                                    color: AppColors.primaryGreen, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _fechaLimiteNueva != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_fechaLimiteNueva!)
                                      : 'Seleccionar fecha',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text('Editar Cuotas Pendientes',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cuotasEditables.length,
                          itemBuilder: (context, index) {
                            final cuota = _cuotasEditables[index];
                            final bool isLocked = cuota['bloqueada'] == true;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isLocked
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isLocked
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isLocked
                                        ? Colors.grey
                                        : AppColors.primaryGreen,
                                    child: isLocked
                                        ? const Icon(Icons.lock,
                                            color: Colors.white, size: 14)
                                        : Text(
                                            '${cuota['numero'] ?? (index + 1)}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: cuota['controller'],
                                      enabled: !isLocked,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                        prefixText: '\$ ',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        fillColor: isLocked
                                            ? Colors.grey.shade100
                                            : Colors.white,
                                        filled: true,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: InkWell(
                                      onTap: isLocked
                                          ? null
                                          : () => _seleccionarFechaCuota(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8),
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today,
                                                size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                                DateFormat('dd/MM/yy')
                                                    .format(cuota['fecha']),
                                                style: const TextStyle(
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _quitarCuota,
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 18),
                                label: const Text('Quitar Cuota',
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(
                                      color: AppColors.error.withOpacity(0.5)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _agregarCuota,
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 18),
                                label: const Text('Agregar Cuota',
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryGreen,
                                  side: BorderSide(
                                      color: AppColors.primaryGreen
                                          .withOpacity(0.5)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],



                      const SizedBox(height: 10),
                      Text(
                          'Mora sugerida: \$${_moraSugerida.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error)),

                      const SizedBox(height: 16),
                      const Text('Abono en la Renovación (\$)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _abonoController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          hintText: '0.00',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final abono = double.tryParse(value);
                            if (abono == null || abono < 0) {
                              return 'Monto inválido';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Checkbox Incluir Mora
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _incluirMora,
                              activeColor: AppColors.error,
                              onChanged: (val) {
                                setState(() {
                                  _incluirMora = val ?? false;
                                  if (_tipoCredito == 'cuotas')
                                    _repartirMontoEntreCuotas();
                                });
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '¿Desea incluir mora en esta renovación?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_moraCalculada > 0)
                                    Text(
                                      'Mora sugerida: \$${_moraCalculada.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_incluirMora) ...[
                        const SizedBox(height: 16),
                        // Monto de Mora (Editable)
                        const Text('Monto de Mora a Incluir (\$)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _moraManualController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            hintText: 'Ej: 5.00',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Motivo
                      const Text('Motivo de Renovación *',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _motivoController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          hintText:
                              'Ej: Cliente solicita ampliación de plazo...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el motivo';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Observaciones (opcional)
                      const Text('Observaciones (opcional)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _observacionesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          hintText: 'Notas adicionales...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // === TABLA COMPARATIVA ===
              _buildSectionTitle('📊 Comparativa', AppColors.darkGreen),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                    },
                    children: [
                      // Header
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        children: [
                          _buildTableCell('Concepto', isHeader: true),
                          _buildTableCell('Pendiente Actual', isHeader: true),
                          _buildTableCell('Nuevo Total', isHeader: true),
                        ],
                      ),
                      // Plazo
                      TableRow(
                        children: [
                          _buildTableCell('Plazo'),
                          _buildTableCell(_tipoCredito == 'unico'
                              ? '${_plazoOriginal > 1 ? _plazoOriginal : "30"} días' // Usualmente 30 si es inicial único
                              : '$_plazoOriginal cuotas'),
                          _buildTableCell(
                              _tipoCredito == 'unico'
                                  ? (_fechaLimiteNueva != null
                                      ? '${_fechaLimiteNueva!.difference(DateTime.parse(_credito?['fecha_inicio'] ?? DateTime.now().toIso8601String())).inDays} días'
                                      : 'N/A')
                                  : '${_cuotasEditables.length} cuotas',
                              color: AppColors.primaryGreen),
                        ],
                      ),
                      // Cuota
                      if (_tipoCredito != 'unico')
                        TableRow(
                          children: [
                            _buildTableCell('Cuota Prom.'),
                            _buildTableCell(
                                '\$${_cuotaActual.toStringAsFixed(2)}'),
                            _buildTableCell(
                                '\$${_nuevaCuota.toStringAsFixed(2)}',
                                color: AppColors.primaryGreen),
                          ],
                        ),
                      // Mora
                      if (_incluirMora && _montoMora > 0)
                        TableRow(
                          children: [
                            _buildTableCell('Mora'),
                            _buildTableCell('\$0.00'),
                            _buildTableCell(
                                '\$${_montoMora.toStringAsFixed(2)}',
                                color: AppColors.error),
                          ],
                        ),
                      // Total a Pagar
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                        ),
                        children: [
                          _buildTableCell('Total', isBold: true),
                          _buildTableCell(
                            '\$${_totalPagarActual.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                          _buildTableCell(
                            '\$${_totalPagarNuevo.toStringAsFixed(2)}',
                            isBold: true,
                            color: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                      // Diferencia de cuotas
                      if (_tipoCredito == 'cuotas' &&
                          (_montoCuotasEditadas - _montoTotalCalculado).abs() >
                              0.01)
                        TableRow(
                          children: [
                            _buildTableCell(
                                _montoCuotasEditadas > _montoTotalCalculado
                                    ? 'Sobran'
                                    : 'Faltan',
                                color: AppColors.error),
                            _buildTableCell(''),
                            _buildTableCell(
                              '\$${(_montoCuotasEditadas - _montoTotalCalculado).abs().toStringAsFixed(2)}',
                              color: AppColors.error,
                              isBold: true,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Resumen de cálculo
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                color: AppColors.veryLightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalcRow('Saldo Pendiente', _saldoPendiente),
                      if (_abono > 0)
                        _buildCalcRow('- Abono aplicado', -_abono,
                            color: AppColors.success),
                      if (_incluirMora && _montoMora > 0)
                        _buildCalcRow('+ Mora incluida', _montoMora,
                            color: AppColors.error),
                      const Divider(),
                      _buildCalcRow('NUEVO TOTAL CRÉDITO', _nuevoMontoTotal,
                          isBold: true, color: AppColors.primaryGreen),
                      if (_tipoCredito != 'unico')
                        _buildCalcRow(
                            'Cuota promedio (${_cuotasEditables.length} cuotas)',
                            _nuevaCuota,
                            isBold: true,
                            color: AppColors.darkGreen),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // === BOTONES ===
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.mediumGrey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _guardarRenovacion,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                          _isSaving ? 'Guardando...' : 'Guardar Renovación'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text,
      {bool isHeader = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 13 : 12,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isHeader ? AppColors.darkGreen : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, double value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
