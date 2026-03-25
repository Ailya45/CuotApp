// lib/widget/seguimiento/tarjeta_credito_unico.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/credito_unico_model.dart';
import 'package:cuot_app/Model/pago_model.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/widget/seguimiento/dialogo_pago_unico.dart';
import 'package:cuot_app/service/whatsapp_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 👈 NUEVO
import 'package:intl/intl.dart';

class TarjetaCreditoUnico extends StatefulWidget {
  final CreditoUnico credito;
  final Function(Pago) onPagoRealizado;
  final VoidCallback onVerDetalle;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  const TarjetaCreditoUnico({
    super.key,
    required this.credito,
    required this.onPagoRealizado,
    required this.onVerDetalle,
    this.onEditar,
    this.onEliminar,
  });

  @override
  State<TarjetaCreditoUnico> createState() => _TarjetaCreditoUnicoState();
}

class _TarjetaCreditoUnicoState extends State<TarjetaCreditoUnico> {
  bool _expandido = false;

  void _enviarWhatsApp() {
    final credito = widget.credito;
    final diasRestantes = credito.estaVencido
        ? '${_diasAtrasoTotal} días de atraso'
        : '$_diasRestantes días';
    final mensaje = WhatsappService.generarFichaUnico(
      creditoId: credito.id.toString(),
      nombreCliente: credito.nombreCliente.trim(),
      concepto: credito.concepto.trim(),
      montoTotal: credito.montoTotal,
      totalPagado: credito.totalPagado,
      saldoPendiente: credito.saldoPendiente,
      cantidadAbonos: credito.pagosRealizados.length,
      fechaLimite: DateFormat('dd/MM/yy').format(credito.fechaLimite),
      diasRestantes: diasRestantes,
    );
    WhatsappService.abrirWhatsApp(
      telefono: credito.telefono,
      mensaje: mensaje,
    );
  }

  int get _diasRestantes {
    final hoy = DateTime.now();
    final fechaLimite = widget.credito.fechaLimite;
    final diferencia = fechaLimite.difference(hoy).inDays;
    return diferencia > 0 ? diferencia : 0;
  }

  int get _diasAtrasoTotal {
    if (widget.credito.fechaInicio == null) return 0;
    final hoy = DateTime.now();
    final inicio = widget.credito.fechaInicio!;
    final diferencia = hoy.difference(inicio).inDays;
    return diferencia > 0 ? diferencia : 0;
  }

  String get _textoDiasRestantes {
    if (widget.credito.estaPagado) return 'Pagado';
    if (widget.credito.estaVencido) {
      final atraso = _diasAtrasoTotal;
      if (atraso > 0) return '$atraso días de atraso';
      return 'Vencido';
    }
    if (_diasRestantes == 0) return 'Último día';
    return '$_diasRestantes días restantes';
  }

  Color get _colorDiasRestantes {
    if (widget.credito.estaPagado) return AppColors.success;
    if (widget.credito.estaVencido) return AppColors.error;
    if (_diasRestantes <= 3) return AppColors.error;
    if (_diasRestantes <= 7) return AppColors.warning;
    return AppColors.info;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shadowColor: widget.credito.estadoColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.credito.estaPagado ? Colors.white : null,
          gradient: widget.credito.estaPagado ? null : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              widget.credito.estadoColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header siempre visible
            InkWell(
              onTap: () {
                setState(() {
                  _expandido = !_expandido;
                });
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Fila superior: Nombre, tipo y flecha
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: widget.credito.tipoPago == 
                                          TipoPagoUnico.unico
                                          ? Colors.purple.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      widget.credito.tipoPago == TipoPagoUnico.unico
                                          ? Icons.payment
                                          : Icons.payment_outlined,
                                      size: 14,
                                      color: widget.credito.tipoPago == 
                                          TipoPagoUnico.unico
                                          ? Colors.purple
                                          : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.credito.nombreCliente,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: widget.credito.telefono.isNotEmpty ? _enviarWhatsApp : null,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.credito.telefono.isEmpty 
                                            ? 'No tiene' 
                                            : widget.credito.telefono,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontStyle: widget.credito.telefono.isEmpty 
                                              ? FontStyle.italic 
                                              : FontStyle.normal,
                                        ),
                                      ),
                                      if (widget.credito.telefono.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        const FaIcon(
                                          FontAwesomeIcons.whatsapp,
                                          size: 12,
                                          color: Colors.green,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _colorDiasRestantes.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    size: 14,
                                    color: _colorDiasRestantes,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _textoDiasRestantes,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _colorDiasRestantes,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Concepto y monto
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Concepto',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.credito.concepto,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox.shrink(),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Grid de montos
                    Row(
                      children: [
                        _buildMontoCard(
                          'Total',
                          '\$${widget.credito.montoTotal.toStringAsFixed(2)}',
                          AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildMontoCard(
                          'Pagado',
                          '\$${widget.credito.totalPagado.toStringAsFixed(2)}',
                          AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _buildMontoCard(
                          'Pendiente',
                          '\$${widget.credito.saldoPendiente.toStringAsFixed(2)}',
                          widget.credito.saldoPendiente > 0 
                              ? AppColors.warning 
                              : AppColors.success,
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
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Progreso de pago',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.credito.estadoColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(widget.credito.progreso * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: widget.credito.estadoColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: widget.credito.progreso.clamp(0.0, 1.0),
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.credito.estadoColor,
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              color: AppColors.info,
                              size: 24,
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
            
            // Sección expandible con botones de acción
            // Sección expandible con botones de acción
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _expandido
                ? Column(
                  children: [
                    const Divider(height: 1),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          // Botones de acción
                          Row(
                            children: [
                              if (widget.credito.saldoPendiente > 0) ...[
                                Expanded(
                                  child: _buildBotonAccion(
                                    icon: Icons.payment,
                                    label: 'Pago Completo',
                                    color: AppColors.success,
                                    onTap: () {
                                      _mostrarDialogoPago(
                                        context,
                                        esParcial: false,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildBotonAccion(
                                    icon: Icons.payment_outlined,
                                    label: 'Pago Parcial',
                                    color: Colors.orange,
                                    onTap: () {
                                      _mostrarDialogoPago(
                                        context,
                                        esParcial: true,
                                      );
                                    },
                                  ),
                                ),
                              ],
                              if (widget.credito.saldoPendiente <= 0) ...[
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: AppColors.success,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Crédito Pagado',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildMontoCard(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonAccion({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoPago(BuildContext context, {required bool esParcial}) {
    showDialog(
      context: context,
      builder: (context) => DialogoPagoUnico(
        credito: widget.credito,
        esParcial: esParcial,
        onPagoRealizado: widget.onPagoRealizado,
      ),
    );
  }
}