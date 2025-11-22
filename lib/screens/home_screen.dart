import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/saldo_card.dart';
import '../widgets/categoria_gastos_card.dart';
import 'receitas_screen.dart';
import 'despesas_screen.dart';
import 'categorias_screen.dart';
import 'vencendo_hoje_screen.dart';
import 'proximos_vencimentos_screen.dart';
import 'configuracoes_screen.dart';

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
        title: const Text('SET'),
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
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

                  // Botões de Vencimentos
                  _buildBotoesVencimentos(context, provider),
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

  Widget _buildBotoesVencimentos(
    BuildContext context,
    ExpenseProvider provider,
  ) {
    final hoje = DateTime.now();

    // Contar despesas vencendo hoje
    final despesasHoje = provider.despesas.where((despesa) {
      if (despesa.diaVencimento == null) return false;
      final vencimento = DateTime(
        despesa.ano,
        despesa.mes,
        despesa.diaVencimento!,
      );
      return vencimento.year == hoje.year &&
          vencimento.month == hoje.month &&
          vencimento.day == hoje.day;
    }).length;

    // Contar próximos vencimentos do mês (apenas após hoje, excluindo hoje)
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);
    final proximosVencimentos = provider.despesas.where((despesa) {
      if (despesa.diaVencimento == null) return false;
      final vencimento = DateTime(
        despesa.ano,
        despesa.mes,
        despesa.diaVencimento!,
      );
      final vencimentoNormalizado = DateTime(
        vencimento.year,
        vencimento.month,
        vencimento.day,
      );
      return vencimentoNormalizado.isAfter(hojeNormalizado);
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vencimentos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            // Botão Vencendo Hoje
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: despesasHoje > 0
                        ? [
                            const Color(0xFFFF6B35).withOpacity(0.15),
                            const Color(0xFFFF6B35).withOpacity(0.05),
                          ]
                        : [
                            Colors.grey.withOpacity(0.1),
                            Colors.grey.withOpacity(0.05),
                          ],
                  ),
                  border: Border.all(
                    color: despesasHoje > 0
                        ? const Color(0xFFFF6B35).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: despesasHoje > 0
                          ? const Color(0xFFFF6B35).withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
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
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VencendoHojeScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            size: 40,
                            color: despesasHoje > 0
                                ? const Color(0xFFFF6B35)
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hoje',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: despesasHoje > 0
                                    ? [
                                        const Color(
                                          0xFFFF6B35,
                                        ).withOpacity(0.2),
                                        const Color(
                                          0xFFFF6B35,
                                        ).withOpacity(0.1),
                                      ]
                                    : [
                                        Colors.grey.withOpacity(0.2),
                                        Colors.grey.withOpacity(0.1),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: despesasHoje > 0
                                    ? const Color(0xFFFF6B35).withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '$despesasHoje',
                              style: TextStyle(
                                color: despesasHoje > 0
                                    ? const Color(0xFFFF6B35)
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botão Próximos Vencimentos
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: proximosVencimentos > 0
                        ? [
                            const Color(0xFF3498DB).withOpacity(0.15),
                            const Color(0xFF3498DB).withOpacity(0.05),
                          ]
                        : [
                            Colors.grey.withOpacity(0.1),
                            Colors.grey.withOpacity(0.05),
                          ],
                  ),
                  border: Border.all(
                    color: proximosVencimentos > 0
                        ? const Color(0xFF3498DB).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: proximosVencimentos > 0
                          ? const Color(0xFF3498DB).withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
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
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProximosVencimentosScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 40,
                            color: proximosVencimentos > 0
                                ? const Color(0xFF3498DB)
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Próximos',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: proximosVencimentos > 0
                                    ? [
                                        const Color(
                                          0xFF3498DB,
                                        ).withOpacity(0.2),
                                        const Color(
                                          0xFF3498DB,
                                        ).withOpacity(0.1),
                                      ]
                                    : [
                                        Colors.grey.withOpacity(0.2),
                                        Colors.grey.withOpacity(0.1),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: proximosVencimentos > 0
                                    ? const Color(0xFF3498DB).withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '$proximosVencimentos',
                              style: TextStyle(
                                color: proximosVencimentos > 0
                                    ? const Color(0xFF3498DB)
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
