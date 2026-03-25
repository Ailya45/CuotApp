import 'package:flutter/material.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/ui/pages/formulario_renovacion_page.dart';
import 'package:intl/intl.dart';

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
  Map<String, dynamic>? _credito;
  bool _isLoading = true;

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
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
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

    rawCuotas.sort((a, b) => (a['numero_cuota'] as int).compareTo(b['numero_cuota'] as int));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detalle de Pago'),
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
                // No cerramos el detalle, solo navegamos a editar?
                // El código original hacía Navigator.pop(context); widget.onEditar!();
                // Eso está bien si queremos volver a la lista y abrir el editor.
                Navigator.pop(context);
                widget.onEditar!();
              },
              tooltip: 'Editar Crédito',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cliente Info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Información del Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.person, 'Nombre', cliente['nombre'] ?? 'Sin nombre'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.phone, 'Teléfono', cliente['telefono'] ?? 'Sin teléfono'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.credit_card, 'Cédula', cliente['cedula'] ?? 'Sin cédula'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Credito Info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Información', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FormularioRenovacionPage(
                                  creditoId: widget.creditoId,
                                  nombreUsuario: widget.nombreUsuario ?? '',
                                ),
                              ),
                            ).then((result) {
                              if (result == true) _loadDetalle();
                            });
                          },
                          icon: const Icon(Icons.autorenew, size: 16),
                          label: const Text('Renovación'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.inventory, 'Concepto', _credito!['concepto'] ?? 'Sin concepto'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.attach_money, 'Costo Inversión', '\$${costoInversion.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.trending_up, 'Margen Ganancia', '\$${margenGanancia.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.monetization_on, 'Total General', '\$${totalCredito.toStringAsFixed(2)}', isBold: true),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.check_circle, 'Total Pagado', '\$${totalPagado.toStringAsFixed(2)}', color: AppColors.success),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.warning, 'Saldo Pendiente', '\$${saldoPendiente.toStringAsFixed(2)}', color: AppColors.warning),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Historial de Cuotas
            if (rawCuotas.isNotEmpty && _credito!['tipo_credito'] != 'unico') ...[
              const Text('Cuotas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rawCuotas.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cuota = rawCuotas[index];
                    final bool pagada = cuota['pagada'] == true;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: pagada ? AppColors.success.withOpacity(0.2) : AppColors.warning.withOpacity(0.2),
                        child: Text('${cuota['numero_cuota']}'),
                      ),
                      title: Text('Cuota #${cuota['numero_cuota']}'),
                      subtitle: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(cuota['fecha_pago']))}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${(cuota['monto'] as num).toDouble().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(pagada ? 'Pagada' : 'Pendiente', style: TextStyle(color: pagada ? AppColors.success : AppColors.warning, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Historial de Pagos
            const Text('Historial de Pagos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (rawPagos.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No hay pagos registrados')))
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rawPagos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final pago = rawPagos[index];
                    return ListTile(
                      leading: const Icon(Icons.payment, color: AppColors.primaryGreen),
                      title: Text(_credito!['tipo_credito'] == 'unico' ? 'Abono' : 'Pago de la cuota #${pago['numero_cuota']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(pago['fecha_pago_real']))),
                          Text('Método: ${pago['metodo_pago']}'),
                          if (pago['referencia'] != null && pago['referencia'].toString().isNotEmpty)
                            Text('Ref: ${pago['referencia']}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                          if (pago['observaciones'] != null && pago['observaciones'].toString().isNotEmpty)
                            Text('Obs: ${pago['observaciones']}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                        ],
                      ),
                      trailing: Text(
                        '\$${(pago['monto'] as num).toDouble().toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
}
