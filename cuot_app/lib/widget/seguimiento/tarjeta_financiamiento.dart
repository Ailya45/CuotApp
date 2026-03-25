// lib/widget/seguimiento/tarjeta_financiamiento.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/Model/pago_model.dart';
import 'package:cuot_app/service/whatsapp_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 👈 NUEVO

class TarjetaFinanciamiento extends StatefulWidget {
  final String nombreCliente;
  final String telefono;
  final String estado;
  final double montoCuota;
  final double totalPagado;
  final double totalPendiente;
  final double progreso;
  final int cuotasVencidas;
  final List<CuotaPersonalizada> cuotas;
  final List<Pago> pagos;
  final String concepto;
  final double totalCredito; // 👈 NUEVO
  final String? creditoId;
  final String modalidadPago; // 👈 NUEVO: Recibe la modalidad real (Diario, Semanal, etc.)
  final Function(int) onCuotaTap;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;
  final VoidCallback onVerDetalle;

  const TarjetaFinanciamiento({
    super.key,
    required this.nombreCliente,
    required this.telefono,
    required this.estado,
    required this.montoCuota,
    required this.totalPagado,
    required this.totalPendiente,
    required this.progreso,
    required this.cuotasVencidas,
    required this.cuotas,
    required this.pagos,
    required this.concepto,
    required this.totalCredito, // 👈 NUEVO
    required this.modalidadPago, // 👈 NUEVO
    this.creditoId,
    required this.onCuotaTap,
    required this.onVerDetalle,
    this.onEditar,
    this.onEliminar,
  });

  @override
  State<TarjetaFinanciamiento> createState() => _TarjetaFinanciamientoState();
}

class _TarjetaFinanciamientoState extends State<TarjetaFinanciamiento> {
  bool _mostrarRegistroPagos = false;

  void _enviarWhatsApp() {
    final mensaje = WhatsappService.generarFichaCuotas(
      creditoId: widget.creditoId ?? '0',
      nombreCliente: widget.nombreCliente.trim(),
      concepto: widget.concepto.trim(),
      modalidadPago: widget.modalidadPago, // 👈 MODIFICADO: Usa la modalidad real
      montoTotal: widget.totalCredito,
      totalPagado: widget.totalPagado,
      saldoPendiente: widget.totalPendiente,
      totalCuotas: widget.cuotas.length,
      cuotasPagadas: widget.cuotas.where((c) => c.pagada).length,
      cuotasVencidas: widget.cuotasVencidas,
      montoCuota: widget.montoCuota,
    );
    WhatsappService.abrirWhatsApp(
      telefono: widget.telefono,
      mensaje: mensaje,
    );
  }


  Color get _estadoColor {
    switch (widget.estado.toLowerCase()) {
      case 'pagado':
        return AppColors.success;
      case 'atrasado':
        return AppColors.error;
      case 'al día':
        return AppColors.primaryGreen;
      default:
        return AppColors.warning;
    }
  }

  IconData get _estadoIcon {
    switch (widget.estado.toLowerCase()) {
      case 'pagado':
        return Icons.check_circle;
      case 'atrasado':
        return Icons.warning;
      case 'al día':
        return Icons.thumb_up;
      default:
        return Icons.info;
    }
  }

  bool _cuotaPagada(int numeroCuota) {
    return widget.cuotas.firstWhere((c) => c.numeroCuota == numeroCuota).pagada;
  }

  int get _cuotasPagadasCount => widget.cuotas.where((c) => c.pagada).length;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: widget.estado.toLowerCase() == 'pagado' ? Colors.white : null,
          gradient: widget.estado.toLowerCase() == 'pagado' ? null : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _estadoColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header con información principal
            InkWell(
              onTap: () {
                setState(() {
                  _mostrarRegistroPagos = !_mostrarRegistroPagos;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Fila: Nombre, estado y flecha
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.nombreCliente,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: widget.telefono.isNotEmpty ? _enviarWhatsApp : null,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.telefono.isEmpty 
                                            ? 'No tiene' 
                                            : widget.telefono,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          fontStyle: widget.telefono.isEmpty 
                                              ? FontStyle.italic 
                                              : FontStyle.normal,
                                        ),
                                      ),
                                      if (widget.telefono.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        const FaIcon(
                                          FontAwesomeIcons.whatsapp,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.primaryGreen.withOpacity(0.7)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.concepto,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.darkGrey.withOpacity(0.8),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _estadoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(_estadoIcon, size: 14, color: _estadoColor),
                              const SizedBox(width: 4),
                              Text(
                                widget.estado,
                                style: TextStyle(
                                  color: _estadoColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Mini resumen de cuotas - ACTUALIZADO con Vencidas
                    Row(
                      children: [
                        _buildMiniEstadistica(
                          'Pagadas',
                          '$_cuotasPagadasCount',
                          AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _buildMiniEstadistica(
                          'Vencidas',
                          '${widget.cuotasVencidas}',
                          AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        _buildMiniEstadistica(
                          'Restantes',
                          '${widget.cuotas.length - _cuotasPagadasCount}',
                          Colors.amber,
                        ),
                        const Spacer(),
                        _buildMiniEstadistica(
                          'Total',
                          '\$${widget.totalCredito.toStringAsFixed(2)}',
                          AppColors.primaryGreen,
                          isProminent: true,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Mensaje de estado mejorado
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getMensajeEstado(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _estadoColor,
                              fontWeight: widget.cuotasVencidas > 0 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (widget.cuotasVencidas > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${widget.cuotasVencidas} vencida${widget.cuotasVencidas != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Barra de progreso y Ojo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Progreso',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    '${(widget.progreso * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _estadoColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: widget.progreso.clamp(0.0, 1.0),
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(_estadoColor),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón de acción (Ver Detalle)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              color: AppColors.info,
                              size: 22,
                            ),
                            onPressed: widget.onVerDetalle,
                            tooltip: 'Ver Detalle',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Sección expandible de Registro de Pagos
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _mostrarRegistroPagos 
                ? Column(
                  children: [
                    const Divider(height: 1),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título de la sección
                          Row(
                            children: [
                              const Text(
                                'Registro de Pagos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_cuotasPagadasCount/${widget.cuotas.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Cuotas en horizontal (UNA SOLA FILA)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: widget.cuotas.map((cuota) {
                                return _buildCuotaHorizontal(cuota);
                              }).toList(),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Leyenda de colores para las cuotas
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLeyendaColor(AppColors.success, 'Pagada'),
                              const SizedBox(width: 16),
                              _buildLeyendaColor(Colors.amber, 'Pendiente'),
                              const SizedBox(width: 16),
                              _buildLeyendaColor(AppColors.error, 'Vencida'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniEstadistica(String label, String valor, Color color, {bool isProminent = false}) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isProminent) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isProminent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: isProminent ? 14 : 12,
                  color: isProminent ? color : Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: isProminent ? 10 : 10,
                  color: Colors.grey.shade600,
                  fontWeight: isProminent ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    if (isProminent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: content,
      );
    }

    return Expanded(
      flex: 1,
      child: content,
    );
  }

  Widget _buildCuotaHorizontal(CuotaPersonalizada cuota) {
    final pagada = _cuotaPagada(cuota.numeroCuota);
    final fechaCuota = DateTime(
      cuota.fechaPago.year,
      cuota.fechaPago.month,
      cuota.fechaPago.day,
    );
    final hoy = DateTime.now();
    final fechaActual = DateTime(hoy.year, hoy.month, hoy.day);
    final vencida = !pagada && fechaCuota.isBefore(fechaActual);
    
    Color getColor() {
      if (pagada) return AppColors.success;
      if (vencida) return AppColors.error;
      return Colors.amber;
    }
    
    final borderColor = pagada 
        ? AppColors.success.withOpacity(0.3)
        : vencida
            ? AppColors.error.withOpacity(0.3)
            : Colors.amber.withOpacity(0.5);
    
    return GestureDetector(
      onTap: pagada ? null : () => widget.onCuotaTap(cuota.numeroCuota),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: pagada 
              ? AppColors.success.withOpacity(0.1)
              : vencida
                  ? AppColors.error.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: !pagada && !vencida ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '#${cuota.numeroCuota}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: getColor(),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${cuota.fechaPago.day.toString().padLeft(2, '0')}/'
              '${cuota.fechaPago.month.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: pagada || vencida ? getColor() : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 2),
            pagada
                ? const Icon(Icons.check_circle, size: 14, color: AppColors.success)
                : vencida
                    ? const Icon(Icons.warning, size: 14, color: AppColors.error)
                    : Text(
                        '\$${cuota.monto.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyendaColor(Color color, String texto) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getMensajeEstado() {
    if (widget.cuotasVencidas > 0) {
      return 'Tienes ${widget.cuotasVencidas} cuota${widget.cuotasVencidas != 1 ? 's' : ''} vencida${widget.cuotasVencidas != 1 ? 's' : ''}';
    }
    
    switch (widget.estado.toLowerCase()) {
      case 'pagado':
        return '¡Crédito pagado completamente!';
      case 'atrasado':
        return 'Tienes cuotas pendientes por pagar';
      case 'al día':
        // Encontrar la próxima cuota no pagada
        final proximaCuota = widget.cuotas.where((c) => !c.pagada).toList();
        if (proximaCuota.isNotEmpty) {
          proximaCuota.sort((a, b) => a.fechaPago.compareTo(b.fechaPago));
          final hoy = DateTime.now();
          final fechaNext = proximaCuota.first.fechaPago;
          final diff = fechaNext.difference(hoy).inDays;
          if (diff <= 0) return 'Hoy vence tu próxima cuota';
          return 'Próxima cuota en $diff (días)';
        }
        return 'Estás al día con tus pagos';
      default:
        return 'Revisa el estado de tus cuotas';
    }
  }
}