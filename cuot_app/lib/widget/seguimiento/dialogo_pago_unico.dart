// lib/widget/seguimiento/dialogo_pago_unico.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/utils/scrapper_util.dart'; // 👈 NUEVO: Scrapper
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
  bool _isLoadingTasa = false; // 👈 NUEVO: Estado de carga
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _metodosPago = [
    {'valor': 'efectivo', 'label': 'Efectivo', 'icon': Icons.money, 'color': Colors.green},
    {'valor': 'transferencia', 'label': 'Transferencia', 'icon': Icons.compare_arrows, 'color': Colors.blue},
    {'valor': 'pagomovil', 'label': 'Pago Móvil', 'icon': Icons.smartphone, 'color': Colors.orange},
    {'valor': 'divisas', 'label': 'Divisas (E)', 'icon': Icons.attach_money, 'color': Colors.teal},
    {'valor': 'binance', 'label': 'Binance', 'icon': Icons.currency_bitcoin, 'color': Colors.amber},
    {'valor': 'zelle', 'label': 'Zelle', 'icon': Icons.qr_code, 'color': Colors.purple},
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
      duration: const Duration(milliseconds: 600), // Más suave
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Efecto rebote suave corregido
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn), // Solo al inicio
    );
    _animationController.forward();
    
    // 👈 NUEVO: Intentar cargar la tasa automáticamente
    _cargarTasaBcv();
  }

  // 👈 NUEVO: Método para cargar la tasa del BCV
  Future<void> _cargarTasaBcv() async {
    setState(() => _isLoadingTasa = true);
    final tasa = await ScrapperUtil.getDolarBcv();
    if (mounted && tasa != null) {
      setState(() {
        _tasaController.text = tasa.toStringAsFixed(2);
        _isLoadingTasa = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingTasa = false);
    }
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32), // Igual al otro (32)
          ),
          elevation: 24,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Igual al otro
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85, // Igualado
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
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
                // Header ya no tiene barra azul/decorativa (ELIMINADO)
              
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
                      ),                      const SizedBox(height: 20),
                      
                      // 1. Resumen Cliente
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
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 2. Info Cards
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
                            const Color(0xFFE8573D),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      
                      // 3. Métodos de pago
                      const Text(
                        'Método de pago',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _metodosPago.length,
                        itemBuilder: (context, index) {
                          final metodo = _metodosPago[index];
                          final isSelected = _metodoPago == metodo['valor'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _metodoPago = metodo['valor'];
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? metodo['color'] 
                                    : metodo['color'].withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.transparent 
                                      : metodo['color'].withOpacity(0.3),
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: metodo['color'].withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    metodo['icon'],
                                    color: isSelected ? Colors.white : metodo['color'],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      metodo['label'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? Colors.white : metodo['color'],
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // 2. Campo de referencia condicional
                      if (_metodoPago == 'transferencia' || 
                          _metodoPago == 'pagomovil' || 
                          _metodoPago == 'zelle') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _referenciaController,
                          decoration: InputDecoration(
                            labelText: 'Referencia',
                            hintText: 'Ej: 1234',
                            prefixIcon: const Icon(Icons.confirmation_number_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // 3. Fecha de pago
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
                      
                      // 4. Observaciones
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

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),

                      // 5. Campo de monto
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
                        onChanged: (value) => setState(() {}),
                      ),
                      
                      const SizedBox(height: 16),

                      // 6. Tasa del día
                      TextFormField(
                        controller: _tasaController,
                        readOnly: true,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Tasa del día (BCV)',
                          prefixText: 'Bs. ',
                          suffixIcon: _isLoadingTasa 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _cargarTasaBcv,
                              ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.blue.withOpacity(0.05),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 7. Equivalente en Bolívares
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'EQUIVALENTE EN BOLÍVARES',
                              style: TextStyle(
                                fontSize: 10, 
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                () {
                                  final montoUsd = double.tryParse(_montoController.text) ?? 0.0;
                                  final tasa = double.tryParse(_tasaController.text) ?? 0.0;
                                  return 'Bs. ${(montoUsd * tasa).toStringAsFixed(2)}';
                                }(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (widget.esParcial) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildMontoRapido(0.25)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMontoRapido(0.5)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMontoRapido(0.75)),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),
                      
                      // 👈 INTEGRADO: Resumen final de pago (ESTILO REUTILIZADO)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total a pagar:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '\$${(double.tryParse(_montoController.text) ?? 0.0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total en Bolívares:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    () {
                                      final montoUsd = double.tryParse(_montoController.text) ?? 0.0;
                                      final tasa = double.tryParse(_tasaController.text) ?? 0.0;
                                      return 'Bs. ${(montoUsd * tasa).toStringAsFixed(2)}';
                                    }(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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