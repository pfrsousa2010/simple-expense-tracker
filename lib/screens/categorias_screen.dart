import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/categoria.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../services/database_service.dart';

class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Consumer<ExpenseProvider>(
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
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddCategoriaDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nova Categoria'),
          ),
        ),
      ],
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

    return Dismissible(
      key: Key('categoria_${categoria.id}'),
      direction: categoria.isPadrao
          ? DismissDirection
                .horizontal // Permite swipe em ambas direções para categorias padrão (só editar)
          : DismissDirection
                .horizontal, // Permite swipe em ambas direções para categorias customizadas
      confirmDismiss: (direction) async {
        // Para categorias padrão, só permite editar (swipe esquerda)
        if (categoria.isPadrao) {
          if (direction == DismissDirection.endToStart) {
            _showEditCategoriaDialog(context, categoria);
            return false; // Não remove o item
          }
          return false; // Não remove o item em nenhum caso
        }

        // Para categorias customizadas
        if (direction == DismissDirection.startToEnd) {
          // Swipe para direita = Editar
          _showEditCategoriaDialog(context, categoria);
          return false; // Não remove o item
        } else if (direction == DismissDirection.endToStart) {
          // Swipe para esquerda = Remover
          return await _showDeleteConfirmation(context, provider, categoria);
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
      secondaryBackground: categoria.isPadrao
          ? Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
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
                        'Editar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.edit, color: Colors.white, size: 28),
                    ],
                  ),
                ),
              ),
            )
          : Container(
              margin: const EdgeInsets.only(bottom: 12),
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
      child: Card(
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
                  // Indicador visual de que pode fazer swipe
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swipe,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: percentual > 100
                                    ? AppTheme.secondaryColor
                                    : percentual > 80
                                    ? AppTheme.warningColor
                                    : AppTheme.textSecondary,
                              ),
                        ),
                        Text(
                          '${percentual.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    ExpenseProvider provider,
    Categoria categoria,
  ) async {
    // Verificar se há despesas associadas a esta categoria
    final databaseService = DatabaseService.instance;
    final quantidadeDespesas = await databaseService.contarDespesasPorCategoria(categoria.id!);

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja realmente excluir "${categoria.nome}"?'),
            if (quantidadeDespesas > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warningColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        quantidadeDespesas == 1
                            ? 'Esta categoria possui 1 despesa associada. Ao excluir, a despesa será perdida permanentemente.'
                            : 'Esta categoria possui $quantidadeDespesas despesas associadas. Ao excluir, todas as despesas serão perdidas permanentemente.',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletarCategoria(categoria.id!);
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
    return result ?? false;
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
