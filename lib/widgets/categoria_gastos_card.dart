import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class CategoriaGastosCard extends StatelessWidget {
  final Categoria categoria;
  final double gastoAtual;

  const CategoriaGastosCard({
    super.key,
    required this.categoria,
    required this.gastoAtual,
  });

  @override
  Widget build(BuildContext context) {
    final limite = categoria.limiteGasto!;
    final percentual = (gastoAtual / limite) * 100;
    final saldo = limite - gastoAtual;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(categoria.icone, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria.nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Limite: ${Formatters.formatCurrency(limite)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(gastoAtual),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: percentual > 100
                            ? AppTheme.secondaryColor
                            : percentual > 80
                            ? AppTheme.warningColor
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${percentual.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: percentual > 100
                            ? AppTheme.secondaryColor
                            : percentual > 80
                            ? AppTheme.warningColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentual > 100 ? 1.0 : percentual / 100,
                minHeight: 10,
                backgroundColor: AppTheme.cardDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentual > 100
                      ? AppTheme.secondaryColor
                      : percentual > 80
                      ? AppTheme.warningColor
                      : AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  saldo >= 0 ? 'Disponível' : 'Excedido',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  Formatters.formatCurrency(saldo.abs()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: saldo >= 0
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
