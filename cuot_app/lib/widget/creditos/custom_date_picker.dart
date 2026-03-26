// 📅 WIDGET REUTILIZABLE: Selector de fecha personalizado
import 'package:flutter/material.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool readOnly;

  const CustomDatePicker(
      {super.key,
      required this.selectedDate,
      required this.onDateSelected,
      required this.label,
      this.firstDate,
      this.lastDate,
      this.readOnly = false});

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  Future<void> _selectDate() async {
    if (widget.readOnly) return;

    try {
      // Usar dateOnly para evitar problemas de comparación por hora/minuto/segundo
      final DateTime now = DateUtils.dateOnly(DateTime.now());
      final DateTime effectiveFirstDate = widget.firstDate != null
          ? DateUtils.dateOnly(widget.firstDate!)
          : DateTime(2000); // 👈 CAMBIADO: Permitir fechas pasadas por defecto
      final DateTime effectiveLastDate = widget.lastDate != null
          ? DateUtils.dateOnly(widget.lastDate!)
          : now.add(const Duration(days: 365 * 5));

      // Clamp initialDate para que siempre esté dentro del rango válido
      DateTime effectiveInitialDate = widget.selectedDate != null
          ? DateUtils.dateOnly(widget.selectedDate!)
          : now;
      if (effectiveInitialDate.isBefore(effectiveFirstDate)) {
        effectiveInitialDate = effectiveFirstDate;
      }
      if (effectiveInitialDate.isAfter(effectiveLastDate)) {
        effectiveInitialDate = effectiveLastDate;
      }

      Locale pickerLocale;
      try {
        pickerLocale = Localizations.localeOf(context);
      } catch (_) {
        pickerLocale = const Locale('es', 'ES');
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: effectiveInitialDate,
        firstDate: effectiveFirstDate,
        lastDate: effectiveLastDate,
        locale: pickerLocale,
      );

      if (picked != null && mounted) {
        widget.onDateSelected(picked);
      }
    } catch (e) {
      debugPrint('❌ Error al abrir el selector de fecha: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                widget.readOnly ? Colors.grey.shade300 : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(8),
          color: widget.readOnly ? Colors.grey.shade50 : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.selectedDate == null
                    ? widget.label
                    : '${widget.selectedDate!.day}/${widget.selectedDate!.month}/${widget.selectedDate!.year}',
                style: TextStyle(
                  color: widget.readOnly
                      ? Colors.grey.shade600
                      : (widget.selectedDate == null
                          ? Colors.grey
                          : Colors.black),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: widget.readOnly ? Colors.grey.shade400 : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
