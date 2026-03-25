import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/service/renovacion_service.dart';
import 'package:cuot_app/widget/dashboard/custom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:cuot_app/ui/pages/dashboard_screen.dart';

class HistorialRenovacionesPage extends StatefulWidget {
  final String nombreUsuario;

  const HistorialRenovacionesPage({
    super.key,
    required this.nombreUsuario,
  });

  @override
  State<HistorialRenovacionesPage> createState() =>
      _HistorialRenovacionesPageState();
}

class _HistorialRenovacionesPageState extends State<HistorialRenovacionesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RenovacionService _renovacionService = RenovacionService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _renovaciones = [];
  bool _isLoading = true;
  String _filtroEstado = 'todos';
  String _busqueda = '';
  DateTimeRange? _filtroFechas;

  @override
  void initState() {
    super.initState();
    _loadRenovaciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRenovaciones() async {
    setState(() => _isLoading = true);
    try {
      final data =
          await _renovacionService.getRenovacionesRaw(widget.nombreUsuario);
      setState(() {
        _renovaciones = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando renovaciones: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _renovacionesFiltradas {
    return _renovaciones.where((r) {
      // Filtro por estado
      if (_filtroEstado != 'todos') {
        if (r['estado'] != _filtroEstado) return false;
      }

      // Filtro por búsqueda (nombre de cliente)
      if (_busqueda.isNotEmpty) {
        final credito = r['Creditos'];
        String nombre = '';
        if (credito != null && credito['Clientes'] != null) {
          nombre = credito['Clientes']['nombre']?.toString().toLowerCase() ?? '';
        }
        if (!nombre.contains(_busqueda.toLowerCase())) return false;
      }

      // Filtro por fechas
      if (_filtroFechas != null) {
        final fecha = DateTime.tryParse(r['fecha_renovacion'] ?? '');
        if (fecha != null) {
          if (fecha.isBefore(_filtroFechas!.start) ||
              fecha.isAfter(_filtroFechas!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }
      }

      return true;
    }).toList();
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
        return AppColors.info;
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
        return Icons.hourglass_top;
      default:
        return Icons.info;
    }
  }

  Future<void> _seleccionarFechas() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (rango != null) {
      setState(() => _filtroFechas = rango);
    }
  }

  void _mostrarDetalleRenovacion(Map<String, dynamic> renovacion) {
    final condAnteriores = renovacion['condiciones_anteriores'] is Map
        ? Map<String, dynamic>.from(renovacion['condiciones_anteriores'])
        : <String, dynamic>{};
    final condNuevas = renovacion['condiciones_nuevas'] is Map
        ? Map<String, dynamic>.from(renovacion['condiciones_nuevas'])
        : <String, dynamic>{};
    final credito = renovacion['Creditos'];
    final cliente =
        credito != null && credito['Clientes'] != null ? credito['Clientes'] : {};
    
    final tipoCredito = condNuevas['tipo_credito'] ?? 'cuotas';
    final labelTipoCuota = tipoCredito == 'unico' ? "Cuota Simple" : "Cuota Fija";

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
                          _getIconEstado(renovacion['estado'] ?? ''),
                          color:
                              _getColorEstado(renovacion['estado'] ?? ''),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Detalle de Renovación',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getColorEstado(
                                    renovacion['estado'] ?? '')
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (renovacion['estado'] ?? 'N/A')
                                .toString()
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getColorEstado(
                                  renovacion['estado'] ?? ''),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    Text('Tipo de Cuota: $labelTipoCuota', 
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // Info del cliente
                    _buildDetalleRow(
                        'Cliente', cliente['nombre'] ?? 'N/A'),
                    _buildDetalleRow(
                        'Concepto', credito?['concepto'] ?? 'N/A'),
                    _buildDetalleRow('Motivo',
                        renovacion['motivo'] ?? 'Sin motivo'),
                    _buildDetalleRow(
                      'Fecha de Renovación',
                      renovacion['fecha_renovacion'] != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(
                              DateTime.parse(
                                  renovacion['fecha_renovacion']))
                          : 'N/A',
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
                              _buildCondRow('Plazo Anterior',
                                  _formatPlazoDias(condAnteriores['plazo_dias'] ?? condAnteriores['plazo'])),
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
                          children: [
                            if (tipoCredito == 'unico') ...[
                              _buildCondRow('Nuevo Plazo',
                                  _formatPlazoDias(_calcularDiasSimple(renovacion['fecha_renovacion'], condNuevas['fecha_pago_nueva']))),
                              _buildCondRow('Mora',
                                  '\$${(condNuevas['monto_mora'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                            ] else ...[
                              _buildCondRow('Fecha Tope',
                                  _getFechaTope(condNuevas['cuotas_renovadas'])),
                              _buildCondRow('Cant. Cuotas Nuevas',
                                  '${condNuevas['plazo'] ?? 'N/A'}'),
                              _buildCondRow('Mora',
                                  '\$${(condNuevas['monto_mora'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                            ],
                            _buildCondRow('Nuevo Total',
                                '\$${(condNuevas['monto_total'] as num?)?.toStringAsFixed(2) ?? 'N/A'}'),
                            if (condNuevas['abono'] != null &&
                                (condNuevas['abono'] as num) > 0)
                              _buildCondRow('Abono',
                                  '\$${(condNuevas['abono'] as num).toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (renovacion['observaciones'] != null &&
                        renovacion['observaciones'].toString().isNotEmpty) ...[
                      const Text('Observaciones',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          renovacion['observaciones'],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Botón para ver historial de cambios
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _verHistorialCambios(renovacion['id']),
                        icon: const Icon(Icons.history),
                        label:
                            const Text('Ver Historial de Cambios'),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

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

  String _getFechaTope(dynamic cuotas) {
    if (cuotas is! List || cuotas.isEmpty) return 'N/A';
    try {
      final last = cuotas.last;
      final fecha = DateTime.parse(last['fecha']);
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (e) {
      return 'Err';
    }
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

  String _getResumenPlazo(Map<String, dynamic> renovacion, Map<String, dynamic> condNuevas) {
    final tipo = condNuevas['tipo_credito'] ?? 'cuotas';
    final fechaRen = renovacion['fecha_renovacion'];
    
    if (tipo == 'unico') {
      final fechaNueva = condNuevas['fecha_pago_nueva'];
      return '${_calcularDiasSimple(fechaRen, fechaNueva)} días';
    } else {
      final cuotas = condNuevas['cuotas_renovadas'];
      if (cuotas is List && cuotas.isNotEmpty) {
        final last = cuotas.last;
        final s = DateTime.parse(fechaRen.toString());
        final e = DateTime.parse(last['fecha'].toString());
        return '${e.difference(s).inDays} días';
      }
      return '? días';
    }
  }

  Future<void> _verHistorialCambios(String renovacionId) async {
    final historial =
        await _renovacionService.getHistorialRenovacion(renovacionId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.history, color: AppColors.info),
            SizedBox(width: 8),
            Text('Historial de Cambios'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: historial.isEmpty
              ? const Center(
                  child: Text('No hay cambios registrados'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final h = historial[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _getColorEstado(h.estadoNuevo)
                                .withOpacity(0.1),
                        child: Icon(
                          _getIconEstado(h.estadoNuevo),
                          size: 18,
                          color: _getColorEstado(h.estadoNuevo),
                        ),
                      ),
                      title: Text(
                        '${h.estadoAnterior ?? 'Inicio'} → ${h.estadoNuevo}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(h.fechaCambio),
                            style: const TextStyle(fontSize: 11),
                          ),
                          if (h.observaciones != null &&
                              h.observaciones!.isNotEmpty)
                            Text(
                              h.observaciones!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              correo: null,
              userName: widget.nombreUsuario,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      },
      child: Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(
        nombre_usuario: widget.nombreUsuario,
        ventanaActiva: 'historial',
      ),
      appBar: AppBar(
        title: const Text('Historial de Renovaciones'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _seleccionarFechas,
            tooltip: 'Filtrar por fecha',
          ),
          if (_filtroFechas != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _filtroFechas = null),
              tooltip: 'Limpiar filtro de fecha',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _busqueda = value),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre de cliente...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtros de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: ['todos', 'solicitada', 'aprobada', 'rechazada', 'cancelada']
                  .map((filtro) {
                final isSelected = _filtroEstado == filtro;
                final color = filtro == 'todos'
                    ? AppColors.info
                    : _getColorEstado(filtro);
                final label = filtro == 'todos'
                    ? 'Todos'
                    : '${filtro[0].toUpperCase()}${filtro.substring(1)}';

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selectedColor: color,
                    checkmarkColor: Colors.white,
                    backgroundColor: color.withOpacity(0.1),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : color.withOpacity(0.5),
                    ),
                    onSelected: (_) =>
                        setState(() => _filtroEstado = filtro),
                  ),
                );
              }).toList(),
            ),
          ),

          // Info de filtro de fechas
          if (_filtroFechas != null)
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(_filtroFechas!.start)} - ${DateFormat('dd/MM/yyyy').format(_filtroFechas!.end)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.info),
                  ),
                ],
              ),
            ),

          // Lista de renovaciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _renovacionesFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history,
                                size: 64,
                                color: AppColors.mediumGrey),
                            const SizedBox(height: 16),
                            Text(
                              'No hay renovaciones',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRenovaciones,
                        color: AppColors.primaryGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                              top: 8, bottom: 80),
                          itemCount:
                              _renovacionesFiltradas.length,
                          itemBuilder: (context, index) {
                            final r =
                                _renovacionesFiltradas[index];
                            return _buildRenovacionCard(r);
                          },
                        ),
                      ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildRenovacionCard(Map<String, dynamic> renovacion) {
    final credito = renovacion['Creditos'];
    final cliente = credito != null && credito['Clientes'] != null
        ? credito['Clientes']
        : {};
    final condNuevas =
        renovacion['condiciones_nuevas'] is Map
            ? Map<String, dynamic>.from(
                renovacion['condiciones_nuevas'])
            : <String, dynamic>{};
    final estado = renovacion['estado'] ?? 'solicitada';

    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              // Header: Cliente + Estado
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        _getColorEstado(estado).withOpacity(0.1),
                    radius: 18,
                    child: Icon(
                      _getIconEstado(estado),
                      color: _getColorEstado(estado),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente['nombre'] ?? 'Cliente desconocido',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          credito?['concepto'] ?? 'Sin concepto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getColorEstado(estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getColorEstado(estado),
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
                      _getResumenPlazo(renovacion, condNuevas),
                      Icons.schedule,
                    ),
                  ),
                  Expanded(
                    child: _buildMiniInfo(
                      'Mora',
                      '\$${(condNuevas['monto_mora'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      Icons.warning_amber_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildMiniInfo(
                      'Total',
                      '\$${(condNuevas['monto_total'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      Icons.payments,
                    ),
                  ),
                  Expanded(
                    child: _buildMiniInfo(
                      'Fecha',
                      renovacion['fecha_renovacion'] != null
                          ? DateFormat('dd/MM/yy').format(
                              DateTime.parse(
                                  renovacion['fecha_renovacion']))
                          : 'N/A',
                      Icons.event,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
