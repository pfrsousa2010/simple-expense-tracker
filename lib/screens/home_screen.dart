import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../providers/expense_provider.dart';
import '../models/cartao_credito.dart';
import '../models/despesa.dart';
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
import 'cartoes_credito_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().initialize();
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getAppBarTitle())),
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textTertiary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Cartões',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorias',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config.'),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Finanças';
      case 1:
        return 'Cartões de Crédito';
      case 2:
        return 'Categorias';
      case 3:
        return 'Configurações';
      default:
        return 'Finanças';
    }
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return const CartoesCreditoScreen();
      case 2:
        return const CategoriasScreen();
      case 3:
        return const ConfiguracoesScreen();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return Consumer<ExpenseProvider>(
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
                const SizedBox(height: 24),
                // Cards de Cartões de Crédito com Vencimento
                _buildCartoesComVencimento(context, provider),
              ],
            ),
          ),
        );
      },
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
        Text(
          'Vencimentos de contas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
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

  Widget _buildCartoesComVencimento(
    BuildContext context,
    ExpenseProvider provider,
  ) {
    final hoje = DateTime.now();
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);

    // Buscar cartões que têm despesas vencendo hoje ou nos próximos dias
    final cartoesComVencimento = <CartaoCredito, List<Despesa>>{};

    for (var cartao in provider.cartoesCredito) {
      if (cartao.diaVencimento == null) continue;

      // Buscar despesas deste cartão
      final despesasCartao = provider.despesas
          .where((d) => d.cartaoCreditoId == cartao.id)
          .toList();

      if (despesasCartao.isEmpty) continue;

      // Calcular vencimento baseado no mês ATUAL REAL (não o selecionado)
      // O vencimento do cartão é sempre relativo ao mês atual
      final vencimentoEsteMes = DateTime(
        hoje.year,
        hoje.month,
        cartao.diaVencimento!,
      );

      // Normalizar a data de vencimento
      final vencimentoEsteMesNormalizado = DateTime(
        vencimentoEsteMes.year,
        vencimentoEsteMes.month,
        vencimentoEsteMes.day,
      );

      // Se o dia já passou este mês, considerar o próximo mês
      DateTime vencimentoFinal;
      if (vencimentoEsteMesNormalizado.isBefore(hojeNormalizado)) {
        // Calcular próximo mês corretamente
        final proximoMes = hoje.month == 12
            ? DateTime(hoje.year + 1, 1, cartao.diaVencimento!)
            : DateTime(hoje.year, hoje.month + 1, cartao.diaVencimento!);
        vencimentoFinal = DateTime(
          proximoMes.year,
          proximoMes.month,
          proximoMes.day,
        );
      } else {
        vencimentoFinal = vencimentoEsteMesNormalizado;
      }

      final diasParaVencer = vencimentoFinal.difference(hojeNormalizado).inDays;

      // Mostrar cartões que vencem hoje ou nos próximos 30 dias
      if (diasParaVencer >= 0 && diasParaVencer <= 30) {
        cartoesComVencimento[cartao] = despesasCartao;
      }
    }

    if (cartoesComVencimento.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vecimentos de faturas de cartão',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...cartoesComVencimento.entries.map((entry) {
          final cartao = entry.key;
          final despesas = entry.value;
          final totalFatura = despesas.fold(0.0, (sum, d) => sum + d.valor);

          // Determinar o mês/ano da fatura baseado no vencimento
          final vencimentoEsteMes = DateTime(
            hoje.year,
            hoje.month,
            cartao.diaVencimento!,
          );
          final vencimentoEsteMesNormalizado = DateTime(
            vencimentoEsteMes.year,
            vencimentoEsteMes.month,
            vencimentoEsteMes.day,
          );

          DateTime vencimentoFinal;
          if (vencimentoEsteMesNormalizado.isBefore(hojeNormalizado)) {
            final proximoMes = hoje.month == 12
                ? DateTime(hoje.year + 1, 1, cartao.diaVencimento!)
                : DateTime(hoje.year, hoje.month + 1, cartao.diaVencimento!);
            vencimentoFinal = DateTime(
              proximoMes.year,
              proximoMes.month,
              proximoMes.day,
            );
          } else {
            vencimentoFinal = vencimentoEsteMesNormalizado;
          }

          final diasParaVencer = vencimentoFinal
              .difference(hojeNormalizado)
              .inDays;

          // Usar o mês/ano selecionado pelo usuário, não o vencimento calculado
          final mesFatura = provider.mesAtual.month;
          final anoFatura = provider.mesAtual.year;

          return FutureBuilder<StatusPagamento?>(
            future: provider.getStatusFatura(cartao.id!, mesFatura, anoFatura),
            builder: (context, snapshot) {
              final statusFatura = snapshot.data ?? cartao.status;
              final statusInfo = _getStatusInfo(statusFatura);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showStatusModal(context, provider, cartao),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (cartao.diaVencimento != null) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          diasParaVencer == 0
                                              ? 'Fatura vence hoje'
                                              : diasParaVencer == 1
                                              ? 'Fatura vence amanhã'
                                              : 'Fatura vence em $diasParaVencer dias',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: diasParaVencer <= 3
                                                    ? AppTheme.warningColor
                                                    : AppTheme.textSecondary,
                                                fontWeight: diasParaVencer <= 3
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
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
                                          size: 12,
                                          color: statusInfo['color'] as Color,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusInfo['text'] as String,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    statusInfo['color']
                                                        as Color,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(totalFatura),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: cartao.color,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  void _showStatusModal(
    BuildContext context,
    ExpenseProvider provider,
    CartaoCredito cartao,
  ) {
    // Usar o mês/ano selecionado pelo usuário, não o vencimento calculado
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
      onTap: () {
        provider.atualizarStatusFatura(
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
}
