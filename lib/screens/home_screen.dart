import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/saldo_card.dart';
import '../widgets/despesa_item.dart';
import '../widgets/categoria_gastos_card.dart';
import 'receitas_screen.dart';
import 'despesas_screen.dart';
import 'categorias_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciador de Despesas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriasScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: provider.carregarDados,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seletor de mês
                  _buildMonthSelector(provider),
                  const SizedBox(height: 20),

                  // Card de saldo
                  SaldoCard(
                    receitas: provider.totalReceitas,
                    despesas: provider.totalDespesas,
                    saldo: provider.saldo,
                  ),
                  const SizedBox(height: 20),

                  // Botões de Receitas e Despesas
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReceitasScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle),
                          label: const Text('Receitas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DespesasScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.remove_circle),
                          label: const Text('Despesas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Gastos por categoria com limite
                  _buildCategoriasComLimite(provider),
                  const SizedBox(height: 24),

                  // Próximos vencimentos
                  _buildProximosVencimentos(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(ExpenseProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: provider.mesAnterior,
            ),
            Text(
              Formatters.formatMonth(provider.mesAtual),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: provider.proximoMes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriasComLimite(ExpenseProvider provider) {
    final categoriasComLimite = provider.categorias
        .where((cat) => cat.limiteGasto != null)
        .toList();

    if (categoriasComLimite.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorias com Limite',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...categoriasComLimite.map((categoria) {
          final gasto = provider.getGastosPorCategoria(categoria.id!);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CategoriaGastosCard(categoria: categoria, gastoAtual: gasto),
          );
        }),
      ],
    );
  }

  Widget _buildProximosVencimentos(ExpenseProvider provider) {
    final hoje = DateTime.now();
    final despesasComVencimento =
        provider.despesas.where((d) => d.diaVencimento != null).toList()
          ..sort((a, b) => a.diaVencimento!.compareTo(b.diaVencimento!));

    final proximasDespesas = despesasComVencimento
        .where((d) {
          final vencimento = DateTime(d.ano, d.mes, d.diaVencimento!);
          return vencimento.isAfter(hoje) || vencimento.isAtSameMomentAs(hoje);
        })
        .take(5)
        .toList();

    if (proximasDespesas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos Vencimentos',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...proximasDespesas.map((despesa) {
          final categoria = provider.categorias.firstWhere(
            (cat) => cat.id == despesa.categoriaId,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DespesaItem(despesa: despesa, categoria: categoria),
          );
        }),
      ],
    );
  }
}
