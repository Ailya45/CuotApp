import 'package:cuot_app/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:cuot_app/widget/creditos/custom_date_picker.dart';
import 'package:intl/intl.dart';

class FormaPagoForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onFormaPagoChanged;
  final double montoTotal;

  const FormaPagoForm({
    super.key,
    required this.onFormaPagoChanged,
    required this.montoTotal,
  });

  @override
  State<FormaPagoForm> createState() => _FormaPagoFormState();
}

class _FormaPagoFormState extends State<FormaPagoForm> {
  String _formaPago = 'semanal';
  int _numeroCuotas = 1;
  double _interes = 0;
  double _cuotaInicial = 0;
  final _cuotaInicialController = TextEditingController();
  DateTime _fechaPrimerPago = DateTime.now().add(const Duration(days: 7));

  final List<String> _opcionesPago = ['semanal', 'quincenal', 'mensual'];

  // 🔧 LÓGICA: Calcular saldo a financiar después de cuota inicial
  double get _saldoPendiente {
    return widget.montoTotal - _cuotaInicial;
  }

  // 🔧 LÓGICA: Calcular monto por cuota
  double get _montoPorCuota {
    if (_numeroCuotas <= 0) return 0;
    return (_saldoPendiente * (1 + _interes / 100)) / _numeroCuotas;
  }

  // 🔧 LÓGICA: Calcular fecha estimada de primera cuota
  String get _fechaEstimada {
    return DateFormat('dd/MM/yyyy').format(_fechaPrimerPago);
  }

  // 🔧 LÓGICA: Notificar cambios
  void _notificarCambio() {
    widget.onFormaPagoChanged({
      'formaPago': _formaPago,
      'numeroCuotas': _numeroCuotas,
      'interes': _interes,
      'cuotaInicial': _cuotaInicial,
      'saldoPendiente': _saldoPendiente,
      'montoPorCuota': _montoPorCuota,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Forma de Pago',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),

        // Cuota Inicial
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _cuotaInicialController,
                  decoration: InputDecoration(
                    labelText: 'Cuota Inicial (opcional)',
                    prefixIcon: Icon(Icons.payments),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _cuotaInicial = double.tryParse(value) ?? 0;
                      if (_cuotaInicial > widget.montoTotal) {
                        _cuotaInicial = widget.montoTotal;
                        _cuotaInicialController.text = _cuotaInicial.toString();
                      }
                      _notificarCambio();
                    });
                  },
                ),
                SizedBox(height: 8),
                Text(
                  'Saldo a financiar: \$${Formatters.formatCurrency(_saldoPendiente)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),

        // Selección de forma de pago
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Período de Pago', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ..._opcionesPago.map((opcion) {
                  return RadioListTile<String>(
                    title: Text(StringExtension(opcion).capitalize()),
                    value: opcion,
                    groupValue: _formaPago,
                    onChanged: (value) {
                      setState(() {
                        _formaPago = value!;
                        // Ajustar fecha sugerida según cambio de frecuencia
                        final now = DateTime.now();
                        if (_formaPago == 'semanal') {
                          _fechaPrimerPago = now.add(const Duration(days: 7));
                        } else if (_formaPago == 'quincenal') {
                          _fechaPrimerPago = now.add(const Duration(days: 15));
                        } else if (_formaPago == 'mensual') {
                          _fechaPrimerPago = now.add(const Duration(days: 30));
                        }
                        _notificarCambio();
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ),

        // Fecha de primer pago
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fecha del primer pago', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                CustomDatePicker(
                  selectedDate: _fechaPrimerPago,
                  onDateSelected: (date) {
                    setState(() {
                      _fechaPrimerPago = date;
                      _notificarCambio();
                    });
                  },
                  label: 'Seleccionar fecha',
                ),
              ],
            ),
          ),
        ),

        // Número de cuotas e interés
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Número de Cuotas', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle),
                                onPressed: _numeroCuotas > 1 ? () {
                                  setState(() {
                                    _numeroCuotas--;
                                    _notificarCambio();
                                  });
                                } : null,
                              ),
                              Expanded(
                                child: Text(
                                  '$_numeroCuotas',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle),
                                onPressed: () {
                                  setState(() {
                                    _numeroCuotas++;
                                    _notificarCambio();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Interés %', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          TextFormField(
                            initialValue: _interes.toString(),
                            decoration: InputDecoration(
                              suffixText: '%',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _interes = double.tryParse(value) ?? 0;
                                _notificarCambio();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Resumen de pagos
        Card(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cuota por período:'),
                    Text(
                      '\$${Formatters.formatCurrency(_montoPorCuota)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Primera cuota estimada:'),
                    Text(_fechaEstimada, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total a pagar:'),
                    Text(
                      '\$${Formatters.formatCurrency(_saldoPendiente + (_saldoPendiente * _interes / 100))}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cuotaInicialController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}