import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/despesa.dart';
import '../models/categoria.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/despesa_item.dart';
import 'copiar_despesas_fixas_screen.dart';

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
          _showEditDespesaDialog(context, despesa);
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
          onTap: () => _showEditDespesaDialog(context, despesa),
        ),
      ),
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

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    ExpenseProvider provider,
    Despesa despesa,
  ) async {
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
}
