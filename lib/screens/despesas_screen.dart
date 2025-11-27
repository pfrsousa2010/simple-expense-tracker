import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/despesa.dart';
import '../models/categoria.dart';
import '../models/cartao_credito.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/despesa_item.dart';
import 'copiar_despesas_fixas_screen.dart';
import 'adicionar_despesa_screen.dart';
import 'adicionar_despesa_cartao_screen.dart';
import 'editar_despesa_screen.dart';
import 'editar_despesa_cartao_screen.dart';

class DespesasScreen extends StatefulWidget {
  const DespesasScreen({super.key});

  @override
  State<DespesasScreen> createState() => _DespesasScreenState();
}

class _DespesasScreenState extends State<DespesasScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar Despesas Fixas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CopiarDespesasFixasScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final despesas = provider.despesas;

          if (despesas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma despesa cadastrada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione seus gastos',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Separar despesas de cartão
          final despesasCartao = despesas
              .where((d) => d.isCartaoCredito)
              .toList();

          // Agrupar despesas de cartão por cartão
          final despesasPorCartao = <CartaoCredito, List<Despesa>>{};
          for (var despesa in despesasCartao) {
            if (despesa.cartaoCreditoId != null) {
              final cartao = provider.cartoesCredito.firstWhere(
                (c) => c.id == despesa.cartaoCreditoId,
                orElse: () => CartaoCredito(
                  nome: 'Cartão Removido',
                  banco: '',
                  numero: '',
                ),
              );
              if (!despesasPorCartao.containsKey(cartao)) {
                despesasPorCartao[cartao] = [];
              }
              despesasPorCartao[cartao]!.add(despesa);
            }
          }

          // Agrupar despesas normais por categoria
          final despesasPorCategoria = provider.getDespesasPorCategoria();
          // Filtrar apenas despesas normais
          final despesasPorCategoriaNormais = <Categoria, List<Despesa>>{};
          for (var entry in despesasPorCategoria.entries) {
            final despesasNormaisCategoria = entry.value
                .where((d) => !d.isCartaoCredito)
                .toList();
            if (despesasNormaisCategoria.isNotEmpty) {
              despesasPorCategoriaNormais[entry.key] = despesasNormaisCategoria;
            }
          }

          final totalItems =
              despesasPorCartao.length + despesasPorCategoriaNormais.length;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              // Primeiro mostrar despesas de cartão
              if (index < despesasPorCartao.length) {
                final cartao = despesasPorCartao.keys.elementAt(index);
                final despesasCartao = despesasPorCartao[cartao]!;
                return _buildCartaoSection(
                  context,
                  provider,
                  cartao,
                  despesasCartao,
                );
              } else {
                // Depois mostrar despesas normais por categoria
                final categoriaIndex = index - despesasPorCartao.length;
                final categoria = despesasPorCategoriaNormais.keys.elementAt(
                  categoriaIndex,
                );
                final despesasCategoria =
                    despesasPorCategoriaNormais[categoria]!;
                return _buildCategoriaSection(
                  context,
                  provider,
                  categoria,
                  despesasCategoria,
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMenu(context);
        },
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCartaoSection(
    BuildContext context,
    ExpenseProvider provider,
    CartaoCredito cartao,
    List<Despesa> despesas,
  ) {
    final totalFatura = despesas.fold(0.0, (sum, d) => sum + d.valor);
    final mesFatura = provider.mesAtual.month;
    final anoFatura = provider.mesAtual.year;

    // Verificar se o cartão ainda existe (não foi deletado)
    if (cartao.id == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<StatusPagamento?>(
      future: provider.getStatusFatura(cartao.id!, mesFatura, anoFatura),
      builder: (context, snapshot) {
        final statusFatura = snapshot.data ?? cartao.status;
        final statusInfo = _getStatusInfo(statusFatura);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showStatusModal(context, provider, cartao),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cartao.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cartao.color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cartao.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cartao.nome,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            cartao.banco,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (statusInfo['color'] as Color)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusInfo['icon'] as IconData,
                                      size: 14,
                                      color: statusInfo['color'] as Color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusInfo['text'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: statusInfo['color'] as Color,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (cartao.diaVencimento != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withOpacity(
                                      0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    cartao.diaFechamento != null
                                        ? 'Fatura vence dia ${cartao.diaVencimento} • fecha dia ${cartao.diaFechamento}'
                                        : 'Fatura vence dia ${cartao.diaVencimento}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.textPrimary),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(totalFatura),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cartao.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...despesas.map((despesa) {
              final categoria = provider.categorias.firstWhere(
                (c) => c.id == despesa.categoriaId,
              );
              return _buildDespesaItemWithSwipe(
                context,
                provider,
                despesa,
                categoria,
              );
            }),
            const Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildCategoriaSection(
    BuildContext context,
    ExpenseProvider provider,
    Categoria categoria,
    List<Despesa> despesas,
  ) {
    final totalCategoria = despesas.fold(0.0, (sum, d) => sum + d.valor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(categoria.icone, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                categoria.nome,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                Formatters.formatCurrency(totalCategoria),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...despesas.map((despesa) {
          return _buildDespesaItemWithSwipe(
            context,
            provider,
            despesa,
            categoria,
          );
        }),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildDespesaItemWithSwipe(
    BuildContext context,
    ExpenseProvider provider,
    Despesa despesa,
    Categoria categoria,
  ) {
    return Dismissible(
      key: Key('despesa_${despesa.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe para direita = Editar
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
            if (opcaoEdicao == null) return false;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditarDespesaCartaoScreen(
                  despesa: despesa,
                  editarTodasParcelas:
                      opcaoEdicao == 1, // 1 = esta e as próximas
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
          return false; // Não remove o item
        } else if (direction == DismissDirection.endToStart) {
          // Swipe para esquerda = Remover
          return await _showDeleteConfirmation(context, provider, despesa);
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Editar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Remover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.delete, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DespesaItem(
          despesa: despesa,
          categoria: categoria,
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
                    editarTodasParcelas:
                        opcaoEdicao == 1, // 1 = esta e as próximas
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
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    ExpenseProvider provider,
    Despesa despesa,
  ) async {
    // Verificar se é uma despesa parcelada
    if (despesa.isCartaoCredito &&
        despesa.parcelaId != null &&
        despesa.tipoPagamento == TipoPagamentoCartao.parcelado &&
        despesa.numeroParcela != null) {
      // Buscar parcelas futuras não pagas (a partir desta parcela)
      final parcelasFuturasNaoPagas = await provider
          .getDespesasParceladasFuturasNaoPagas(
            despesa.parcelaId!,
            despesa.numeroParcela!,
          );
      final totalParcelasFuturas = parcelasFuturasNaoPagas.length;

      if (totalParcelasFuturas > 1) {
        // Perguntar se quer excluir apenas esta ou todas a partir desta
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excluir Despesa Parcelada'),
            content: Text(
              'Esta despesa faz parte de uma compra parcelada.\n\n'
              'Deseja excluir:\n'
              '• Apenas esta parcela\n'
              '• Esta e as ${totalParcelasFuturas - 1} próximas (${totalParcelasFuturas} no total)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  provider.deletarDespesa(despesa.id!);
                  Navigator.pop(context, true);
                },
                child: const Text('Apenas esta'),
              ),
              ElevatedButton(
                onPressed: () {
                  final idsParaExcluir = parcelasFuturasNaoPagas
                      .map((d) => d.id!)
                      .toList();
                  provider.deletarDespesas(idsParaExcluir);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Esta e as próximas (${totalParcelasFuturas})'),
              ),
            ],
          ),
        );
      }
    }
    // Verificar se é uma despesa recorrente
    else if (despesa.isCartaoCredito &&
        despesa.parcelaId != null &&
        despesa.tipoPagamento == TipoPagamentoCartao.recorrente) {
      // Buscar despesas recorrentes futuras não pagas (a partir deste mês/ano)
      final recorrentesFuturasNaoPagas = await provider
          .getDespesasRecorrentesFuturasNaoPagas(
            despesa.parcelaId!,
            despesa.mes,
            despesa.ano,
          );
      final totalRecorrentesFuturas = recorrentesFuturasNaoPagas.length;

      if (totalRecorrentesFuturas > 1) {
        // Perguntar se quer excluir apenas esta ou todas a partir desta
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excluir Despesa Recorrente'),
            content: Text(
              'Esta despesa faz parte de uma compra recorrente.\n\n'
              'Deseja excluir:\n'
              '• Apenas esta despesa\n'
              '• Esta e as ${totalRecorrentesFuturas - 1} próximas (${totalRecorrentesFuturas} no total)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  provider.deletarDespesa(despesa.id!);
                  Navigator.pop(context, true);
                },
                child: const Text('Apenas esta'),
              ),
              ElevatedButton(
                onPressed: () {
                  final idsParaExcluir = recorrentesFuturasNaoPagas
                      .map((d) => d.id!)
                      .toList();
                  provider.deletarDespesas(idsParaExcluir);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Esta e as próximas (${totalRecorrentesFuturas})'),
              ),
            ],
          ),
        );
      }
    }

    // Diálogo padrão para despesas não parceladas ou única parcela
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Despesa'),
        content: Text('Deseja realmente excluir "${despesa.descricao}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletarDespesa(despesa.id!);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return confirmado;
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
        title: Text(
          'Editar Despesa ${tipoTexto[0].toUpperCase()}${tipoTexto.substring(1)}',
        ),
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
            onPressed: () =>
                Navigator.pop(context, 1), // 1 = esta e as próximas
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

  Map<String, dynamic> _getStatusInfo(StatusPagamento status) {
    switch (status) {
      case StatusPagamento.pago:
        return {
          'color': AppTheme.primaryColor,
          'icon': Icons.check_circle,
          'text': 'Pago',
        };
      case StatusPagamento.agendado:
        return {
          'color': AppTheme.warningColor,
          'icon': Icons.schedule,
          'text': 'Agendado',
        };
      case StatusPagamento.debitoAutomatico:
        return {
          'color': AppTheme.accentColor,
          'icon': Icons.autorenew,
          'text': 'Débito Automático',
        };
      case StatusPagamento.aPagar:
        return {
          'color': AppTheme.secondaryColor,
          'icon': Icons.pending,
          'text': 'A Pagar',
        };
    }
  }

  void _showStatusModal(
    BuildContext context,
    ExpenseProvider provider,
    CartaoCredito cartao,
  ) {
    // Verificar se o cartão ainda existe (não foi deletado)
    if (cartao.id == null) {
      return;
    }

    final mesFatura = provider.mesAtual.month;
    final anoFatura = provider.mesAtual.year;
    final despesasCartao = provider.despesas
        .where((d) => d.cartaoCreditoId == cartao.id)
        .toList();
    final totalFatura = despesasCartao.fold(0.0, (sum, d) => sum + d.valor);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FutureBuilder<StatusPagamento?>(
        future: provider.getStatusFatura(cartao.id!, mesFatura, anoFatura),
        builder: (context, snapshot) {
          final statusAtual = snapshot.data ?? cartao.status;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Status da Fatura',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${cartao.nome} - ${Formatters.formatCurrency(totalFatura)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildStatusOption(
                    context,
                    provider,
                    cartao,
                    StatusPagamento.aPagar,
                    mesFatura,
                    anoFatura,
                    statusAtual,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusOption(
                    context,
                    provider,
                    cartao,
                    StatusPagamento.agendado,
                    mesFatura,
                    anoFatura,
                    statusAtual,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusOption(
                    context,
                    provider,
                    cartao,
                    StatusPagamento.debitoAutomatico,
                    mesFatura,
                    anoFatura,
                    statusAtual,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusOption(
                    context,
                    provider,
                    cartao,
                    StatusPagamento.pago,
                    mesFatura,
                    anoFatura,
                    statusAtual,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    ExpenseProvider provider,
    CartaoCredito cartao,
    StatusPagamento status,
    int mesFatura,
    int anoFatura,
    StatusPagamento statusAtual,
  ) {
    final isSelected = statusAtual == status;
    final statusInfo = _getStatusInfo(status);

    return InkWell(
      onTap: () async {
        await provider.atualizarStatusFatura(
          cartao.id!,
          mesFatura,
          anoFatura,
          status,
        );
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (statusInfo['color'] as Color).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? statusInfo['color'] as Color
                : AppTheme.textTertiary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              statusInfo['icon'] as IconData,
              color: statusInfo['color'] as Color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                statusInfo['text'] as String,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: statusInfo['color'] as Color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: statusInfo['color'] as Color),
          ],
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance, size: 28),
              title: const Text('Conta Corrente'),
              subtitle: const Text('Despesa da conta corrente'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdicionarDespesaScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, size: 28),
              title: const Text('Cartão de Crédito'),
              subtitle: const Text('Despesa no cartão de crédito'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdicionarDespesaCartaoScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
