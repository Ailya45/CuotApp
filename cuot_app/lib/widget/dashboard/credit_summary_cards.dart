import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CreditSummaryCards extends StatelessWidget {
  final int totalCredits;           // 1. Cantidad de Créditos
  final double totalPaid;           // 2. Dinero abonado
  final int pendingWeeklyQuotas;    // 3. Cuotas pendientes por semana
  final double pendingBalance;      // 4. Saldo de Cuotas Pendiente

  final VoidCallback? onTapActiveCredits; // 👈 NUEVO: Callback para navegación
  final VoidCallback? onTapPendingBalance; // 👈 NUEVO: Opcional para el futuro

  const CreditSummaryCards({
    super.key,
    required this.totalCredits,
    required this.totalPaid,
    required this.pendingWeeklyQuotas,
    required this.pendingBalance,
    this.onTapActiveCredits,
    this.onTapPendingBalance,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildSummaryCard(
          title: 'Créditos Activos',
          value: totalCredits.toString(),
          icon: Icons.credit_card,
          color: AppColors.primaryGreen,
          onTap: onTapActiveCredits, // 👈 ASIGNADO
        ),
        _buildSummaryCard(
          title: 'Total Abonado',
          value: '\$${totalPaid.toStringAsFixed(2)}',
          icon: Icons.account_balance_wallet,
          color: AppColors.info,
        ),
        _buildSummaryCard(
          title: 'Cuotas x Semana',
          value: pendingWeeklyQuotas.toString(),
          icon: Icons.calendar_today,
          color: AppColors.warning,
        ),
        _buildSummaryCard(
          title: 'Saldo Pendiente',
          value: '\$${pendingBalance.toStringAsFixed(2)}',
          icon: Icons.pending_actions,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap, // 👈 AGREGADO
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias, // Para que el ripple del InkWell respete el borde del Card
      child: InkWell( // 👈 AGREGADO para interactividad
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.pureWhite,
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mediumGrey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}