import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class SaldoCard extends StatelessWidget {
  final double receitas;
  final double despesas;
  final double saldo;

  const SaldoCard({
    super.key,
    required this.receitas,
    required this.despesas,
    required this.saldo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfo(
                  context,
                  'Receitas',
                  receitas,
                  AppTheme.primaryColor,
                  Icons.arrow_upward,
                ),
                Container(width: 1, height: 50, color: AppTheme.textTertiary),
                _buildInfo(
                  context,
                  'Despesas',
                  despesas,
                  AppTheme.secondaryColor,
                  Icons.arrow_downward,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saldo', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  Formatters.formatCurrency(saldo),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: saldo >= 0
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(
    BuildContext context,
    String label,
    double valor,
    Color cor,
    IconData icone,
  ) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: cor, size: 16),
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(valor),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: cor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
