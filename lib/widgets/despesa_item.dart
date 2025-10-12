import 'package:flutter/material.dart';
import '../models/despesa.dart';
import '../models/categoria.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class DespesaItem extends StatelessWidget {
  final Despesa despesa;
  final Categoria categoria;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DespesaItem({
    super.key,
    required this.despesa,
    required this.categoria,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final vencimento = despesa.diaVencimento != null
        ? DateTime(despesa.ano, despesa.mes, despesa.diaVencimento!)
        : null;

    final bool vencido =
        vencimento != null &&
        vencimento.isBefore(hoje) &&
        (despesa.status != StatusPagamento.pago &&
            despesa.status != StatusPagamento.debitoAutomatico);

    final bool venceHoje =
        vencimento != null &&
        vencimento.year == hoje.year &&
        vencimento.month == hoje.month &&
        vencimento.day == hoje.day;

    return Card(
      color: vencido
          ? AppTheme.secondaryColor.withOpacity(0.1)
          : venceHoje
          ? AppTheme.warningColor.withOpacity(0.1)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(categoria.icone, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          despesa.descricao,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              Formatters.formatCurrency(despesa.valor),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildStatusChip(context),
                if (despesa.diaVencimento != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: vencido
                          ? AppTheme.secondaryColor
                          : venceHoje
                          ? AppTheme.warningColor
                          : AppTheme.accentColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Dia ${despesa.diaVencimento}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: vencido || venceHoje
                            ? Colors.white
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                if (despesa.isFixa)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Fixa',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete, color: AppTheme.secondaryColor),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color cor;
    IconData icone;

    switch (despesa.status) {
      case StatusPagamento.pago:
        cor = AppTheme.primaryColor;
        icone = Icons.check_circle;
        break;
      case StatusPagamento.agendado:
        cor = AppTheme.warningColor;
        icone = Icons.schedule;
        break;
      case StatusPagamento.debitoAutomatico:
        cor = AppTheme.accentColor;
        icone = Icons.autorenew;
        break;
      case StatusPagamento.aPagar:
        cor = AppTheme.secondaryColor;
        icone = Icons.pending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: cor),
          const SizedBox(width: 4),
          Text(
            Formatters.getStatusText(despesa.status.index),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cor),
          ),
        ],
      ),
    );
  }
}
