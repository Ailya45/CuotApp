// 📝 VISTA 2: Formulario para pago único
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/utils/validators.dart';
import 'package:cuot_app/widget/creditos/custom_date_picker.dart';
import 'package:cuot_app/widget/creditos/factura_uploader.dart';
import 'package:cuot_app/utils/date_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 👈 NUEVO

class FormularioPagounico extends StatefulWidget {
  final Function(Credito) onCreditoActualizado;
  final Function() onGuardar;

  const FormularioPagounico({
    super.key,
    required this.onCreditoActualizado,
    required this.onGuardar,
  });

  @override
  State<FormularioPagounico> createState() => _FormularioPagounicoState();
}

class _FormularioPagounicoState extends State<FormularioPagounico> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _conceptoController = TextEditingController();
  final _inversionController = TextEditingController();
  final _gananciaController = TextEditingController();
  final _clienteController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  // Variables de estado
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaLimite = DateTime.now().add(const Duration(days: 30));
  File? _facturaSeleccionada;
  bool _mostrarTelefono = false; // 👈 NUEVO: Estado del checkbox
  
  // Valores calculados
  double get _inversion => double.tryParse(_inversionController.text) ?? 0;
  double get _ganancia => double.tryParse(_gananciaController.text) ?? 0;
  double get _precioTotal => _inversion + _ganancia;
  

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📌 1. CONCEPTO/PRODUCTO
            _buildSeccionTitulo('Articulo', Icons.shopping_bag),
            const SizedBox(height: 8),
            TextFormField(
              controller: _conceptoController,
              decoration: _buildInputDecoration(
                label: 'Ej: Producto, servicio, etc.',
                icon: Icons.description,
              ),
              validator: (v) => Validators.required(v, 'Concepto'),
              onChanged: _actualizarCredito,
            ),
            const SizedBox(height: 20),

            // 📌 2. INVERSIÓN Y GANANCIA - CORREGIDO
                        // 📌 2. INVERSIÓN Y GANANCIA - CON INVERSIÓN MÁS GRANDE
            Row(
              children: [
                // INVERSIÓN - OCUPA MÁS ESPACIO (flex: 2)
                Expanded(
                  flex: 2, // 👈 VALOR MÁS ALTO = MÁS ESPACIO
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSeccionTitulo('Inversión/Coste', Icons.attach_money),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _inversionController,
                        decoration: _buildInputDecoration(
                          label: 'Monto invertido',
                          icon: Icons.money,
                          prefix: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.positiveNumber(v, 'Inversión'),
                        onChanged: _actualizarCredito,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12), // Espacio entre columnas
                
                // GANANCIA - OCUPA MENOS ESPACIO (flex: 1)
                Expanded(
                  flex: 1, // 👈 VALOR MÁS BAJO = MENOS ESPACIO
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSeccionTitulo('Ganancia', Icons.trending_up),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _gananciaController,
                        decoration: _buildInputDecoration(
                          label: '',
                          icon: Icons.add_chart,
                          prefix: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.positiveNumber(v, 'Ganancia'),
                        onChanged: _actualizarCredito,
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // 📌 4. FECHAS
            _buildSeccionTitulo('Fechas de pago', Icons.date_range),
            const SizedBox(height: 8),
            
            // Fecha de inicio
            Row(
              spacing: 5,
              children: [
                Expanded( child:
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color.fromARGB(255, 27, 19, 19)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.play_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text('Inicio de pago:'),
                          const Spacer(),
                         /* Text(
                            _formatearFecha(_fechaInicio),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),*/
                        ],
                      ),
                      CustomDatePicker(
                        selectedDate: _fechaInicio,
                        onDateSelected: (date) {
                          setState(() => _fechaInicio = date);
                          _actualizarCredito();
                        },
                        label: 'Seleccionar fecha',
                      ),
                      
                    ],
                    
                    
                  ),
                  
                  
                ),
                ),
 
                // Fecha límite
                Expanded(
                   child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stop_circle, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Text('Fecha límite:'),
                          const Spacer(),
                          /*Text(
                            _formatearFecha(_fechaLimite),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),*/
                        ],
                      ),
                      
                      CustomDatePicker(
                        selectedDate: _fechaLimite,
                        onDateSelected: (date) {
                          setState(() => _fechaLimite = date);
                          _actualizarCredito();
                        },
                        label: 'Seleccionar fecha límite',
                      ),
                    ],
                  ),
                ),
                )
              ],
              
            ),
            const SizedBox(height: 20),

            // 📌 6. RESUMEN DE VALORES
            _buildResumenCard(),
          
            const SizedBox(height: 20),

            // 📌 7. CLIENTE
            _buildSeccionTitulo('Cliente', Icons.person),
            const SizedBox(height: 8),
            TextFormField(
              controller: _clienteController,
              decoration: _buildInputDecoration(
                label: 'Nombre completo del cliente',
                icon: Icons.person_outline,
              ),
              validator: (v) => Validators.required(v, 'Cliente'),
              onChanged: _actualizarCredito,
            ),
            const SizedBox(height: 20),
            
            // 📌 7.5 TELEFONO OPCIONAL
            CheckboxListTile(
              title: const Text('Agregar número de teléfono'),
              value: _mostrarTelefono,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (val) {
                setState(() => _mostrarTelefono = val ?? false);
                _actualizarCredito();
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            if (_mostrarTelefono) ...[
              _buildSeccionTitulo('Teléfono', Icons.phone),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telefonoController,
                decoration: _buildInputDecoration(
                  label: 'Número de WhatsApp',
                  icon: Icons.phone_android,
                  prefix: '+',
                  suffixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                ),
                keyboardType: TextInputType.phone,
                onChanged: _actualizarCredito,
              ),
            ],

             const SizedBox(height: 20),
            
            // 📌 5. FACTURA (OPCIONAL)
            _buildSeccionTitulo('Factura (Opcional)', Icons.receipt),
            const SizedBox(height: 8),
            FacturaUploader(
              onFacturaSeleccionada: (File? archivo) {
                setState(() {
                  _facturaSeleccionada = archivo;
                });
                _actualizarCredito();
              },
            ),
            const SizedBox(height: 20),

            // 📌 8. INDICADOR DE FACTURA (si hay)
            if (_facturaSeleccionada != null) _buildFacturaIndicator(),
            const SizedBox(height: 24),

            // 📌 9. BOTÓN GUARDAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _guardarCredito,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text(
                      'GUARDAR PAGO ÚNICO',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📌 TARJETA DE RESUMEN
  Widget _buildResumenCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildInfoRow('Precio total:', '\$$_precioTotal'),
            _buildInfoRow(
              'Duración:', 
              DateUt.formatearDuracion(_fechaInicio, _fechaLimite),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estado:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PAGO ÚNICO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📌 INDICADOR DE FACTURA ADJUNTA
  Widget _buildFacturaIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Factura adjunta:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _facturaSeleccionada!.path.split('/').last,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              setState(() {
                _facturaSeleccionada = null;
              });
              _actualizarCredito();
            },
          ),
        ],
      ),
    );
  }

  /// 📌 ACTUALIZAR CRÉDITO (callback)
  void _actualizarCredito([_]) {
    if (_formKey.currentState?.validate() ?? false) {
      final credito = Credito(
        concepto: _conceptoController.text,
        costeInversion: _inversion,
        margenGanancia: _ganancia,
        fechaInicio: _fechaInicio,
        modalidadPago: ModalidadPago.mensual,
        nombreCliente: _clienteController.text,
        telefono: _mostrarTelefono ? _telefonoController.text : '', // 👈 Condicional
        numeroCuotas: 1,
        facturaPath: _facturaSeleccionada?.path,
        nombreFactura: _facturaSeleccionada?.path.split('/').last,
        fechaLimite: _fechaLimite, // 👈 Pasar fecha límite para pago único
      );
      widget.onCreditoActualizado(credito);
    }
  }

  /// 📌 GUARDAR CRÉDITO (con validaciones)
  void _guardarCredito() {
    // Validar formulario básico
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Validar fechas
    if (_fechaLimite.isBefore(_fechaInicio)) {
      _mostrarError(
        'Fechas inválidas',
        'La fecha límite no puede ser anterior a la fecha de inicio',
      );
      return;
    }

    // Diálogo para factura opcional
    if (_facturaSeleccionada == null) {
      _mostrarDialogoFacturaOpcional();
    } else {
      widget.onGuardar();
    }
  }

  /// 📌 MOSTRAR ERROR
  void _mostrarError(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }

  /// 📌 DIÁLOGO PARA FACTURA OPCIONAL
  void _mostrarDialogoFacturaOpcional() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Adjuntar factura?'),
        content: const Text(
          'No has adjuntado ninguna factura. ¿Deseas continuar sin factura?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ADJUNTAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _actualizarCredito(); // 👈 Aseguramos actualización
              widget.onGuardar();
            },
            child: const Text('CONTINUAR'),
          ),
        ],
      ),
    );
  }

  /// 📌 MÉTODOS DE UTILIDAD
  Widget _buildSeccionTitulo(String titulo, IconData icono) {
    return Row(
      children: [
        Icon(icono, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    IconData? icon,
    String? prefix,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
           '${fecha.month.toString().padLeft(2, '0')}/'
           '${fecha.year}';
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _inversionController.dispose();
    _gananciaController.dispose();
    _clienteController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
}