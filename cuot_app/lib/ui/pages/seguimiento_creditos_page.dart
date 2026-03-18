import 'package:cuot_app/Model/credito_unico_model.dart';
import 'package:cuot_app/ui/credito_page.dart';
import 'package:cuot_app/widget/seguimiento/dialogo_pago_cuota_completo.dart';
import 'package:cuot_app/widget/seguimiento/tarjeta_credito_unico.dart';
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/Model/pago_model.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/widget/seguimiento/tarjeta_financiamiento.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/widget/dashboard/custom_drawer.dart';

class SeguimientoCreditosPage extends StatefulWidget {
  final String nombreUsuario;

  const SeguimientoCreditosPage({
    super.key,
    required this.nombreUsuario,
  });

  @override
  State<SeguimientoCreditosPage> createState() => _SeguimientoCreditosPageState();
}

class _SeguimientoCreditosPageState extends State<SeguimientoCreditosPage> {
  final CreditService _creditService = CreditService();
  List<dynamic> _financiamientos = [];
  bool _isLoading = true;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 🚀 OPTIMIZACIÓN: Una sola consulta para traer todo (N+1 fixed)
      final rawCredits = await _creditService.getFullCreditsData(widget.nombreUsuario);
      
      final List<dynamic> processedCredits = [];
      
      for (var c in rawCredits) {
        final cliente = c['Clientes'];
        final creditId = c['id'].toString();
        final bool esPagoUnico = c['tipo_credito'] == 'unico';
        
        // Extraer datos de la respuesta anidada (YA NO SON CONSULTAS APARTE)
        final List<dynamic> rawCuotas = c['Cuotas'] ?? [];
        final List<dynamic> rawPagos = c['Pagos'] ?? [];
        
        final List<CuotaPersonalizada> cuotas = rawCuotas.map((cq) => CuotaPersonalizada(
          numeroCuota: cq['numero_cuota'],
          fechaPago: DateTime.parse(cq['fecha_pago']),
          monto: (cq['monto'] as num).toDouble(),
          pagada: cq['pagada'] ?? false,
        )).toList();
        
        // Ordenar cuotas por número (menor a mayor)
        cuotas.sort((a, b) => a.numeroCuota.compareTo(b.numeroCuota));
        
        final List<Pago> pagos = rawPagos.map((p) => Pago(
          id: p['id'].toString(),
          creditoId: creditId,
          numeroCuota: p['numero_cuota'],
          fechaPago: DateTime.parse(p['fecha_pago_real']), 
          monto: (p['monto'] as num).toDouble(),
          fechaPagoReal: DateTime.parse(p['fecha_pago_real']),
          estado: 'pagado',
          metodoPago: p['metodo_pago'] ?? 'efectivo',
        )).toList();
        
        // Ordenar pagos por fecha de pago real
        pagos.sort((a, b) => (a.fechaPagoReal ?? a.fechaPago).compareTo(b.fechaPagoReal ?? b.fechaPago));

        if (esPagoUnico) {
          processedCredits.add(CreditoUnico(
            id: c['id'],
            nombreCliente: cliente['nombre'],
            telefono: cliente['telefono'] ?? '',
            concepto: c['concepto'],
            montoTotal: (c['costo_inversion'] + c['margen_ganancia']).toDouble(),
            fechaLimite: DateTime.parse(c['fecha_vencimiento'] ?? c['fecha_inicio']),
            tipoPago: TipoPagoUnico.unico,
            descripcion: c['concepto'],
            pagosRealizados: pagos,
          ));
        } else {
          processedCredits.add({
            'id': c['id'],
            'nombre': cliente['nombre'],
            'telefono': cliente['telefono'] ?? '',
            'montoCuota': cuotas.isNotEmpty ? cuotas[0].monto : 0.0,
            'totalPagado': pagos.fold<double>(0, (sum, p) => sum + p.monto),
            'totalCredito': (c['costo_inversion'] + c['margen_ganancia']).toDouble(),
            'concepto': c['concepto'],
            'tipo': 'cuotas',
            'cuotas': cuotas,
            'pagos': pagos,
            'pagosParciales': <int, double>{},
          });
        }
      }
      
      setState(() {
        _financiamientos = processedCredits;
        _isLoading = false;
      });
      _actualizarEstados();
    } catch (e) {
      print(' Error cargando créditos optimizados: $e');
      setState(() => _isLoading = false);
    }
  }

  String _filtroEstado = 'todos';
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

  // Función para calcular el estado de créditos en cuotas
  String _calcularEstadoCreditoCuotas(Map<String, dynamic> financiamiento) {
    final hoy = DateTime.now();
    final fechaActual = DateTime(hoy.year, hoy.month, hoy.day);
    
    final totalPagado = financiamiento['totalPagado'] as double;
    final totalCredito = financiamiento['totalCredito'] as double;
    
    if ((totalPagado - totalCredito).abs() < 0.01) {
      return 'Pagado';
    }
    
    final cuotas = financiamiento['cuotas'] as List<CuotaPersonalizada>;
    int cuotasVencidas = 0;
    int cuotasPagadas = 0;
    
    for (var cuota in cuotas) {
      final fechaCuota = DateTime(
        cuota.fechaPago.year,
        cuota.fechaPago.month,
        cuota.fechaPago.day,
      );
      
      final pagoCompleto = cuota.pagada;
      
      if (pagoCompleto) {
        cuotasPagadas++;
        continue;
      }
      
      if (fechaCuota.isBefore(fechaActual)) {
        cuotasVencidas++;
      }
    }
    
    if (cuotasVencidas > 0) {
      return 'Atrasado';
    } else if (cuotasPagadas == cuotas.length) {
      return 'Pagado';
    } else {
      return 'Al día';
    }
  }

  // Actualizar estados de todos los financiamientos
  void _actualizarEstados() {
    for (var financiamiento in _financiamientos) {
      if (financiamiento is Map<String, dynamic>) {
        financiamiento['estado'] = _calcularEstadoCreditoCuotas(financiamiento);
      }
      // CreditoUnico ya tiene su propio cálculo de estado
    }
  }

  List<dynamic> get _financiamientosFiltrados {
    _actualizarEstados();
    
    return _financiamientos.where((f) {
      String nombre = '';
      String telefono = '';
      String estado = '';
      
      if (f is Map<String, dynamic>) {
        nombre = f['nombre'] ?? '';
        telefono = f['telefono'] ?? '';
        estado = f['estado']?.toLowerCase() ?? '';
      } else if (f is CreditoUnico) {
        nombre = f.nombreCliente;
        telefono = f.telefono;
        estado = f.estado.toLowerCase();
      }
      
      final matchesBusqueda = _busqueda.isEmpty ||
          nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
          telefono.contains(_busqueda);
      
      bool matchesEstado = true;
      if (_filtroEstado != 'todos') {
        matchesEstado = estado == _filtroEstado.toLowerCase();
      }
      
      return matchesBusqueda && matchesEstado;
    }).toList();
  }

  Color _getColorParaFiltro(String filtro) {
    switch (filtro.toLowerCase()) {
      case 'todos':
        return AppColors.info;
      case 'al día':
        return AppColors.primaryGreen;
      case 'atrasado':
        return AppColors.error;
      case 'pagado':
        return AppColors.success;
      default:
        return AppColors.mediumGrey;
    }
  }

  double getMontoRestanteCuota(int financiamientoIndex, int numeroCuota) {
    final f = _financiamientos[financiamientoIndex];
    if (f is Map<String, dynamic>) {
      final cuota = (f['cuotas'] as List).firstWhere(
        (c) => c.numeroCuota == numeroCuota,
      );
      
      if (cuota.pagada) return 0.0;
      
      return cuota.monto;
    }
    return 0.0;
  }

  bool esCuotaParcialmentePagada(int financiamientoIndex, int numeroCuota) {
    final f = _financiamientos[financiamientoIndex];
    if (f is Map<String, dynamic>) {
      final cuota = (f['cuotas'] as List).firstWhere(
        (c) => c.numeroCuota == numeroCuota,
      );
      
      // En nuestra lógica actual, si no está pagada pero el monto es menor al original, es parcial.
      // Sin embargo, como el monto en DB es el saldo, necesitamos saber el monto original para estar seguros.
      // Por ahora, una forma simple es verificar si hay pagos registrados para esta cuota pero aún no está marcada como pagada.
      final pagos = f['pagos'] as List<Pago>;
      final tienePagos = pagos.any((p) => p.numeroCuota == numeroCuota);
      
      return tienePagos && !cuota.pagada;
    }
    return false;
  }

  int getCuotasVencidas(int financiamientoIndex) {
    final f = _financiamientos[financiamientoIndex];
    if (f is Map<String, dynamic>) {
      final hoy = DateTime.now();
      final fechaActual = DateTime(hoy.year, hoy.month, hoy.day);
      
      final cuotas = f['cuotas'] as List<CuotaPersonalizada>;
      int vencidas = 0;

      for (var cuota in cuotas) {
        final fechaCuota = DateTime(
          cuota.fechaPago.year,
          cuota.fechaPago.month,
          cuota.fechaPago.day,
        );
        
        final pagada = cuota.pagada;
        
        if (!pagada && fechaCuota.isBefore(fechaActual)) {
          vencidas++;
        }
      }
      
      return vencidas;
    }
    return 0;
  }

  Future<void> _pagarCuotaCompleto(
    int financiamientoIndex,
    int numeroCuota,
    double monto,
    DateTime fechaPago,
    String metodoPago,
    String referencia,
    String observaciones,
    bool aplicarMora,
    double? montoMora,
    bool esPagoParcial,
  ) async {
    final f = _financiamientos[financiamientoIndex];
    if (f is! Map<String, dynamic>) return;

    try {
      // 1. Guardar en base de datos
      await _creditService.savePayment(
        creditId: f['id'].toString(),
        numeroCuota: numeroCuota,
        montoPagado: monto,
        fechaPago: fechaPago,
        metodoPago: metodoPago,
        referencia: referencia,
        observaciones: observaciones,
        esPagoParcial: esPagoParcial,
      );

      // 2. Refrescar datos desde la base de datos
      await _loadData();

      String mensaje = esPagoParcial
          ? '✅ Pago parcial de cuota #$numeroCuota registrado'
          : '✅ Pago de cuota #$numeroCuota registrado';
      
      if (aplicarMora && montoMora != null && montoMora > 0) {
        mensaje += ' (incluye mora de \$${montoMora.toStringAsFixed(2)})';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al registrar pago: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pagarCreditoUnico(CreditoUnico credito, Pago pago) async {
    try {
      // 1. Guardar en base de datos
      await _creditService.savePayment(
        creditId: credito.id,
        numeroCuota: 1, // Créditos únicos siempre usan la cuota 1
        montoPagado: pago.monto,
        fechaPago: pago.fechaPago,
        metodoPago: pago.metodoPago ?? 'efectivo',
        referencia: '',
        esPagoParcial: pago.monto < credito.montoTotal, // Simplificación
      );

      // 2. Refrescar datos
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Pago de \$${pago.monto.toStringAsFixed(2)} registrado'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al registrar pago: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildFiltros() {
    final filtros = ['todos', 'al día', 'atrasado', 'pagado'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filtros.map((filtro) {
          final isSelected = _filtroEstado == filtro;
          final color = _getColorParaFiltro(filtro);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                filtro == 'todos' ? 'Todos' : filtro,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selectedColor: color,
              checkmarkColor: Colors.white,
              backgroundColor: color.withOpacity(0.1),
              side: BorderSide(
                color: isSelected ? Colors.transparent : color.withOpacity(0.5),
              ),
              onSelected: (selected) {
                setState(() {
                  _filtroEstado = filtro;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        nombre_usuario: widget.nombreUsuario,
        ventanaActiva: 'Cuotas Personales',
      ),
      appBar: AppBar(
        title: const Text('Seguimiento de Créditos'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _busqueda = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _busqueda = '';
                          });
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
          _buildFiltros(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _financiamientosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.mediumGrey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron resultados',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: _financiamientosFiltrados.length,
                    itemBuilder: (context, index) {
                      final item = _financiamientosFiltrados[index];
                      final originalIndex = _financiamientos.indexOf(item);
                      
                      if (item is CreditoUnico) {
                        return TarjetaCreditoUnico(
                          credito: item,
                          onPagoRealizado: (pago) => _pagarCreditoUnico(item, pago),
                          onVerDetalle: () {
                            // Navegar a detalle del crédito único
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ver detalle de ${item.nombreCliente}'),
                                backgroundColor: AppColors.info,
                              ),
                            );
                          },
                        );
                      } else if (item is Map<String, dynamic>) {
                        final totalCuotas = item['cuotas'].length;
                        final cuotasPagadas = item['pagos'].length;
                        final cuotasVencidas = getCuotasVencidas(originalIndex);
                        
                        return TarjetaFinanciamiento(
                          nombreCliente: item['nombre'],
                          telefono: item['telefono'],
                          estado: item['estado'] ?? 'Pendiente',
                          montoCuota: item['montoCuota'],
                          totalPagado: item['totalPagado'],
                          totalPendiente: item['totalPendiente'] ?? 
                              (item['totalCredito'] - item['totalPagado']),
                          progreso: item['progreso'] ?? 
                              (item['totalPagado'] / item['totalCredito']),
                          cuotas: item['cuotas'],
                          pagos: item['pagos'],
                          cuotasVencidas: cuotasVencidas,
                          concepto: item['concepto'] ?? 'Sin concepto',
                          totalCredito: item['totalCredito'] ?? 0.0,
                          onCuotaTap: (numeroCuota) {
                            final cuota = (item['cuotas'] as List).firstWhere(
                              (c) => c.numeroCuota == numeroCuota,
                            );
                            
                            final montoRestante = getMontoRestanteCuota(
                              originalIndex,
                              numeroCuota,
                            );
                            
                            if (montoRestante <= 0) return;
                            
                            final esPagoParcialPrevio = esCuotaParcialmentePagada(
                              originalIndex,
                              numeroCuota,
                            );
                            
                            showDialog(
                              context: context,
                              builder: (context) => DialogoPagoCuotaCompleto(
                                numeroCuota: numeroCuota,
                                monto: cuota.monto,
                                montoRestante: montoRestante,
                                fechaVencimiento: cuota.fechaPago,
                                nombreCliente: item['nombre'],
                                concepto: item['concepto'] ?? 'Préstamo',
                                montoPagadoHastaAhora: item['totalPagado'],
                                totalCredito: item['totalCredito'] ?? 500.00,
                                totalCuotas: totalCuotas,
                                cuotasPagadas: cuotasPagadas,
                                esPagoParcial: esPagoParcialPrevio,
                                onPagar: (
                                  monto,
                                  fechaPago,
                                  metodoPago,
                                  referencia,
                                  observaciones,
                                  aplicarMora,
                                  montoMora,
                                  esPagoParcial,
                                ) {
                                  _pagarCuotaCompleto(
                                    originalIndex,
                                    numeroCuota,
                                    monto,
                                    fechaPago,
                                    metodoPago,
                                    referencia,
                                    observaciones,
                                    aplicarMora,
                                    montoMora,
                                    esPagoParcial,
                                  );
                                },
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreditoPage(nombreUsuario: widget.nombreUsuario)),
          );
        },
        tooltip: 'Nuevo crédito',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }
}