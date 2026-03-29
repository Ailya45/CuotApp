// lib/widget/seguimiento/cuota_miniatura.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';

class CuotaMiniatura extends StatelessWidget {
  final int numeroCuota;
  final DateTime fecha;
  final double monto;
  final bool pagada;
  final VoidCallback? onTap;

  const CuotaMiniatura({
    super.key,
    required this.numeroCuota,
    required this.fecha,
    required this.monto,
    required this.pagada,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pagada ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: pagada ? AppColors.success : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: pagada 
                ? AppColors.success 
                : (onTap != null ? AppColors.primaryGreen : AppColors.lightGrey),
            width: pagada ? 0 : (onTap != null ? 1.5 : 1),
          ),
          boxShadow: [
            if (!pagada && onTap != null)
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '#$numeroCuota',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: pagada ? Colors.white : AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${fecha.day}/${fecha.month}',
              style: TextStyle(
                fontSize: 10,
                color: pagada ? Colors.white70 : AppColors.mediumGrey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '\$${monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: pagada ? Colors.white : AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}