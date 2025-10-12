import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/despesa.dart';
import '../models/categoria.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/despesa_item.dart';

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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copiar_fixas') {
                _showCopiarDespesasFixasDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copiar_fixas',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Copiar Despesas Fixas'),
                  ],
                ),
              ),
            ],
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

          final despesasPorCategoria = provider.getDespesasPorCategoria();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: despesasPorCategoria.length,
            itemBuilder: (context, index) {
              final categoria = despesasPorCategoria.keys.elementAt(index);
              final despesasCategoria = despesasPorCategoria[categoria]!;

              return _buildCategoriaSection(
                context,
                provider,
                categoria,
                despesasCategoria,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDespesaDialog(context),
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DespesaItem(
              despesa: despesa,
              categoria: categoria,
              onTap: () => _showEditDespesaDialog(context, despesa),
              onDelete: () =>
                  _showDeleteConfirmation(context, provider, despesa),
            ),
          );
        }),
        const Divider(height: 32),
      ],
    );
  }

  Future<void> _showAddDespesaDialog(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();
    Categoria? categoriaSelecionada;
    int? diaVencimento;
    StatusPagamento statusSelecionado = StatusPagamento.aPagar;
    bool isFixa = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Adicionar Despesa'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex: Conta de luz',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valorController,
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Categoria>(
                    initialValue: categoriaSelecionada,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: provider.categorias.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Text(
                              cat.icone,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(cat.nome),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        categoriaSelecionada = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<StatusPagamento>(
                    initialValue: statusSelecionado,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: StatusPagamento.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(Formatters.getStatusText(status.index)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        statusSelecionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: diaVencimento,
                    decoration: const InputDecoration(
                      labelText: 'Dia do Vencimento (Opcional)',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sem vencimento'),
                      ),
                      ...List.generate(31, (i) => i + 1).map((dia) {
                        return DropdownMenuItem(
                          value: dia,
                          child: Text('Dia $dia'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        diaVencimento = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: isFixa,
                    onChanged: (value) {
                      setDialogState(() {
                        isFixa = value ?? false;
                      });
                    },
                    title: const Text('Despesa Fixa'),
                    subtitle: const Text('Pode ser reaproveitada mensalmente'),
                    contentPadding: EdgeInsets.zero,
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
                  if (descricaoController.text.isEmpty ||
                      valorController.text.isEmpty ||
                      categoriaSelecionada == null) {
                    return;
                  }

                  final despesa = Despesa(
                    descricao: descricaoController.text,
                    valor: double.parse(valorController.text),
                    categoriaId: categoriaSelecionada!.id!,
                    mes: provider.mesAtual.month,
                    ano: provider.mesAtual.year,
                    diaVencimento: diaVencimento,
                    status: statusSelecionado,
                    isFixa: isFixa,
                  );

                  provider.adicionarDespesa(despesa);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditDespesaDialog(
    BuildContext context,
    Despesa despesa,
  ) async {
    final provider = context.read<ExpenseProvider>();
    final descricaoController = TextEditingController(text: despesa.descricao);
    final valorController = TextEditingController(
      text: despesa.valor.toString(),
    );
    Categoria? categoriaSelecionada = provider.categorias.firstWhere(
      (cat) => cat.id == despesa.categoriaId,
    );
    int? diaVencimento = despesa.diaVencimento;
    StatusPagamento statusSelecionado = despesa.status;
    bool isFixa = despesa.isFixa;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar Despesa'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valorController,
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Categoria>(
                    initialValue: categoriaSelecionada,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: provider.categorias.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Text(
                              cat.icone,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(cat.nome),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        categoriaSelecionada = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<StatusPagamento>(
                    initialValue: statusSelecionado,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: StatusPagamento.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(Formatters.getStatusText(status.index)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        statusSelecionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: diaVencimento,
                    decoration: const InputDecoration(
                      labelText: 'Dia do Vencimento (Opcional)',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sem vencimento'),
                      ),
                      ...List.generate(31, (i) => i + 1).map((dia) {
                        return DropdownMenuItem(
                          value: dia,
                          child: Text('Dia $dia'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        diaVencimento = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: isFixa,
                    onChanged: (value) {
                      setDialogState(() {
                        isFixa = value ?? false;
                      });
                    },
                    title: const Text('Despesa Fixa'),
                    subtitle: const Text('Pode ser reaproveitada mensalmente'),
                    contentPadding: EdgeInsets.zero,
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
                  if (descricaoController.text.isEmpty ||
                      valorController.text.isEmpty ||
                      categoriaSelecionada == null) {
                    return;
                  }

                  final despesaAtualizada = despesa.copyWith(
                    descricao: descricaoController.text,
                    valor: double.parse(valorController.text),
                    categoriaId: categoriaSelecionada!.id!,
                    diaVencimento: diaVencimento,
                    status: statusSelecionado,
                    isFixa: isFixa,
                  );

                  provider.atualizarDespesa(despesaAtualizada);
                  Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ExpenseProvider provider,
    Despesa despesa,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Despesa'),
        content: Text('Deseja realmente excluir "${despesa.descricao}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletarDespesa(despesa.id!);
              Navigator.pop(context);
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
  }

  Future<void> _showCopiarDespesasFixasDialog(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();

    // Buscar despesas fixas do mês anterior (mesmo padrão das receitas)
    final mesAnterior = DateTime(
      provider.mesAtual.year,
      provider.mesAtual.month - 1,
    );

    final despesasMesAnterior = await provider.getDespesasMes(
      mesAnterior.month,
      mesAnterior.year,
    );

    if (!context.mounted) return;

    final despesasFixas = despesasMesAnterior.where((d) => d.isFixa).toList();

    if (despesasFixas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não há despesas fixas em ${Formatters.formatMonthShort(mesAnterior)} para copiar.',
          ),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    List<DateTime> mesesSelecionados = [];

    // Map para controlar quais despesas estão selecionadas
    final Map<int, bool> despesasSelecionadas = {};
    for (var despesa in despesasFixas) {
      despesasSelecionadas[despesa.id!] =
          true; // Por padrão, todas selecionadas
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Copiar Despesas Fixas'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecione os meses para onde deseja copiar as despesas fixas:',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final data = await _showMonthPicker(context);
                      if (data != null) {
                        setDialogState(() {
                          // Adicionar mês se não existir
                          if (!mesesSelecionados.any(
                            (m) => m.month == data.month && m.year == data.year,
                          )) {
                            mesesSelecionados.add(data);
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Mês'),
                  ),
                  if (mesesSelecionados.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Meses selecionados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: mesesSelecionados.map((mes) {
                        return Chip(
                          label: Text(Formatters.formatMonthShort(mes)),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setDialogState(() {
                              mesesSelecionados.remove(mes);
                            });
                          },
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.2,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Despesas fixas encontradas:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: despesasSelecionadas.values.every(
                            (selected) => selected,
                          ),
                          tristate: true,
                          onChanged: (value) {
                            setDialogState(() {
                              final allSelected = value == true;
                              for (var key in despesasSelecionadas.keys) {
                                despesasSelecionadas[key] = allSelected;
                              }
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const Text('Marcar todas'),
                      ],
                    ),
                    ...despesasFixas.map((despesa) {
                      return CheckboxListTile(
                        value: despesasSelecionadas[despesa.id!] ?? false,
                        onChanged: (value) {
                          setDialogState(() {
                            despesasSelecionadas[despesa.id!] = value ?? false;
                          });
                        },
                        title: Text(despesa.descricao),
                        subtitle: Text(
                          Formatters.formatCurrency(despesa.valor),
                          style: const TextStyle(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: mesesSelecionados.isEmpty
                    ? null
                    : () async {
                        final despesasParaCopiar = despesasFixas
                            .where(
                              (despesa) =>
                                  despesasSelecionadas[despesa.id!] == true,
                            )
                            .toList();

                        print(
                          'DEBUG: Despesas selecionadas: ${despesasParaCopiar.map((d) => d.descricao).join(", ")}',
                        );
                        print('DEBUG: Map de seleção: $despesasSelecionadas');

                        if (despesasParaCopiar.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selecione pelo menos uma despesa para copiar.',
                              ),
                              backgroundColor: AppTheme.warningColor,
                            ),
                          );
                          return;
                        }

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

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$totalCopiadas despesa(s) copiada(s) para ${mesesSelecionados.length} mês(es) com sucesso!',
                            ),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                child: const Text('Copiar Selecionadas'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<DateTime?> _showMonthPicker(BuildContext context) async {
    int anoSelecionado = DateTime.now().year;
    int mesSelecionado = DateTime.now().month;

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
                  // Grid de meses
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
