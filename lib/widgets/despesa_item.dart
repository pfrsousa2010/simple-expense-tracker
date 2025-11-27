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
  final bool showSwipeIcon;

  const DespesaItem({
    super.key,
    required this.despesa,
    required this.categoria,
    this.onTap,
    this.onDelete,
    this.showSwipeIcon = true,
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
            // Estabelecimento (para cartão de crédito ou despesa não fixa)
            if (despesa.estabelecimento != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.store, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      despesa.estabelecimento!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Compra Online (para despesas de cartão de crédito)
            if (despesa.isCartaoCredito && despesa.isCompraOnline) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Compra Online',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            // Dia da compra
            if (despesa.dataCompra != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Dia ${despesa.dataCompra!.day}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  Formatters.formatCurrency(despesa.valor),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (despesa.isCartaoCredito &&
                    despesa.tipoPagamento == TipoPagamentoCartao.parcelado &&
                    despesa.numeroParcela != null &&
                    despesa.totalParcelas != null) ...[
                  const SizedBox(width: 8),
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
                      '${despesa.numeroParcela}/${despesa.totalParcelas}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Não mostrar status para despesas de cartão de crédito
                if (!despesa.isCartaoCredito) _buildStatusChip(context),
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
        trailing: showSwipeIcon
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                  ],
                ),
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
