import 'package:flutter/material.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/service/renovacion_service.dart';
import 'package:cuot_app/Model/renovacion_model.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/ui/pages/formulario_renovacion_page.dart';
import 'package:intl/intl.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class DetalleCreditoPage extends StatefulWidget {
  final String creditoId;
  final String? nombreUsuario;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  const DetalleCreditoPage({
    super.key,
    required this.creditoId,
    this.nombreUsuario,
    this.onEditar,
    this.onEliminar,
  });

  @override
  State<DetalleCreditoPage> createState() => _DetalleCreditoPageState();
}

class _DetalleCreditoPageState extends State<DetalleCreditoPage> {
  final CreditService _creditService = CreditService();
  final RenovacionService _renovacionService = RenovacionService();
  Map<String, dynamic>? _credito;
  List<Renovacion> _historialRenovaciones = [];
  bool _isLoading = true;
  bool _isHistorialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  Future<void> _loadDetalle() async {
    setState(() => _isLoading = true);
    try {
      final data = await _creditService.getCreditById(widget.creditoId);
      setState(() {
        _credito = data;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error cargando detalle del crédito: $e');
      debugPrint('$stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el detalle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    await _loadHistorialRenovaciones();
  }

  Future<void> _loadHistorialRenovaciones() async {
    setState(() => _isHistorialLoading = true);
    try {
      final renovaciones =
          await _renovacionService.getRenovacionesPorCredito(widget.creditoId);
      setState(() {
        _historialRenovaciones = renovaciones;
        _isHistorialLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error cargando historial de renovaciones: $e');
      debugPrint('$stackTrace');
      setState(() => _isHistorialLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar historial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Crédito'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_credito == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Crédito'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Error al cargar la información')),
      );
    }

    final cliente = _credito!['Clientes'] ?? {};
    final List<dynamic> rawPagos = _credito!['Pagos'] ?? [];
    final List<dynamic> rawCuotas = _credito!['Cuotas'] ?? [];

    double costoInversion = (_credito!['costo_inversion'] as num).toDouble();
    double margenGanancia = (_credito!['margen_ganancia'] as num).toDouble();
    double totalCredito = costoInversion + margenGanancia;

    double totalPagado = 0;
    for (var pago in rawPagos) {
      totalPagado += (pago['monto'] as num).toDouble();
    }
    double saldoPendiente = totalCredito - totalPagado;
    final bool isPagado = saldoPendiente <= 0.01;

    // Sort pagos by date
    rawPagos.sort((a, b) => DateTime.parse(b['fecha_pago_real'])
        .compareTo(DateTime.parse(a['fecha_pago_real'])));

    rawCuotas.sort((a, b) =>
        (a['numero_cuota'] as int).compareTo(b['numero_cuota'] as int));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Detalle de Crédito',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (widget.onEditar != null && !isPagado)
            IconButton(
              icon: const Icon(
                Icons.edit_note_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onEditar!();
              },
              tooltip: 'Editar Crédito',
            ),
          if (widget.nombreUsuario != null && !isPagado)
            IconButton(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormularioRenovacionPage(
                        creditoId: widget.creditoId,
                        nombreUsuario: widget.nombreUsuario!,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadDetalle();
                    }
                  });
                } catch (e, stackTrace) {
                  debugPrint('Error al navegar a renovación: $e');
                  debugPrint('$stackTrace');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al abrir renovación: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              tooltip: 'Renovar Crédito',
            ),
          if (widget.onEliminar != null)
            IconButton(
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
                size: 26,
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onEliminar!();
              },
              tooltip: 'Eliminar Crédito',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._buildInfoSeccion(),
              const SizedBox(height: 16),
              ..._buildDetallesSeccion(),
              const SizedBox(height: 16),
              ..._buildHistorialUnificadoSeccion(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInfoSeccion() {
    final cliente = _credito!['Clientes'] ?? {};
    final bool isPagado = (_credito?['costo_inversion'] as num? ?? 0) +
            (_credito?['margen_ganancia'] as num? ?? 0) -
            ((_credito?['Pagos'] as List<dynamic>?)?.fold(
                    0.0,
                    (sum, pago) =>
                        (sum as double) + (pago['monto'] as num).toDouble()) ??
                0.0) <=
        0.01;

    bool isAtrasado = false;
    final List<dynamic> cuotas = _credito?['Cuotas'] ?? [];
    if (!isPagado) {
      for (var cuota in cuotas) {
        if (cuota['pagada'] == false && cuota['fecha_pago'] != null) {
          final fechaPago = DateTime.tryParse(cuota['fecha_pago'].toString());
          if (fechaPago != null) {
            final hoy = DateTime.now();
            final fechaPagoDate =
                DateTime(fechaPago.year, fechaPago.month, fechaPago.day);
            final hoyDate = DateTime(hoy.year, hoy.month, hoy.day);
            if (fechaPagoDate.isBefore(hoyDate)) {
              isAtrasado = true;
              break;
            }
          }
        }
      }
      if (cuotas.isEmpty && _credito?['fecha_vencimiento'] != null) {
        final fechaVen =
            DateTime.tryParse(_credito!['fecha_vencimiento'].toString());
        if (fechaVen != null) {
          final hoy = DateTime.now();
          final fechaVenDate =
              DateTime(fechaVen.year, fechaVen.month, fechaVen.day);
          final hoyDate = DateTime(hoy.year, hoy.month, hoy.day);
          if (fechaVenDate.isBefore(hoyDate)) {
            isAtrasado = true;
          }
        }
      }
    }

    final String textoEstado =
        isPagado ? 'PAGADO' : (isAtrasado ? 'ATRASADO' : 'AL DÍA');
    final Color colorEstado = isPagado
        ? AppColors.success
        : (isAtrasado ? AppColors.error : Colors.blue.shade700);

    return [
      Card(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppColors.primaryGreen.withOpacity(0.1),
                    child: const Icon(Icons.person,
                        color: AppColors.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cliente['nombre'] ?? 'N/A',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(cliente['telefono'] ?? 'Sin teléfono',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorEstado.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      textoEstado,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorEstado,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Información',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.credit_score, 'Concepto',
                  _credito?['concepto'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.calendar_today,
                  'Fecha de inicio',
                  _credito?['fecha_inicio'] != null
                      ? _formatFecha(_credito!['fecha_inicio'])
                      : 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.calendar_month, 'Fecha límite', (() {
                if (_credito?['fecha_vencimiento'] != null) {
                  return _formatFecha(_credito!['fecha_vencimiento']);
                }
                final cuotas = _credito?['Cuotas'] as List<dynamic>? ?? [];
                if (cuotas.isNotEmpty) {
                  return _formatFecha(cuotas.last['fecha_pago']);
                }
                return 'N/A';
              })()),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.monetization_on, 'Monto total',
                  '\$${(((_credito?['costo_inversion'] as num?)?.toDouble() ?? 0) + ((_credito?['margen_ganancia'] as num?)?.toDouble() ?? 0)).toStringAsFixed(2)}',
                  isBold: true),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.payments, 'Saldo pendiente',
                  '\$${((_credito?['costo_inversion'] as num? ?? 0).toDouble() + (_credito?['margen_ganancia'] as num? ?? 0).toDouble() - ((_credito?['Pagos'] as List<dynamic>?)?.fold(0.0, (sum, pago) => (sum as double) + (pago['monto'] as num).toDouble()) ?? 0.0)).toStringAsFixed(2)}',
                  color: AppColors.error, isBold: true),
              const SizedBox(height: 20),
              // Botón de Renovación Azul solicitado por el usuario
              if (widget.nombreUsuario != null && !isPagado)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormularioRenovacionPage(
                            creditoId: widget.creditoId,
                            nombreUsuario: widget.nombreUsuario!,
                          ),
                        ),
                      ).then((result) {
                        if (result == true) {
                          _loadDetalle();
                        }
                      });
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Renovación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildDetallesSeccion() {
    final List<dynamic> rawCuotas = _credito?['Cuotas'] ?? [];
    final String tipoCredito = _credito?['tipo_credito'] ?? 'cuotas';
    final bool esUnico = tipoCredito == 'unico';

    return [
      Text(esUnico ? 'Monto a Pagar' : 'Cuotas',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (rawCuotas.isEmpty)
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
                child: Text('No hay registros vinculados.',
                    style: TextStyle(color: Colors.grey))),
          ),
        ),
      if (!esUnico && rawCuotas.isNotEmpty)
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text('Ver Lista de Cuotas (${rawCuotas.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: rawCuotas.length <= 5,
            children: [
              for (var cuota in rawCuotas)
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: cuota['pagada'] == true
                          ? AppColors.success.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cuota['pagada'] == true
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      child: Icon(
                        cuota['pagada'] == true
                            ? Icons.check_circle
                            : Icons.schedule,
                        color: cuota['pagada'] == true
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    title: Text(
                      'Cuota ${cuota['numero_cuota'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle:
                        Text('Vence: ${_formatFecha(cuota['fecha_pago'])}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${(cuota['monto'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          cuota['pagada'] == true ? 'Pagada' : 'Pendiente',
                          style: TextStyle(
                            fontSize: 12,
                            color: cuota['pagada'] == true
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        )
      else if (esUnico && rawCuotas.isNotEmpty)
        for (var cuota in rawCuotas)
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: cuota['pagada'] == true
                    ? AppColors.success.withOpacity(0.5)
                    : Colors.transparent,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cuota['pagada'] == true
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                child: Icon(
                  cuota['pagada'] == true
                      ? Icons.check_circle
                      : Icons.schedule,
                  color: cuota['pagada'] == true
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
              title: const Text('Total a Pagar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Vence: ${_formatFecha(cuota['fecha_pago'])}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${(cuota['monto'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    cuota['pagada'] == true ? 'Pagada' : 'Pendiente',
                    style: TextStyle(
                      fontSize: 12,
                      color: cuota['pagada'] == true
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
    ];
  }

  List<Widget> _buildHistorialUnificadoSeccion() {
    final List<dynamic> rawPagos = _credito?['Pagos'] ?? [];
    final String tipoCredito = _credito?['tipo_credito'] ?? 'cuotas';
    final bool esUnico = tipoCredito == 'unico';

    final List<Map<String, dynamic>> historialData = [];
    
    for (var pago in rawPagos) {
      historialData.add({
        'type': 'pago',
        'date': DateTime.parse(pago['fecha_pago_real']),
        'data': pago,
      });
    }
    
    for (var ren in _historialRenovaciones) {
      historialData.add({
        'type': 'renovacion',
        'date': ren.fechaRenovacion,
        'data': ren,
      });
    }
    
    historialData.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    final List<Widget> items = [
      const Text('Historial General',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
    ];

    if (_isHistorialLoading) {
      items.add(const Center(child: CircularProgressIndicator()));
      return items;
    }

    if (historialData.isEmpty) {
      items.add(
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
                child: Text('No hay actividad registrada aún.',
                    style: TextStyle(color: Colors.grey))),
          ),
        ),
      );
      return items;
    }

    for (var item in historialData) {
      if (item['type'] == 'pago') {
        final pago = item['data'];
        items.add(
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.primaryGreen.withOpacity(0.1),
                            radius: 16,
                            child: const Icon(Icons.attach_money,
                                size: 18, color: AppColors.primaryGreen),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            esUnico ? 'Abono Realizado' : 'Pago de Cuota',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Text(
                        '\$${(pago['monto'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildDetalleRow(
                      'Fecha', _formatFechaHora(pago['fecha_pago_real'])),
                  if (pago['metodo_pago'] != null)
                    _buildDetalleRow('Forma de Pago',
                        pago['metodo_pago'].toString().capitalize()),
                  if (pago['referencia'] != null &&
                      pago['referencia'].toString().isNotEmpty)
                    _buildDetalleRow(
                        'Referencia', pago['referencia'].toString()),
                  if (pago['observaciones'] != null &&
                      pago['observaciones'].toString().isNotEmpty)
                    _buildDetalleRow(
                        'Descripción', pago['observaciones'].toString()),
                ],
              ),
            ),
          ),
        );
      } else if (item['type'] == 'renovacion') {
        final renovacion = item['data'];
        final estado = renovacion.estado ?? 'solicitada';
        final colorEstado = _getColorEstado(estado);

        items.add(
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colorEstado.withOpacity(0.5), width: 1),
            ),
            child: InkWell(
              onTap: () => _mostrarDetalleRenovacion(renovacion),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Estado
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorEstado.withOpacity(0.1),
                          radius: 18,
                          child: Icon(
                            _getIconEstado(estado),
                            color: colorEstado,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Renovación de Crédito',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (renovacion.observaciones != null &&
                                  renovacion.observaciones!.isNotEmpty)
                                Text(
                                  renovacion.observaciones!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorEstado.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            estado.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorEstado,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    // Info comparativa
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniInfo(
                            'Plazo',
                            _getResumenPlazoLocal(renovacion.fechaRenovacion,
                                renovacion.condicionesNuevas),
                            Icons.schedule,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniInfo(
                            'Mora',
                            '\$${(renovacion.condicionesNuevas['monto_mora'] as num?)?.toStringAsFixed(0) ?? '0'}',
                            Icons.warning_amber_rounded,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniInfo(
                            'Total',
                            '\$${(renovacion.condicionesNuevas['monto_total'] as num?)?.toStringAsFixed(0) ?? '0'}',
                            Icons.payments,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniInfo(
                            'Fecha',
                            DateFormat('dd/MM/yy')
                                .format(renovacion.fechaRenovacion),
                            Icons.event,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return items;
  }

  // Helper para formatear montos de forma segura
  String _formatMonto(dynamic value) {
    if (value == null) return 'N/A';
    final num? n = value is num ? value : num.tryParse(value.toString());
    return n != null ? '\$${n.toStringAsFixed(2)}' : '\$$value';
  }

  int _calcularDiasSimple(dynamic start, dynamic end) {
    if (start == null || end == null) return 0;
    try {
      final s = DateTime.parse(start.toString());
      final e = DateTime.parse(end.toString());
      return e.difference(s).inDays;
    } catch (e) {
      return 0;
    }
  }

  String _getResumenPlazoLocal(
      DateTime fechaRen, Map<String, dynamic> condNuevas) {
    final tipo = condNuevas['tipo_credito'] ?? 'cuotas';
    if (tipo == 'unico') {
      final fechaNueva = condNuevas['fecha_pago_nueva'];
      return '${_calcularDiasSimple(fechaRen.toIso8601String(), fechaNueva)} días';
    } else {
      final cuotas = condNuevas['cuotas_renovadas'];
      if (cuotas is List && cuotas.isNotEmpty) {
        final last = cuotas.last;
        final e = DateTime.tryParse(last['fecha'].toString());
        if (e != null) {
          return '${e.difference(fechaRen).inDays} días';
        }
      }
      return '? días';
    }
  }

  Widget _buildMiniInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Helper para formatear fechas ISO a dd/MM/yyyy
  String _formatFecha(String? fechaStr) {
    if (fechaStr == null) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaStr));
    } catch (_) {
      return fechaStr;
    }
  }

  // Helper para formatear fechas ISO a dd/MM/yyyy HH:mm
  String _formatFechaHora(String? fechaStr) {
    if (fechaStr == null) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy, HH:mm')
          .format(DateTime.parse(fechaStr).toLocal());
    } catch (_) {
      return fechaStr;
    }
  }

  List<Widget> _formatCondiciones(Map<String, dynamic> condiciones,
      {required bool isAnterior}) {
    List<Widget> widgets = [];
    final tipoCredito = condiciones['tipo_credito'] ?? 'cuotas';

    // Orden definido para mostrar los campos
    final orderedKeys = [
      'tipo_credito',
      'plazo',
      'plazo_dias',
      'modalidad',
      'cuota',
      'saldo_pendiente',
      'monto_total',
      'costo_inversion',
      'abono',
      'incluye_mora',
      'monto_mora',
      'fecha_pago_nueva',
      'cuotas_renovadas',
      'fecha_renovacion',
    ];

    try {
      final seenKeys = <String>{};

      for (final key in orderedKeys) {
        if (!condiciones.containsKey(key)) continue;
        if (seenKeys.contains(key)) continue;

        final value = condiciones[key];
        String label = '';
        String displayValue = '';

        switch (key) {
          case 'plazo':
            if (tipoCredito == 'unico') {
              // Para pago único en condiciones anteriores, mostrar plazo_dias
              if (isAnterior) {
                seenKeys.add('plazo_dias');
                final dias = condiciones['plazo_dias'] ?? value;
                label = 'Plazo Anterior';
                displayValue = '$dias días';
              } else {
                // Para condiciones nuevas de pago único, calcular a partir de fechas
                label = 'Plazo Nuevo';
                displayValue = _calcularDiasPlazo(condiciones);
              }
            } else {
              label = isAnterior ? 'Plazo Anterior' : 'Plazo Nuevo';
              displayValue = '$value cuotas';
            }
            break;
          case 'plazo_dias':
            // Solo mostrar si no fue ya procesado por 'plazo'
            if (!seenKeys.contains('plazo_dias') && tipoCredito == 'unico') {
              label = isAnterior ? 'Plazo Anterior' : 'Plazo Nuevo';
              displayValue = '$value días';
            }
            break;
          case 'cuota':
            if (tipoCredito != 'unico') {
              label = 'Cuota';
              displayValue = _formatMonto(value);
            }
            break;
          case 'saldo_pendiente':
            label = 'Saldo en la fecha';
            displayValue = _formatMonto(value);
            break;
          case 'monto_total':
            label = 'Monto Total';
            displayValue = _formatMonto(value);
            break;
          case 'costo_inversion':
            label = 'Costo de Inversión';
            displayValue = _formatMonto(value);
            break;
          case 'modalidad':
            label = 'Modalidad';
            displayValue = value.toString().capitalize();
            break;
          case 'tipo_credito':
            label = 'Tipo de Crédito';
            displayValue = value == 'unico' ? 'Pago Único' : 'Cuotas';
            break;
          case 'abono':
            final abonoNum =
                value is num ? value : num.tryParse(value.toString());
            if (abonoNum != null && abonoNum > 0) {
              label = 'Abono';
              displayValue = _formatMonto(value);
            }
            break;
          case 'incluye_mora':
            if (value == true) {
              label = 'Mora Incluida';
              displayValue = 'Sí';
            }
            break;
          case 'monto_mora':
            final moraNum =
                value is num ? value : num.tryParse(value.toString());
            if (moraNum != null && moraNum > 0) {
              label = 'Monto de Mora';
              displayValue = _formatMonto(value);
            }
            break;
          case 'fecha_pago_nueva':
            if (value != null) {
              label = 'Nueva Fecha de Pago';
              try {
                displayValue = DateFormat('dd/MM/yyyy')
                    .format(DateTime.parse(value.toString()));
              } catch (_) {
                displayValue = value.toString();
              }
            }
            break;
          case 'cuotas_renovadas':
            if (value != null && value is List && value.isNotEmpty) {
              label = 'Cuotas Renovadas';
              displayValue =
                  '${value.length} cuota${value.length != 1 ? 's' : ''}';
            }
            break;
          default:
            break;
        }

        if (label.isNotEmpty) {
          seenKeys.add(key);
          widgets.add(_buildCondRow(label, displayValue));
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error formateando condiciones: $e');
      debugPrint('$stackTrace');
      widgets.add(const Text('Error al mostrar condiciones'));
    }

    return widgets;
  }

  String _calcularDiasPlazo(Map<String, dynamic> condiciones) {
    // Para condiciones nuevas en único, calcular días si hay fecha_pago_nueva
    if (condiciones['fecha_pago_nueva'] != null && _credito != null) {
      try {
        final fechaInicio = DateTime.parse(_credito!['fecha_inicio']);
        final fechaNueva = DateTime.parse(condiciones['fecha_pago_nueva']);
        final dias = fechaNueva.difference(fechaInicio).inDays;
        return '$dias días';
      } catch (_) {
        return 'N/A';
      }
    }
    return 'N/A';
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCuotasMini(List<dynamic> cuotas,
      {required bool isAnterior}) {
    if (cuotas.isEmpty) return const SizedBox.shrink();

    List<dynamic> parsedCuotas = List.from(cuotas);
    parsedCuotas.sort((a, b) {
      int idxA = a['numero_cuota'] ?? a['numero'] ?? 0;
      int idxB = b['numero_cuota'] ?? b['numero'] ?? 0;
      return idxA.compareTo(idxB);
    });

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isAnterior ? 'Cuotas Anteriores:' : 'Nuevas Cuotas:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800)),
          const SizedBox(height: 4),
          ...parsedCuotas.map((c) {
            final n = c['numero_cuota'] ?? c['numero'] ?? '?';
            final m = c['monto'] ?? 0;
            final f = c['fecha_pago'] ?? c['fecha'];
            final fStr = f != null ? _formatFecha(f.toString()) : 'N/A';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cuota $n', style: const TextStyle(fontSize: 12)),
                  Text(fStr,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('\$${(m as num).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCondRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobada':
        return AppColors.success;
      case 'rechazada':
        return AppColors.error;
      case 'cancelada':
        return AppColors.mediumGrey;
      case 'solicitada':
        return AppColors.warning;
      default:
        return AppColors.mediumGrey;
    }
  }

  IconData _getIconEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobada':
        return Icons.check_circle;
      case 'rechazada':
        return Icons.cancel;
      case 'cancelada':
        return Icons.block;
      case 'solicitada':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  void _mostrarDetalleRenovacion(Renovacion renovacion) {
    final condAnteriores = renovacion.condicionesAnteriores;
    final condNuevas = renovacion.condicionesNuevas;
    final tipoCredito = condNuevas['tipo_credito'] ??
        condAnteriores['tipo_credito'] ??
        'cuotas';
    final labelTipo = tipoCredito == 'unico' ? 'Pago Único' : 'Cuota Fija';
    final colorEstado = _getColorEstado(renovacion.estado ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Título + estado badge
                    Row(
                      children: [
                        Icon(
                          _getIconEstado(renovacion.estado ?? ''),
                          color: colorEstado,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Detalle de Renovación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorEstado.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (renovacion.estado ?? 'N/A').toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorEstado,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Tipo de cuota
                    Text(
                      'Tipo de Cuota: $labelTipo',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Info general
                    _buildDetalleRow(
                      'Motivo',
                      renovacion.motivo ?? 'Sin motivo',
                    ),
                    _buildDetalleRow(
                      'Fecha',
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(renovacion.fechaRenovacion),
                    ),

                    const SizedBox(height: 16),

                    // Condiciones Anteriores
                    Text(
                      tipoCredito == 'unico'
                          ? 'Condiciones Anteriores (Pago Único)'
                          : 'Condiciones Anteriores',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            if (condAnteriores['fecha_inicio'] != null)
                              _buildCondRow(
                                  'Fecha Inicio',
                                  _formatFecha(condAnteriores['fecha_inicio']
                                      .toString())),
                            if (condAnteriores['fecha_vencimiento'] != null)
                              _buildCondRow(
                                  'Fecha Límite Org.',
                                  _formatFecha(
                                      condAnteriores['fecha_vencimiento']
                                          .toString())),
                            if (tipoCredito == 'unico') ...[
                              _buildCondRow(
                                'Plazo Anterior',
                                _formatPlazoDias(condAnteriores['plazo_dias'] ??
                                    condAnteriores['plazo']),
                              ),
                            ] else ...[
                              _buildCondRow(
                                'Plazo Anterior',
                                '${condAnteriores['plazo'] ?? 'N/A'} cuotas',
                              ),
                              _buildCondRow(
                                'Cuota',
                                _formatMonto(condAnteriores['cuota']),
                              ),
                            ],
                            _buildCondRow(
                              'Saldo en la fecha',
                              _formatMonto(condAnteriores['saldo_pendiente']),
                            ),
                            if (tipoCredito == 'cuotas' &&
                                condAnteriores['cuotas_anteriores'] is List &&
                                (condAnteriores['cuotas_anteriores'] as List)
                                    .isNotEmpty)
                              _buildListaCuotasMini(
                                  condAnteriores['cuotas_anteriores'] as List,
                                  isAnterior: true),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Condiciones Nuevas
                    const Text(
                      'Condiciones Nuevas',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            if (tipoCredito == 'unico') ...[
                              _buildCondRow(
                                'Nueva Fecha de Pago',
                                condNuevas['fecha_pago_nueva'] != null
                                    ? _formatFecha(
                                        condNuevas['fecha_pago_nueva']
                                            .toString())
                                    : 'N/A',
                              ),
                              if (condNuevas['monto_mora'] != null &&
                                  (num.tryParse(condNuevas['monto_mora']
                                              .toString()) ??
                                          0) >
                                      0)
                                _buildCondRow(
                                  'Mora',
                                  _formatMonto(condNuevas['monto_mora']),
                                ),
                            ] else ...[
                              if (condNuevas['cuotas_renovadas'] is List &&
                                  (condNuevas['cuotas_renovadas'] as List)
                                      .isNotEmpty)
                                _buildCondRow(
                                  'Fecha Tope',
                                  _getFechaTope(condNuevas['cuotas_renovadas']),
                                ),
                              _buildCondRow(
                                'Cant. Cuotas Nuevas',
                                '${condNuevas['plazo'] ?? 'N/A'}',
                              ),
                              if (condNuevas['monto_mora'] != null &&
                                  (num.tryParse(condNuevas['monto_mora']
                                              .toString()) ??
                                          0) >
                                      0)
                                _buildCondRow(
                                  'Mora',
                                  _formatMonto(condNuevas['monto_mora']),
                                ),
                            ],
                            _buildCondRow(
                              'Nuevo Total',
                              _formatMonto(condNuevas['monto_total']),
                            ),
                            if (condNuevas['abono'] != null &&
                                (num.tryParse(condNuevas['abono'].toString()) ??
                                        0) >
                                    0)
                              _buildCondRow(
                                'Abono',
                                _formatMonto(condNuevas['abono']),
                              ),
                            if (tipoCredito == 'cuotas' &&
                                condNuevas['cuotas_renovadas'] is List &&
                                (condNuevas['cuotas_renovadas'] as List)
                                    .isNotEmpty)
                              _buildListaCuotasMini(
                                  condNuevas['cuotas_renovadas'] as List,
                                  isAnterior: false),
                          ],
                        ),
                      ),
                    ),

                    if (renovacion.observaciones != null &&
                        renovacion.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Observaciones',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          renovacion.observaciones!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatPlazoDias(dynamic days) {
    if (days == null) return 'N/A';
    final int d = int.tryParse(days.toString()) ?? 0;
    if (d <= 0) return 'N/A';
    if (d >= 30 && d % 30 == 0) {
      final meses = d ~/ 30;
      return '$meses ${meses == 1 ? "mes" : "meses"}';
    }
    return '$d días';
  }

  String _getFechaTope(dynamic cuotas) {
    if (cuotas is! List || cuotas.isEmpty) return 'N/A';
    try {
      final last = cuotas.last as Map<String, dynamic>;
      final fecha = DateTime.parse(last['fecha'].toString());
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (_) {
      return 'N/A';
    }
  }
}
