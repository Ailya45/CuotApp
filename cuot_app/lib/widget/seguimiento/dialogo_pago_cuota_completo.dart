// lib/widget/seguimiento/dialogo_pago_cuota_completo.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:intl/intl.dart';

class DialogoPagoCuotaCompleto extends StatefulWidget {
  final int numeroCuota;
  final double monto;
  final double montoRestante; // 👈 NUEVO: monto que falta por pagar de esta cuota
  final DateTime fechaVencimiento;
  final String nombreCliente;
  final String concepto;
  final double montoPagadoHastaAhora;
  final double totalCredito;
  final int totalCuotas;
  final int cuotasPagadas;
  final bool esPagoParcial; // 👈 NUEVO: indica si es un pago parcial de una cuota
  final Function(
    double monto,
    DateTime fechaPago,
    String metodoPago,
    String referencia,
    String observaciones,
    bool aplicarMora,
    double? montoMora,
    bool esPagoParcial, // 👈 NUEVO: para indicar si el pago es parcial
  ) onPagar;

  const DialogoPagoCuotaCompleto({
    super.key,
    required this.numeroCuota,
    required this.monto,
    required this.montoRestante,
    required this.fechaVencimiento,
    required this.nombreCliente,
    required this.concepto,
    required this.montoPagadoHastaAhora,
    required this.totalCredito,
    required this.totalCuotas,
    required this.cuotasPagadas,
    this.esPagoParcial = false,
    required this.onPagar,
  });

  @override
  State<DialogoPagoCuotaCompleto> createState() => _DialogoPagoCuotaCompletoState();
}

class _DialogoPagoCuotaCompletoState extends State<DialogoPagoCuotaCompleto> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _montoController;
  late TextEditingController _tasaController; // 👈 NUEVO
  late TextEditingController _referenciaController;
  late TextEditingController _observacionesController;
  
  DateTime _fechaPago = DateTime.now();
  String _metodoPago = 'efectivo';
  late String _tipoPago;
  bool _aplicarMora = false;
  double _montoMora = 0.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _metodosPago = [
    {'valor': 'efectivo', 'label': 'Efectivo', 'icon': Icons.money, 'color': Colors.green},
    {'valor': 'transferencia', 'label': 'Transferencia', 'icon': Icons.compare_arrows, 'color': Colors.blue},
    {'valor': 'divisaefectivo', 'label': 'Divisas en Efectivo', 'icon': Icons.money, 'color': Colors.purple},
    {'valor': 'zelle', 'label': 'Zelle', 'icon': Icons.qr_code, 'color': Colors.red},
    {'valor': 'pagomovil', 'label': 'Pago Movil', 'icon': Icons.account_balance, 'color': Colors.orange},
    {'valor': 'binance', 'label': 'binance', 'icon': Icons.currency_bitcoin, 'color': Colors.brown},
  ];

  // Calcular días de atraso
  int get _diasAtraso {
    final hoy = DateTime.now();
    final fechaVencimiento = DateTime(
      widget.fechaVencimiento.year,
      widget.fechaVencimiento.month,
      widget.fechaVencimiento.day,
    );
    final fechaActual = DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    );
    
    if (fechaActual.isAfter(fechaVencimiento)) {
      return fechaActual.difference(fechaVencimiento).inDays;
    }
    return 0;
  }

  // Calcular mora
  double get _moraCalculada {
    if (_diasAtraso > 0) {
      const tasaMoraDiaria = 0.005; // 0.5% por día
      return widget.monto * tasaMoraDiaria * _diasAtraso;
    }
    return 0.0;
  }

  // Total a pagar (CORREGIDO para pagos parciales)
  double get _totalAPagar {
    double total = 0.0;
    
    if (_tipoPago == 'completo') {
      total = widget.montoRestante; // 👈 Usar montoRestante en lugar de monto
    } else {
      total = double.tryParse(_montoController.text) ?? 0.0;
    }
    
    if (_aplicarMora && _diasAtraso > 0) {
      final moraAAplicar = _montoMora > 0 ? _montoMora : _moraCalculada;
      total += moraAAplicar;
    }
    
    return total;
  }

  // 👇 NUEVO: Monto que quedará pendiente después de este pago
  double get _montoPendienteDespues {
    if (_tipoPago == 'completo') return 0.0;
    
    final montoAPagar = double.tryParse(_montoController.text) ?? 0.0;
    return widget.montoRestante - montoAPagar;
  }

  double get _saldoRestanteCredito {
    return widget.totalCredito - (widget.montoPagadoHastaAhora + _totalAPagar);
  }

  // Validar monto de mora
  void _validarMontoMora(String value) {
    final nuevoMonto = double.tryParse(value) ?? 0;
    if (nuevoMonto >= 0) {
      setState(() {
        _montoMora = nuevoMonto;
      });
    }
  }

  // Formatear fecha larga
  String _formatearFechaLarga(DateTime fecha) {
    final dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    
    final diaSemana = dias[fecha.weekday - 1];
    final dia = fecha.day;
    final mes = meses[fecha.month - 1];
    final ano = fecha.year;
    
    return '$diaSemana, $dia de $mes de $ano';
  }

  @override
  void initState() {
    super.initState();
    _tipoPago = widget.esPagoParcial ? 'parcial' : 'completo';
    _montoController = TextEditingController(
      text: widget.montoRestante.toStringAsFixed(2), // 👈 Usar montoRestante
    );
    _tasaController = TextEditingController(); // 👈 NUEVO
    _referenciaController = TextEditingController();
    _observacionesController = TextEditingController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        elevation: 24,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header decorativo
              Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.info,
                      AppColors.primaryGreen,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título con icono animado
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.success,
                                      AppColors.success.withOpacity(0.7),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.payment,
                                  color: Colors.white,
                                  size: 45,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Registrar Pago',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  'Cuota #${widget.numeroCuota} de ${widget.totalCuotas}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (widget.esPagoParcial) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Pago Parcial - Resta: \$${widget.montoRestante.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Tarjeta de información del cliente
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.info.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: AppColors.info.withOpacity(0.1),
                                child: Text(
                                  widget.nombreCliente[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.nombreCliente,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.concepto,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.mediumGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Grid de información de la cuota
                        Row(
                          children: [
                            _buildInfoCard(
                              'Monto Total',
                              '\$${widget.monto.toStringAsFixed(2)}',
                              AppColors.primaryGreen,
                              Icons.payments,
                            ),
                            const SizedBox(width: 12),
                            _buildInfoCard(
                              'Restante',
                              '\$${widget.montoRestante.toStringAsFixed(2)}',
                              AppColors.warning,
                              Icons.pending,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            _buildInfoCard(
                              'Vencimiento',
                              DateFormat('dd/MM/yyyy').format(widget.fechaVencimiento),
                              _diasAtraso > 0 ? AppColors.error : AppColors.info,
                              Icons.event,
                            ),
                            const SizedBox(width: 12),
                            _buildInfoCard(
                              'Atraso',
                              _diasAtraso > 0 
                                  ? '$_diasAtraso día${_diasAtraso != 1 ? 's' : ''}' 
                                  : 'Al día',
                              _diasAtraso > 0 ? AppColors.error : AppColors.success,
                              Icons.access_time,
                            ),
                          ],
                        ),
                        
                        // Alerta de mora si está atrasado
                        if (_diasAtraso > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      color: AppColors.error,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cuota vencida',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.error,
                                            ),
                                          ),
                                          Text(
                                            'Atraso de $_diasAtraso día${_diasAtraso != 1 ? 's' : ''}. '
                                            'Mora sugerida: \$${_moraCalculada.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _aplicarMora,
                                      onChanged: (value) {
                                        setState(() {
                                          _aplicarMora = value;
                                          if (value && _montoMora == 0) {
                                            _montoMora = _moraCalculada;
                                          }
                                        });
                                      },
                                      activeColor: AppColors.error,
                                    ),
                                  ],
                                ),
                                
                                if (_aplicarMora) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: _montoMora.toStringAsFixed(2),
                                          decoration: InputDecoration(
                                            labelText: 'Monto de mora',
                                            prefixText: '\$ ',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: _validarMontoMora,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: 'Mora sugerida: \$${_moraCalculada.toStringAsFixed(2)}',
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.info.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.info_outline,
                                            size: 18,
                                            color: AppColors.info,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Tipo de pago
                        const Text(
                          'Tipo de pago',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTipoPagoButton(
                                'Completo',
                                'completo',
                                Icons.check_circle,
                                widget.montoRestante, // 👈 Pasar montoRestante
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTipoPagoButton(
                                'Parcial',
                                'parcial',
                                Icons.payment,
                                widget.montoRestante,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Monto (editable si es parcial)
                        TextFormField(
                          controller: _montoController,
                          enabled: _tipoPago == 'parcial',
                          decoration: InputDecoration(
                            labelText: _tipoPago == 'completo' 
                                ? 'Monto a pagar' 
                                : 'Monto a pagar (parcial)',
                            prefixText: '\$ ',
                            prefixStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: _tipoPago == 'completo'
                                ? Colors.grey.shade100
                                : Colors.grey.shade50,
                            suffixIcon: _tipoPago == 'completo'
                                ? Icon(
                                    Icons.lock,
                                    color: Colors.grey.shade400,
                                  )
                                : null,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {}); // Forzar reconstrucción para actualizar Bs.
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa el monto';
                            }
                            final monto = double.tryParse(value);
                            if (monto == null || monto <= 0) {
                              return 'Monto inválido';
                            }
                            if (_tipoPago == 'completo' && (monto - widget.montoRestante).abs() > 0.01) {
                              return 'El monto debe ser \$${widget.montoRestante.toStringAsFixed(2)}';
                            }
                            if (_tipoPago == 'parcial' && monto > widget.montoRestante) {
                              return 'No puede exceder el restante de \$${widget.montoRestante.toStringAsFixed(2)}';
                            }
                            return null;
                          },
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
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                onChanged: (value) {
                                  setState(() {}); // Actualizar vista al cambiar tasa
                                },
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
                        
                        // 👇 NUEVO: Mostrar cuánto quedará pendiente después del pago parcial
                        if (_tipoPago == 'parcial' && _montoPendienteDespues > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.info,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Quedará pendiente: \$${_montoPendienteDespues.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Selector de método de pago
                        const Text(
                          'Método de pago',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _metodosPago.map((metodo) {
                              final isSelected = _metodoPago == metodo['valor'];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _metodoPago = metodo['valor'];
                                  });
                                },
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 100) / 3,
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
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : metodo['color'].withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        metodo['icon'],
                                        color: isSelected ? Colors.white : metodo['color'],
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        metodo['label'],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected ? Colors.white : metodo['color'],
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        // Referencia (para transferencias, cheques, etc)
                        if (_metodoPago != 'efectivo' && _metodoPago != 'divisaefectivo') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _referenciaController,
                            decoration: InputDecoration(
                              labelText: 'Número de referencia',
                              prefixIcon: Icon(
                                Icons.receipt,
                                color: AppColors.mediumGrey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ],
                        
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
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    primaryColor: AppColors.success,
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.success,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                _fechaPago = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha de pago',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mediumGrey,
                                      ),
                                    ),
                                    Text(
                                      _formatearFechaLarga(_fechaPago),
                                      style: const TextStyle(
                                        fontSize: 15,
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
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Resumen de pago
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
                                    '\$${_totalAPagar.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Pagado hasta ahora:',
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '\$${widget.montoPagadoHastaAhora.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Saldo restante:',
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '\$${_saldoRestanteCredito.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _saldoRestanteCredito > 0 
                                          ? AppColors.warning 
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'CANCELAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final monto = double.parse(_montoController.text);
                                    final esPagoParcial = _tipoPago == 'parcial' && 
                                        (monto < widget.montoRestante);
                                    
                                    widget.onPagar(
                                      monto,
                                      _fechaPago,
                                      _metodoPago,
                                      _referenciaController.text,
                                      _observacionesController.text,
                                      _aplicarMora,
                                      _aplicarMora ? _montoMora : null,
                                      esPagoParcial,
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'CONFIRMAR PAGO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String valor, Color color, IconData icono) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icono, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoPagoButton(String label, String valor, IconData icono, double montoRestante) {
    final isSelected = _tipoPago == valor;
    final bool deshabilitado = valor == 'completo' && montoRestante <= 0;
    
    return Opacity(
      opacity: deshabilitado ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: deshabilitado
            ? null
            : () {
                setState(() {
                  _tipoPago = valor;
                  if (valor == 'completo') {
                    _montoController.text = montoRestante.toStringAsFixed(2);
                  }
                });
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected && !deshabilitado
                ? LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.7),
                    ],
                  )
                : null,
            color: isSelected && !deshabilitado ? null : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected && !deshabilitado
                  ? Colors.transparent
                  : AppColors.primaryGreen.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 18,
                color: isSelected && !deshabilitado
                    ? Colors.white
                    : AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected && !deshabilitado
                      ? Colors.white
                      : AppColors.primaryGreen,
                  fontWeight: isSelected && !deshabilitado
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}