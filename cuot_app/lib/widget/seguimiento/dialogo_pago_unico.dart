// lib/widget/seguimiento/dialogo_pago_unico.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/credito_unico_model.dart';
import 'package:cuot_app/Model/pago_model.dart';
import 'package:cuot_app/theme/app_colors.dart';

class DialogoPagoUnico extends StatefulWidget {
  final CreditoUnico credito;
  final bool esParcial;
  final Function(Pago) onPagoRealizado;

  const DialogoPagoUnico({
    super.key,
    required this.credito,
    required this.esParcial,
    required this.onPagoRealizado,
  });

  @override
  State<DialogoPagoUnico> createState() => _DialogoPagoUnicoState();
}

class _DialogoPagoUnicoState extends State<DialogoPagoUnico> 
    with SingleTickerProviderStateMixin {
  late TextEditingController _montoController;
  late TextEditingController _tasaController; // 👈 NUEVO
  late TextEditingController _referenciaController;
  late TextEditingController _observacionesController;
  String _metodoPago = 'efectivo';
  DateTime _fechaPago = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _metodosPago = [
    {'valor': 'efectivo', 'label': 'Efectivo', 'icon': Icons.money, 'color': Colors.green},
    {'valor': 'transferencia', 'label': 'Transferencia', 'icon': Icons.compare_arrows, 'color': Colors.blue},
    {'valor': 'pagomovil', 'label': 'Pago Movil', 'icon': Icons.credit_card, 'color': Colors.purple},
    {'valor': 'binance', 'label': 'Binance', 'icon': Icons.currency_bitcoin, 'color': Colors.red},
    {'valor': 'efectivodivisas', 'label': 'Efectivo Divisas', 'icon': Icons.money_off_outlined, 'color': Colors.red},
  
  ];

  double get _maxMonto => widget.credito.saldoPendiente;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: widget.esParcial 
          ? (_maxMonto / 2).toStringAsFixed(2)
          : _maxMonto.toStringAsFixed(2),
    );
    _tasaController = TextEditingController(); // 👈 NUEVO
    _referenciaController = TextEditingController();
    _observacionesController = TextEditingController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _tasaController.dispose(); // 👈 NUEVO
    _referenciaController.dispose();
    _observacionesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 24,
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.primaryGreen.withOpacity(0.03),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header decorativo
              Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.credito.estadoColor,
                      widget.credito.estadoColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.credito.estadoColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.esParcial 
                                    ? Icons.payment_outlined
                                    : Icons.payment,
                                size: 40,
                                color: widget.credito.estadoColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.esParcial 
                                  ? 'Pago Parcial'
                                  : 'Pago Completo',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.credito.concepto,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Resumen
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cliente',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.credito.nombreCliente,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: widget.credito.estadoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Total: \$${widget.credito.montoTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.credito.estadoColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Información de pagos
                      Row(
                        children: [
                          _buildInfoCard(
                            'Pagado',
                            '\$${widget.credito.totalPagado.toStringAsFixed(2)}',
                            AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoCard(
                            'Pendiente',
                            '\$${widget.credito.saldoPendiente.toStringAsFixed(2)}',
                            AppColors.warning,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Campo de monto
                      TextFormField(
                        controller: _montoController,
                        decoration: InputDecoration(
                          labelText: widget.esParcial
                              ? 'Monto a pagar (parcial)'
                              : 'Monto total',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        enabled: widget.esParcial,
                        onChanged: (value) => setState(() {}), // Actualizar Bs.
                      ),
                      
                      const SizedBox(height: 16),

                      // 👈 NUEVO: Tasa de cambio y Monto en Bs.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _tasaController,
                              decoration: InputDecoration(
                                labelText: 'Tasa del día (BCV)',
                                prefixText: 'Bs. ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Equivalente en Bolívares',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    () {
                                      final montoUsd = double.tryParse(_montoController.text) ?? 0.0;
                                      final tasa = double.tryParse(_tasaController.text) ?? 0.0;
                                      final totalBs = montoUsd * tasa;
                                      return 'Bs. ${totalBs.toStringAsFixed(2)}';
                                    }(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (widget.esParcial) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMontoRapido(0.25),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMontoRapido(0.5),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMontoRapido(0.75),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Método de pago
                      const Text(
                        'Método de pago',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _metodosPago.map((metodo) {
                          final isSelected = _metodoPago == metodo['valor'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _metodoPago = metodo['valor'];
                              });
                            },
                            child: Container(
                              width: (MediaQuery.of(context).size.width - 80) / 2,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          metodo['color'],
                                          metodo['color'].withOpacity(0.7),
                                        ],
                                      )
                                    : null,
                                color: isSelected ? null : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : metodo['color'].withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    metodo['icon'],
                                    color: isSelected 
                                        ? Colors.white 
                                        : metodo['color'],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    metodo['label'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected 
                                          ? Colors.white 
                                          : metodo['color'],
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Fecha de pago
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _fechaPago,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _fechaPago = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fecha de pago',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    '${_fechaPago.day}/${_fechaPago.month}/${_fechaPago.year}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Observaciones
                      TextFormField(
                        controller: _observacionesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Observaciones (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCELAR'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _confirmarPago,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('CONFIRMAR'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
              ),
            ),
            Text(
              valor,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMontoRapido(double porcentaje) {
    final monto = _maxMonto * porcentaje;
    final isSelected = (double.tryParse(_montoController.text) ?? 0) == monto;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _montoController.text = monto.toStringAsFixed(2);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${(porcentaje * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.darkGrey,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarPago() {
    final monto = double.tryParse(_montoController.text) ?? 0;
    
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (monto > _maxMonto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto no puede exceder el saldo pendiente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nuevoPago = Pago(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      creditoId: widget.credito.id,
      numeroCuota: 1,
      fechaPago: widget.credito.fechaLimite,
      monto: monto,
      fechaPagoReal: _fechaPago,
      estado: 'pagado',
      metodoPago: _metodoPago,
    );

    widget.onPagoRealizado(nuevoPago);
    Navigator.pop(context);
  }
}