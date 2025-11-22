import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/despesa.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class CopiarDespesasFixasScreen extends StatefulWidget {
  const CopiarDespesasFixasScreen({super.key});

  @override
  State<CopiarDespesasFixasScreen> createState() =>
      _CopiarDespesasFixasScreenState();
}

class _CopiarDespesasFixasScreenState extends State<CopiarDespesasFixasScreen> {
  List<DateTime> mesesSelecionados = [];
  Map<int, bool> despesasSelecionadas = {};
  List<Despesa> despesasFixas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDespesasFixas();
  }

  Future<void> _carregarDespesasFixas() async {
    final provider = context.read<ExpenseProvider>();

    // Buscar despesas fixas do mês anterior
    final mesAnterior = DateTime(
      provider.mesAtual.year,
      provider.mesAtual.month - 1,
    );

    final despesasMesAnterior = await provider.getDespesasMes(
      mesAnterior.month,
      mesAnterior.year,
    );

    setState(() {
      despesasFixas = despesasMesAnterior.where((d) => d.isFixa).toList();

      // Por padrão, todas selecionadas
      for (var despesa in despesasFixas) {
        despesasSelecionadas[despesa.id!] = true;
      }

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final mesAnterior = DateTime(
      provider.mesAtual.year,
      provider.mesAtual.month - 1,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Copiar Despesas Fixas')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : despesasFixas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.content_copy_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Não há despesas fixas em\n${Formatters.formatMonthShort(mesAnterior)} para copiar.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header mais elegante
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título e subtítulo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.date_range,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mês de Destino',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Copiando despesas fixas de ${Formatters.formatMonthShort(mesAnterior)} para:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Botão de adicionar mês mais bonito
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final data = await _showMonthPicker(
                              context,
                              mesAnterior,
                            );
                            if (data != null) {
                              setState(() {
                                // Adicionar mês se não existir
                                if (!mesesSelecionados.any(
                                  (m) =>
                                      m.month == data.month &&
                                      m.year == data.year,
                                )) {
                                  mesesSelecionados.add(data);
                                }
                              });
                            }
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: AppTheme.primaryColor,
                          ),
                          label: const Text('Adicionar Mês'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.5),
                              width: 1.5,
                            ),
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Chips dos meses selecionados
                      if (mesesSelecionados.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: mesesSelecionados.map((mes) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      mesesSelecionados.remove(mes);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          Formatters.formatMonthShort(mes),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.black26,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Divisor sutil
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.textTertiary.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Seção de despesas
                Expanded(
                  child: Column(
                    children: [
                      // Header mais elegante com checkbox "Marcar todas"
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.checklist,
                                color: AppTheme.primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Despesas Fixas (${despesasFixas.length})',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  final allSelected =
                                      !(despesasSelecionadas
                                              .values
                                              .isNotEmpty &&
                                          despesasSelecionadas.values.every(
                                            (selected) => selected,
                                          ));
                                  for (var key in despesasSelecionadas.keys) {
                                    despesasSelecionadas[key] = allSelected;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      despesasSelecionadas.values.isNotEmpty &&
                                              despesasSelecionadas.values.every(
                                                (selected) => selected,
                                              )
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: AppTheme.primaryColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Marcar todas',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lista scrollable de despesas
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: despesasFixas.length,
                          itemBuilder: (context, index) {
                            final despesa = despesasFixas[index];
                            final categoria = provider.categorias.firstWhere(
                              (cat) => cat.id == despesa.categoriaId,
                            );
                            final isSelected =
                                despesasSelecionadas[despesa.id!] ?? false;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.cardDark.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                color: isSelected
                                    ? AppTheme.primaryColor.withOpacity(0.05)
                                    : AppTheme.cardDark,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    despesasSelecionadas[despesa.id!] =
                                        !isSelected;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Checkbox customizado
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : AppTheme.textTertiary,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.black,
                                                size: 16,
                                              )
                                            : null,
                                      ),

                                      const SizedBox(width: 16),

                                      // Ícone da categoria
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          categoria.icone,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Informações da despesa
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              despesa.descricao,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              Formatters.formatCurrency(
                                                despesa.valor,
                                              ),
                                              style: const TextStyle(
                                                color: AppTheme.secondaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                if (despesa.diaVencimento !=
                                                    null) ...[
                                                  Icon(
                                                    Icons.event,
                                                    size: 14,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Dia ${despesa.diaVencimento}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                ],
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      despesa.status,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    Formatters.getStatusText(
                                                      despesa.status.index,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: _getStatusColor(
                                                        despesa.status,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão de ação fixo no bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: mesesSelecionados.isEmpty
                            ? null
                            : () => _copiarDespesas(context),
                        icon: const Icon(Icons.copy),
                        label: Text(
                          mesesSelecionados.isEmpty
                              ? 'Selecione um mês de destino'
                              : 'Copiar Despesas Selecionadas',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: AppTheme.cardDark,
                          disabledForegroundColor: AppTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _copiarDespesas(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();

    final despesasParaCopiar = despesasFixas
        .where((despesa) => despesasSelecionadas[despesa.id!] == true)
        .toList();

    if (despesasParaCopiar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos uma despesa para copiar.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Copiar para cada mês selecionado
      int totalCopiadas = 0;
      for (var mes in mesesSelecionados) {
        await provider.copiarDespesasSelecionadas(
          despesasParaCopiar,
          mes.month,
          mes.year,
        );
        totalCopiadas += despesasParaCopiar.length;
      }

      // Fechar loading
      Navigator.pop(context);

      // Voltar para a tela de despesas
      Navigator.pop(context);

      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$totalCopiadas despesa(s) copiada(s) para ${mesesSelecionados.length} mês(es) com sucesso!',
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      // Fechar loading
      Navigator.pop(context);

      // Mostrar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao copiar despesas: $e'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  }

  Color _getStatusColor(StatusPagamento status) {
    switch (status) {
      case StatusPagamento.pago:
        return Colors.green;
      case StatusPagamento.agendado:
        return Colors.blue;
      case StatusPagamento.debitoAutomatico:
        return Colors.purple;
      case StatusPagamento.aPagar:
        return Colors.orange;
    }
  }

  Future<DateTime?> _showMonthPicker(
    BuildContext context,
    DateTime mesReferencia,
  ) async {
    // Calcular o mês seguinte ao mês de referência
    final mesSeguinte = DateTime(mesReferencia.year, mesReferencia.month + 1);

    int anoSelecionado = mesSeguinte.year;
    int mesSelecionado = mesSeguinte.month;

    final meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    DateTime? resultado;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) {
          return AlertDialog(
            title: const Text('Selecionar Mês'),
            content: SizedBox(
              width: 300,
              height: 400,
              child: Column(
                children: [
                  // Seletor de ano
                  const Text(
                    'Ano:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setPickerState(() {
                            anoSelecionado--;
                          });
                        },
                      ),
                      Text(
                        anoSelecionado.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setPickerState(() {
                            anoSelecionado++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mês:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Grid de meses scrollable
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final mes = index + 1;
                        final isSelected = mes == mesSelecionado;
                        return InkWell(
                          onTap: () {
                            setPickerState(() {
                              mesSelecionado = mes;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textTertiary,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                meses[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : AppTheme.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  resultado = DateTime(anoSelecionado, mesSelecionado);
                  Navigator.pop(context);
                },
                child: const Text('Selecionar'),
              ),
            ],
          );
        },
      ),
    );

    return resultado;
  }
}
