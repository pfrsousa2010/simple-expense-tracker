import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/categoria.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final categorias = provider.categorias;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final categoria = categorias[index];
              final gasto = provider.getGastosPorCategoria(categoria.id!);

              return _buildCategoriaCard(context, provider, categoria, gasto);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoriaDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
      ),
    );
  }

  Widget _buildCategoriaCard(
    BuildContext context,
    ExpenseProvider provider,
    Categoria categoria,
    double gasto,
  ) {
    final bool temLimite = categoria.limiteGasto != null;
    final double percentual = temLimite
        ? (gasto / categoria.limiteGasto!) * 100
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(categoria.icone, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria.nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (temLimite)
                        Text(
                          'Limite: ${Formatters.formatCurrency(categoria.limiteGasto!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (!categoria.isPadrao)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.accentColor,
                        ),
                        onPressed: () =>
                            _showEditCategoriaDialog(context, categoria),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppTheme.secondaryColor,
                        ),
                        onPressed: () => _showDeleteConfirmation(
                          context,
                          provider,
                          categoria,
                        ),
                      ),
                    ],
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.accentColor),
                    onPressed: () =>
                        _showEditCategoriaDialog(context, categoria),
                  ),
              ],
            ),
            if (temLimite) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gasto: ${Formatters.formatCurrency(gasto)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: percentual > 100
                              ? AppTheme.secondaryColor
                              : percentual > 80
                              ? AppTheme.warningColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${percentual.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: percentual > 100
                              ? AppTheme.secondaryColor
                              : percentual > 80
                              ? AppTheme.warningColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentual > 100 ? 1.0 : percentual / 100,
                      minHeight: 8,
                      backgroundColor: AppTheme.cardDark,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentual > 100
                            ? AppTheme.secondaryColor
                            : percentual > 80
                            ? AppTheme.warningColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (gasto > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Gasto: ${Formatters.formatCurrency(gasto)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoriaDialog(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final nomeController = TextEditingController();
    final limiteController = TextEditingController();
    String icone = '📦';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nova Categoria'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final novoIcone = await _showIconePicker(context);
                      if (novoIcone != null) {
                        setDialogState(() {
                          icone = novoIcone;
                        });
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor),
                      ),
                      child: Center(
                        child: Text(
                          icone,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque para alterar o ícone',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Categoria',
                      hintText: 'Ex: Streaming',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: limiteController,
                    decoration: const InputDecoration(
                      labelText: 'Limite de Gastos (Opcional)',
                      prefixText: 'R\$ ',
                      hintText: '0.00',
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
                  if (nomeController.text.isEmpty) {
                    return;
                  }

                  final categoria = Categoria(
                    nome: nomeController.text,
                    icone: icone,
                    limiteGasto: limiteController.text.isEmpty
                        ? null
                        : double.tryParse(limiteController.text),
                  );

                  provider.adicionarCategoria(categoria);
                  Navigator.pop(context);
                },
                child: const Text('Adicionar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditCategoriaDialog(
    BuildContext context,
    Categoria categoria,
  ) async {
    final provider = context.read<ExpenseProvider>();
    final nomeController = TextEditingController(text: categoria.nome);
    final limiteController = TextEditingController(
      text: categoria.limiteGasto?.toString() ?? '',
    );
    String icone = categoria.icone;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar Categoria'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final novoIcone = await _showIconePicker(context);
                      if (novoIcone != null) {
                        setDialogState(() {
                          icone = novoIcone;
                        });
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor),
                      ),
                      child: Center(
                        child: Text(
                          icone,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque para alterar o ícone',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Categoria',
                    ),
                    textCapitalization: TextCapitalization.words,
                    enabled: !categoria.isPadrao,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: limiteController,
                    decoration: const InputDecoration(
                      labelText: 'Limite de Gastos (Opcional)',
                      prefixText: 'R\$ ',
                      hintText: '0.00',
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
                  if (nomeController.text.isEmpty) {
                    return;
                  }

                  final categoriaAtualizada = categoria.copyWith(
                    nome: categoria.isPadrao
                        ? categoria.nome
                        : nomeController.text,
                    icone: icone,
                    limiteGasto: limiteController.text.isEmpty
                        ? null
                        : double.tryParse(limiteController.text),
                  );

                  provider.atualizarCategoria(categoriaAtualizada);
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
    Categoria categoria,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text('Deseja realmente excluir "${categoria.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletarCategoria(categoria.id!);
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

  Future<String?> _showIconePicker(BuildContext context) async {
    final icones = [
      '📦',
      '🍔',
      '🚗',
      '⛽',
      '🏠',
      '⚕️',
      '📚',
      '🎮',
      '📄',
      '👕',
      '💰',
      '🎬',
      '🏋️',
      '✈️',
      '🐕',
      '🎵',
      '📱',
      '💻',
      '☕',
      '🍕',
      '🛒',
      '🎁',
      '💊',
      '🚌',
      '🚕',
      '🏥',
      '🏦',
      '🎓',
      '⚽',
      '🎸',
    ];

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha um ícone'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: icones.length,
            itemBuilder: (context, index) {
              final icone = icones[index];
              return InkWell(
                onTap: () => Navigator.pop(context, icone),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(icone, style: const TextStyle(fontSize: 32)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
