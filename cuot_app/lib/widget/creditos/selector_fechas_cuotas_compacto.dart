// lib/widget/creditos/selector_fechas_cuotas_compacto.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/widget/creditos/tarjeta_cuota_compacta.dart';

class SelectorFechasCuotasCompacto extends StatefulWidget {
  final int numeroCuotas;
  final DateTime fechaInicio;
  final double montoPorCuota;
  final double precioTotalEsperado;
  final List<CuotaPersonalizada>? cuotasIniciales;
  final Function(List<CuotaPersonalizada>) onFechasSeleccionadas;

  const SelectorFechasCuotasCompacto({
    super.key,
    required this.numeroCuotas,
    required this.fechaInicio,
    required this.montoPorCuota,
    required this.precioTotalEsperado,
    this.cuotasIniciales,
    required this.onFechasSeleccionadas,
  });

  @override
  State<SelectorFechasCuotasCompacto> createState() =>
      _SelectorFechasCuotasCompactoState();
}

class _SelectorFechasCuotasCompactoState
    extends State<SelectorFechasCuotasCompacto> {
  late List<CuotaPersonalizada> _cuotas;
  late List<bool> _cuotasModificadas;
  final ScrollController _scrollController = ScrollController();

  // 👇 NUEVAS PROPIEDADES PARA VALIDACIÓN
  double get _totalCuotas => CuotaPersonalizada.calcularTotalCuotas(_cuotas);
  double get _diferencia => CuotaPersonalizada.obtenerDiferenciaTotal(
      _cuotas, widget.precioTotalEsperado);
  bool get _totalValido => CuotaPersonalizada.validarTotalCuotas(
      _cuotas, widget.precioTotalEsperado);

  @override
  void initState() {
    super.initState();
    _inicializarCuotas();
  }

  void _inicializarCuotas() {
    _cuotas = [];
    _cuotasModificadas = List.generate(widget.numeroCuotas, (index) => false);

    if (widget.cuotasIniciales != null && widget.cuotasIniciales!.isNotEmpty) {
      if (widget.cuotasIniciales!.length == widget.numeroCuotas) {
        // Cargar exactamente las iniciales
        for (var c in widget.cuotasIniciales!) {
          _cuotas.add(c.copyWith());
        }
      } else {
        // Cargar pagadas + generar el resto para cuadrar el nuevo número de cuotas
        final pagadas = widget.cuotasIniciales!.where((c) => c.pagada).toList();
        final montoPagado = CuotaPersonalizada.calcularTotalCuotas(pagadas);
        final int cuotasPendientesCount = widget.numeroCuotas - pagadas.length;
        final double saldoPendiente = widget.precioTotalEsperado - montoPagado;
        final double montoPendienteAvg = cuotasPendientesCount > 0
            ? saldoPendiente / cuotasPendientesCount
            : 0;

        for (int i = 0; i < widget.numeroCuotas; i++) {
          if (i < pagadas.length) {
            _cuotas.add(pagadas[i].copyWith(numeroCuota: i + 1));
          } else {
            _cuotas.add(CuotaPersonalizada(
              numeroCuota: i + 1,
              fechaPago: widget.fechaInicio.add(Duration(days: 30 * (i + 1))),
              monto: montoPendienteAvg,
            ));
          }
        }
      }
    } else {
      for (int i = 0; i < widget.numeroCuotas; i++) {
        _cuotas.add(CuotaPersonalizada(
          numeroCuota: i + 1,
          fechaPago: widget.fechaInicio.add(Duration(days: 30 * (i + 1))),
          monto: widget.montoPorCuota,
        ));
      }
    }
  }

  void _actualizarCuota(CuotaPersonalizada cuotaEditada) {
    setState(() {
      final index =
          _cuotas.indexWhere((c) => c.numeroCuota == cuotaEditada.numeroCuota);
      if (index != -1) {
        final cuotaOriginal = _cuotas[index];
        final huboCambio = cuotaOriginal.fechaPago != cuotaEditada.fechaPago ||
            (cuotaOriginal.monto - cuotaEditada.monto).abs() > 0.01;

        _cuotas[index] = cuotaEditada;

        if (huboCambio) {
          _cuotasModificadas[index] = true;
        }
      }
    });
    widget.onFechasSeleccionadas(_cuotas);
  }

  void _resetearCuota(int index) {
    if (_cuotas[index].pagada) return; // No resetear cuotas pagadas
    setState(() {
      _cuotas[index] = CuotaPersonalizada(
        numeroCuota: index + 1,
        fechaPago: widget.fechaInicio.add(Duration(days: 30 * (index))),
        monto: widget.montoPorCuota,
      );
      _cuotasModificadas[index] = false;
    });
    widget.onFechasSeleccionadas(_cuotas);
  }

  void _resetearTodas() {
    setState(() {
      for (int i = 0; i < _cuotas.length; i++) {
        if (!_cuotas[i].pagada) {
          _cuotas[i] = CuotaPersonalizada(
            numeroCuota: i + 1,
            fechaPago: widget.fechaInicio.add(Duration(days: 30 * (i + 1))),
            monto: widget.montoPorCuota,
          );
          _cuotasModificadas[i] = false;
        }
      }
    });
    widget.onFechasSeleccionadas(_cuotas);
  }

  // 👇 NUEVO: Método para distribuir la diferencia automáticamente respetando las pagadas
  void _distribuirDiferencia() {
    if (_cuotas.isEmpty) return;

    setState(() {
      final diferencia = _diferencia;
      if (diferencia.abs() < 0.01) return; // Ya está balanceado

      final cuotasEditables = _cuotas.where((c) => !c.pagada).toList();
      if (cuotasEditables.isEmpty)
        return; // No se puede distribuir si no hay editables

      // Distribuir la diferencia solo entre cuotas no pagadas
      final ajustePorCuota = diferencia / cuotasEditables.length;

      for (int i = 0; i < _cuotas.length; i++) {
        if (!_cuotas[i].pagada) {
          _cuotas[i] = _cuotas[i].copyWith(
            monto: _cuotas[i].monto -
                ajustePorCuota, // Restar porque diferencia puede ser positiva o negativa
          );
          _cuotasModificadas[i] = true;
        }
      }
    });
    widget.onFechasSeleccionadas(_cuotas);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final cuotasModificadasCount = _cuotasModificadas.where((m) => m).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera con contador de modificadas y VALIDACIÓN DE TOTAL
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _totalValido
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _totalValido ? Icons.check_circle : Icons.warning,
                size: 16,
                color: _totalValido ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toca cada cuota para editar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.saldoPendienteEsperado != null
                        ? 'Pendiente config: \$${_totalCuotasValidadas.toStringAsFixed(2)} / '
                          '\$${widget.saldoPendienteEsperado!.toStringAsFixed(2)}'
                        : 'Total: \$${_totalCuotasValidadas.toStringAsFixed(2)} / '
                          '\$${widget.precioTotalEsperado.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _totalValido ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_totalValido)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    '${_diferencia > 0 ? "Sobran" : "Faltan"}: \$${_diferencia.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          _diferencia > 0 ? Colors.red : Colors.orange.shade800,
                    ),
                  ),
                ),
              if (cuotasModificadasCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$cuotasModificadasCount modificadas',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Lista horizontal de tarjetas compactas
        SizedBox(
          height: 130,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _cuotas.length,
            itemBuilder: (context, index) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  TarjetaCuotaCompacta(
                    cuota: _cuotas[index],
                    onCuotaEditada: _actualizarCuota,
                    primaryColor: primaryColor,
                    fueModificada: _cuotasModificadas[index],
                  ),

                  // Botón de reset individual
                  if (_cuotasModificadas[index] && !_cuotas[index].pagada)
                    Positioned(
                      top: -4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _resetearCuota(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.restart_alt,
                            size: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // Botones de acción rápida
        if (cuotasModificadasCount > 0 || !_totalValido)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón de distribuir diferencia (solo si no es válido)
                if (!_totalValido)
                  TextButton.icon(
                    onPressed: _distribuirDiferencia,
                    icon: Icon(
                      Icons.balance,
                      size: 14,
                      color: primaryColor,
                    ),
                    label: Text(
                      'Distribuir \$${_diferencia.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, color: primaryColor),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                if (!_totalValido && cuotasModificadasCount > 0)
                  const SizedBox(width: 8),

                // Botón de resetear todas (solo si hay alguna modificada y no pagada)
                if (cuotasModificadasCount > 0)
                  TextButton.icon(
                    onPressed: _resetearTodas,
                    icon: const Icon(Icons.restart_alt, size: 14),
                    label: const Text('Resetear todas'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
