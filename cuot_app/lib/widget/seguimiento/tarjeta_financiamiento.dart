// lib/widget/seguimiento/tarjeta_financiamiento.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/Model/pago_model.dart';
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
  final Function(int) onCuotaTap;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

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
    required this.onCuotaTap,
    this.onEditar,
    this.onEliminar,
  });

  @override
  State<TarjetaFinanciamiento> createState() => _TarjetaFinanciamientoState();
}

class _TarjetaFinanciamientoState extends State<TarjetaFinanciamiento> {
  bool _mostrarRegistroPagos = false;

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
  int get _cuotasPendientesCount => widget.cuotas.where((c) => !c.pagada).length;

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
          gradient: LinearGradient(
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
                              ),
                              const SizedBox(height: 4),
                                Row(
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
                        const SizedBox(width: 4),
                        if (widget.onEditar != null)
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              icon: Icon(
                                Icons.edit,
                                size: 16,
                                color: AppColors.info,
                              ),
                              onPressed: widget.onEditar,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Editar',
                            ),
                          ),
                        if (widget.onEliminar != null)
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: 16,
                                color: AppColors.error,
                              ),
                              onPressed: widget.onEliminar,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Eliminar',
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            _mostrarRegistroPagos
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _mostrarRegistroPagos = !_mostrarRegistroPagos;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
                          'Pendientes',
                          '$_cuotasPendientesCount',
                          AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        _buildMiniEstadistica(
                          'Vencidas',
                          '${widget.cuotasVencidas}',
                          AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        _buildMiniEstadistica(
                          'Monto Total',
                          '\$${widget.totalCredito.toStringAsFixed(2)}',
                          AppColors.primaryGreen,
                          isProminent: true,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Barra de progreso simplificada
                    Column(
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
                    
                    const SizedBox(height: 8),
                    
                    // Mensaje de estado mejorado
                    Row(
                      children: [
                        Icon(_estadoIcon, size: 14, color: _estadoColor),
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
                  ],
                ),
              ),
            ),
            
            // Sección expandible de Registro de Pagos
            if (_mostrarRegistroPagos) ...[
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
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
                    
                    const SizedBox(height: 8),
                    
                    // Leyenda de colores para las cuotas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLeyendaColor(AppColors.success, 'Pagada'),
                        const SizedBox(width: 16),
                        _buildLeyendaColor(AppColors.primaryGreen, 'Pendiente'),
                        const SizedBox(width: 16),
                        _buildLeyendaColor(AppColors.error, 'Vencida'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniEstadistica(String label, String valor, Color color, {bool isProminent = false}) {
    return Expanded(
      flex: isProminent ? 2 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isProminent ? 10 : 8,
            height: isProminent ? 10 : 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: isProminent ? 14 : 12,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isProminent ? 11 : 10,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
      return AppColors.primaryGreen;
    }
    
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
            color: getColor().withOpacity(0.3),
            width: 1,
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
                          color: AppColors.primaryGreen,
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
        return 'Estás al día con tus pagos';
      default:
        return 'Revisa el estado de tus cuotas';
    }
  }
}