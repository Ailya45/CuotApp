// 🔘 VISTA 1: Selector de tipo de crédito
import 'package:cuot_app/Model/credito_model.dart';
import 'package:flutter/material.dart';

class TipoCreditoSelector extends StatelessWidget {
  final Function(TipoCredito) onTipoSeleccionado;

  const TipoCreditoSelector({super.key, required this.onTipoSeleccionado});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿Qué tipo de cuota deseas crear?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          _buildOpcionCredito(
            context,
            tipo: TipoCredito.unPago,
            titulo: 'Cuota simple',
            descripcion: 'paga dentro de un tiempo determinado',
            icono: Icons.payments,
          ),          
          SizedBox(height: 16),
          _buildOpcionCredito(
            context,
            tipo: TipoCredito.cuotas,
            titulo: 'Cuotas fijas',
            descripcion: 'Pagos periódicos en fechas determinadas',
            icono: Icons.calendar_month,
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionCredito(
    BuildContext context, {
    required TipoCredito tipo,
    required String titulo,
    required String descripcion,
    required IconData icono,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => onTipoSeleccionado(tipo),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icono, size: 40, color: Theme.of(context).primaryColor),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(descripcion, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}