// lib/widget/creditos/tarjeta_cuota_compacta.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/widget/creditos/dialogo_editar_cuota.dart';

class TarjetaCuotaCompacta extends StatefulWidget {
  final CuotaPersonalizada cuota;
  final Function(CuotaPersonalizada) onCuotaEditada;
  final Color primaryColor;
  final bool fueModificada; // 👈 Nuevo: indica si la cuota fue modificada

  const TarjetaCuotaCompacta({
    super.key,
    required this.cuota,
    required this.onCuotaEditada,
    required this.primaryColor,
    this.fueModificada = false, // Por defecto false
  });

  @override
  State<TarjetaCuotaCompacta> createState() => _TarjetaCuotaCompactaState();
}

class _TarjetaCuotaCompactaState extends State<TarjetaCuotaCompacta> {
  bool _isHovered = false; // Para efecto hover (web/desktop)

  Color _getBackgroundColor() {
    if (widget.fueModificada) {
      // Si fue modificada: color más oscuro y sólido
      return widget.primaryColor.withOpacity(0.3);
    } else {
      // Si no fue modificada: color suave y degradado
      return widget.primaryColor.withOpacity(0.1);
    }
  }

  Color _getBorderColor() {
    if (widget.fueModificada) {
      return widget.primaryColor.withOpacity(0.8);
    } else {
      return widget.primaryColor.withOpacity(0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final borderColor = _getBorderColor();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () async {
          final cuotaEditada = await showDialog<CuotaPersonalizada>(
            context: context,
            builder: (context) => DialogoEditarCuota(
              cuota: widget.cuota,
              primaryColor: widget.primaryColor,
            ),
          );
          
          if (cuotaEditada != null) {
            widget.onCuotaEditada(cuotaEditada);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          margin: const EdgeInsets.only(right: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered 
                  ? widget.primaryColor 
                  : borderColor,
              width: _isHovered ? 2 : 1.5,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              else if (widget.fueModificada)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              else
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Número de cuota con icono de lápiz y badge de modificada
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '#${widget.cuota.numeroCuota}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: widget.fueModificada 
                          ? Colors.white 
                          : widget.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    widget.fueModificada ? Icons.edit : Icons.edit_outlined,
                    size: 11,
                    color: widget.fueModificada 
                        ? Colors.white70 
                        : Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              // Icono de calendario con indicador de modificada
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.fueModificada 
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: widget.fueModificada 
                      ? Colors.white70 
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              
              // Fecha
              Text(
                '${widget.cuota.fechaPago.day.toString().padLeft(2, '0')}/'
                '${widget.cuota.fechaPago.month.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.fueModificada 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                  color: widget.fueModificada 
                      ? Colors.white 
                      : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              
              // Monto con estilo mejorado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.fueModificada 
                      ? Colors.white
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.fueModificada 
                        ? Colors.transparent
                        : widget.primaryColor.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '\$${widget.cuota.monto.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.fueModificada 
                        ? widget.primaryColor
                        : widget.primaryColor.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}