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

    return DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('Detalle de Pago'),
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Información'),
                Tab(text: 'Detalles'),
                Tab(text: 'Historial'),
              ],
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
            actions: [
              if (widget.onEditar != null && !isPagado)
                IconButton(
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    // No cerramos el detalle, solo navegamos a editar?
                    // El código original hacía Navigator.pop(context); widget.onEditar!();
                    // Eso está bien si queremos volver a la lista y abrir el editor.
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
                          // Recargar datos si se renovó
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
                    color: AppColors.error, // RED TRASH
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
          body: TabBarView(
            children: [
              _buildInfoTab(),
              _buildDetallesTab(),
              _buildHistorialTab(),
            ],
          ),
        ));
  }

  Widget _buildInfoTab() {
    final cliente = _credito!['Clientes'] ?? {};
    final bool isPagado = (_credito?['costo_inversion'] as num? ?? 0) +
            (_credito?['margen_ganancia'] as num? ?? 0) -
            ((_credito?['Pagos'] as List<dynamic>?)?.fold(
                    0.0,
                    (sum, pago) =>
                        (sum as double) + (pago['monto'] as num).toDouble()) ??
                0.0) <=
        0.01;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cliente: ${cliente['nombre'] ?? 'N/A'}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.person, 'Nombre', cliente['nombre'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.phone, 'Teléfono', cliente['telefono'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(
              Icons.credit_score, 'Concepto', _credito?['concepto'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today, 'Fecha de inicio',
              _credito?['fecha_inicio'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_month, 'Fecha límite',
              _credito?['fecha_limite'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.monetization_on, 'Monto total',
              '\$${((_credito?['costo_inversion'] as num?)?.toDouble() ?? 0) + ((_credito?['margen_ganancia'] as num?)?.toDouble() ?? 0)}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.payments, 'Saldo pendiente',
              '\$${(_credito?['costo_inversion'] as num? ?? 0) + (_credito?['margen_ganancia'] as num? ?? 0) - ((_credito?['Pagos'] as List<dynamic>?)?.fold(0.0, (sum, pago) => (sum as double) + (pago['monto'] as num).toDouble()) ?? 0.0)}'),
          const SizedBox(height: 8),
          _buildInfoRow(
              Icons.check_circle, 'Estado', isPagado ? 'Pagado' : 'Activo',
              color: isPagado ? AppColors.success : AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildDetallesTab() {
    final List<dynamic> rawCuotas = _credito?['Cuotas'] ?? [];
    final List<dynamic> rawPagos = _credito?['Pagos'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cuotas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (rawCuotas.isEmpty) const Text('No hay cuotas registradas.'),
          for (var cuota in rawCuotas)
            Card(
              color: Colors.white,
              child: ListTile(
                title: Text(
                    'Cuota ${cuota['numero_cuota'] ?? 'N/A'} - \$${(cuota['monto'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                subtitle: Text(
                    'Fecha: ${cuota['fecha_pago'] ?? 'N/A'} - ${cuota['pagada'] == true ? 'Pagada' : 'Pendiente'}'),
              ),
            ),
          const SizedBox(height: 20),
          const Text('Historial de Pagos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (rawPagos.isEmpty) const Text('No hay pagos registrados.'),
          for (var pago in rawPagos)
            Card(
              child: ListTile(
                title: Text(
                    '\$${(pago['monto'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                subtitle: Text('Fecha: ${pago['fecha_pago_real'] ?? 'N/A'}'),
                trailing: Text(pago['metodo']?.toString() ?? ''),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorialTab() {
    if (_isHistorialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historialRenovaciones.isEmpty) {
      return const Center(
          child: Text('No se han registrado renovaciones para este crédito.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historialRenovaciones.length,
      itemBuilder: (context, index) {
        final renovacion = _historialRenovaciones[index];
        final estado = renovacion.estado ?? 'solicitada';
        final colorEstado = _getColorEstado(estado);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            onTap: () => _mostrarDetalleRenovacion(renovacion),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Fecha + Estado
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
                            Text(
                              'Renovación ${DateFormat('dd/MM/yyyy').format(renovacion.fechaRenovacion)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              estado.capitalize(),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorEstado,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  if (renovacion.observaciones != null &&
                      renovacion.observaciones!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      renovacion.observaciones!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _formatCondiciones(Map<String, dynamic> condiciones,
      {required bool isAnterior}) {
    List<Widget> widgets = [];
    final tipoCredito = condiciones['tipo_credito'] ?? 'cuotas';

    try {
      condiciones.forEach((key, value) {
        String label = '';
        String displayValue = '';

        switch (key) {
          case 'plazo':
            if (tipoCredito == 'unico') {
              label = 'Plazo';
              displayValue = isAnterior
                  ? '${condiciones['plazo_dias'] ?? 'N/A'} días'
                  : _calcularDiasPlazo(condiciones);
            } else {
              label = 'Plazo';
              displayValue = '$value cuotas';
            }
            break;
          case 'plazo_dias':
            if (tipoCredito == 'unico') {
              label = 'Plazo';
              displayValue = '$value días';
            }
            break;
          case 'cuota':
            if (tipoCredito != 'unico') {
              label = 'Cuota';
              displayValue = '\$${value.toStringAsFixed(2)}';
            }
            break;
          case 'saldo_pendiente':
            label = 'Saldo Pendiente';
            displayValue = '\$${value.toStringAsFixed(2)}';
            break;
          case 'monto_total':
            label = 'Monto Total';
            displayValue = '\$${value.toStringAsFixed(2)}';
            break;
          case 'costo_inversion':
            label = 'Costo de Inversión';
            displayValue = '\$${value.toStringAsFixed(2)}';
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
            if (value != null && value > 0) {
              label = 'Abono';
              displayValue = '\$${value.toStringAsFixed(2)}';
            }
            break;
          case 'incluye_mora':
            if (value == true) {
              label = 'Mora Incluida';
              displayValue = 'Sí';
            }
            break;
          case 'monto_mora':
            if (value != null && value > 0) {
              label = 'Monto de Mora';
              displayValue = '\$${value.toStringAsFixed(2)}';
            }
            break;
          case 'fecha_pago_nueva':
            if (value != null) {
              label = 'Nueva Fecha de Pago';
              displayValue =
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(value));
            }
            break;
          case 'cuotas_renovadas':
            if (value != null && value is List) {
              label = 'Cuotas Renovadas';
              displayValue = '${value.length} cuotas';
            }
            break;
          default:
            // Ignorar otros campos
            break;
        }

        if (label.isNotEmpty) {
          widgets.add(Text('$label: $displayValue'));
        }
      });
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

  Widget _buildCondRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold)),
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
    final tipoCredito = condNuevas['tipo_credito'] ?? 'cuotas';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
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

                    // Título
                    Row(
                      children: [
                        Icon(
                          _getIconEstado(renovacion.estado ?? ''),
                          color: _getColorEstado(renovacion.estado ?? ''),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Renovación ${DateFormat('dd/MM/yyyy').format(renovacion.fechaRenovacion)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estado: ${renovacion.estado?.capitalize() ?? 'Desconocido'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getColorEstado(renovacion.estado ?? ''),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fecha de Renovación
                    _buildDetalleRow(
                      'Fecha de Renovación',
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
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            if (tipoCredito == 'unico') ...[
                              _buildCondRow(
                                  'Plazo Anterior',
                                  _formatPlazoDias(
                                      condAnteriores['plazo_dias'] ??
                                          condAnteriores['plazo'])),
                            ] else ...[
                              _buildCondRow('Plazo Anterior',
                                  '${condAnteriores['plazo'] ?? 'N/A'} cuotas'),
                              _buildCondRow('Cuota',
                                  '\$${(condAnteriores['cuota'] as num?)?.toStringAsFixed(2) ?? 'N/A'}'),
                            ],
                            _buildCondRow('Saldo en la fecha',
                                '\$${(condAnteriores['saldo_pendiente'] as num?)?.toStringAsFixed(2) ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Condiciones Nuevas
                    const Text('Condiciones Nuevas',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: _formatCondiciones(
                              renovacion.condicionesNuevas,
                              isAnterior: false),
                        ),
                      ),
                    ),

                    if (renovacion.observaciones != null &&
                        renovacion.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Observaciones',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(renovacion.observaciones!),
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
}
