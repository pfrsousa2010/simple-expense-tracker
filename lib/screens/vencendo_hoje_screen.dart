import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/despesa_item.dart';
import '../models/despesa.dart';
import '../utils/app_theme.dart';
import 'editar_despesa_screen.dart';
import 'editar_despesa_cartao_screen.dart';

class VencendoHojeScreen extends StatelessWidget {
  const VencendoHojeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vencendo Hoje')),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final hoje = DateTime.now();

          // Buscar despesas vencendo hoje (incluindo fixas, débito automático, etc)
          final despesasHoje =
              provider.despesas.where((despesa) {
                  if (despesa.diaVencimento == null) return false;

                  final vencimento = DateTime(
                    despesa.ano,
                    despesa.mes,
                    despesa.diaVencimento!,
                  );

                  // Verifica se vence hoje (mesmo dia, mês e ano)
                  return vencimento.year == hoje.year &&
                      vencimento.month == hoje.month &&
                      vencimento.day == hoje.day;
                }).toList()
                ..sort((a, b) => a.diaVencimento!.compareTo(b.diaVencimento!));

          // Agrupar despesas por data de vencimento (todas vencem hoje, mas pode haver múltiplas)
          final Map<DateTime, List<dynamic>> despesasAgrupadas = {};
          for (var despesa in despesasHoje) {
            final vencimento = DateTime(
              despesa.ano,
              despesa.mes,
              despesa.diaVencimento!,
            );
            if (!despesasAgrupadas.containsKey(vencimento)) {
              despesasAgrupadas[vencimento] = [];
            }
            despesasAgrupadas[vencimento]!.add(despesa);
          }

          // Converter para lista ordenada por data
          final gruposOrdenados = despesasAgrupadas.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          if (gruposOrdenados.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma despesa vence hoje',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gruposOrdenados.length,
            itemBuilder: (context, index) {
              final grupo = gruposOrdenados[index];
              final despesasDoGrupo = grupo.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFF6B35).withOpacity(0.05),
                        const Color(0xFFFF6B35).withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            children: despesasDoGrupo.asMap().entries.map((
                              entry,
                            ) {
                              final despesaIndex = entry.key;
                              final despesa = entry.value;
                              final categoria = provider.categorias.firstWhere(
                                (cat) => cat.id == despesa.categoriaId,
                              );

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      despesaIndex < despesasDoGrupo.length - 1
                                      ? 12
                                      : 0,
                                ),
                                child: DespesaItem(
                                  despesa: despesa,
                                  categoria: categoria,
                                  showSwipeIcon: false,
                                  onTap: () async {
                                    if (despesa.isCartaoCredito &&
                                        despesa.parcelaId != null &&
                                        (despesa.tipoPagamento == TipoPagamentoCartao.parcelado ||
                                            despesa.tipoPagamento == TipoPagamentoCartao.recorrente)) {
                                      // Perguntar se quer editar apenas esta ou esta e as próximas
                                      final opcaoEdicao = await _showEditParcelasConfirmation(
                                        context,
                                        despesa,
                                        provider,
                                      );
                                      if (opcaoEdicao == null) return;
                                      
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditarDespesaCartaoScreen(
                                            despesa: despesa,
                                            editarTodasParcelas: opcaoEdicao == 1, // 1 = esta e as próximas
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => despesa.isCartaoCredito
                                              ? EditarDespesaCartaoScreen(despesa: despesa)
                                              : EditarDespesaScreen(despesa: despesa),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF6B35).withOpacity(0.2),
                                const Color(0xFFFF6B35).withOpacity(0.1),
                              ],
                            ),
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFFFF6B35).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: const Color(0xFFFF6B35),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Vence hoje!',
                                style: TextStyle(
                                  color: const Color(0xFFFF6B35),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<int?> _showEditParcelasConfirmation(
    BuildContext context,
    Despesa despesa,
    ExpenseProvider provider,
  ) async {
    final tipoTexto = despesa.tipoPagamento == TipoPagamentoCartao.parcelado
        ? 'parcelada'
        : 'recorrente';
    final itemTexto = despesa.tipoPagamento == TipoPagamentoCartao.parcelado
        ? 'parcela'
        : 'despesa';

    int? totalFuturas;
    if (despesa.tipoPagamento == TipoPagamentoCartao.parcelado &&
        despesa.numeroParcela != null) {
      final futuras = await provider.getDespesasParceladasFuturasNaoPagas(
        despesa.parcelaId!,
        despesa.numeroParcela!,
      );
      totalFuturas = futuras.length;
    } else if (despesa.tipoPagamento == TipoPagamentoCartao.recorrente) {
      final futuras = await provider.getDespesasRecorrentesFuturasNaoPagas(
        despesa.parcelaId!,
        despesa.mes,
        despesa.ano,
      );
      totalFuturas = futuras.length;
    }

    if (totalFuturas == null || totalFuturas <= 1) {
      return 0; // Apenas esta
    }

    return await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Despesa ${tipoTexto[0].toUpperCase()}${tipoTexto.substring(1)}'),
        content: Text(
          'Esta despesa faz parte de uma compra $tipoTexto.\n\n'
          'Deseja editar:\n'
          '• Apenas esta $itemTexto\n'
          '• Esta e as ${totalFuturas! - 1} próximas (${totalFuturas} no total)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 0), // 0 = apenas esta
            child: const Text('Apenas esta'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 1), // 1 = esta e as próximas
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Esta e as próximas (${totalFuturas})'),
          ),
        ],
      ),
    );
  }
}
