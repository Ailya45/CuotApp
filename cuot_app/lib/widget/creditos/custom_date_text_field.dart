import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateTextField extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool readOnly;

  const CustomDateTextField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.label,
    this.firstDate,
    this.lastDate,
    this.readOnly = false,
  });

  @override
  State<CustomDateTextField> createState() => _CustomDateTextFieldState();
}

class _CustomDateTextFieldState extends State<CustomDateTextField> {
  late TextEditingController _controller;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedDate != null
          ? _dateFormat.format(widget.selectedDate!)
          : '',
    );
  }

  @override
  void didUpdateWidget(CustomDateTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate &&
        widget.selectedDate != null) {
      _controller.text = _dateFormat.format(widget.selectedDate!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (widget.readOnly) return;

    try {
      final DateTime now = DateTime.now();
      final DateTime firstDate = widget.firstDate ?? DateTime(2000);
      final DateTime lastDate = widget.lastDate ?? DateTime(now.year + 10);

      DateTime initialDate = widget.selectedDate ?? now;
      if (initialDate.isBefore(firstDate)) initialDate = firstDate;
      if (initialDate.isAfter(lastDate)) initialDate = lastDate;

      Locale pickerLocale;
      try {
        pickerLocale = Localizations.localeOf(context);
      } catch (_) {
        pickerLocale = const Locale('es', 'ES');
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        locale: pickerLocale,
      );

      if (picked != null && mounted) {
        widget.onDateSelected(picked);
        _controller.text = _dateFormat.format(picked);
      }
    } catch (e, stack) {
      debugPrint('Error seleccionando fecha en CustomDateTextField: $e');
      debugPrint('$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir selector de fecha. Intente de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTextChanged(String value) {
    if (value.length == 10) {
      try {
        final DateTime parsed = _dateFormat.parseStrict(value);
        widget.onDateSelected(parsed);
      } catch (e) {
        // Invalid date format, ignore or show error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'DD/MM/AAAA',
        prefixIcon: const Icon(Icons.calendar_today, size: 20),
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: widget.readOnly ? null : _selectDate,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: widget.readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
      ),
      onChanged: _onTextChanged,
    );
  }
}
