import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/fonte_renda.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class ReceitasScreen extends StatefulWidget {
  const ReceitasScreen({super.key});

  @override
  State<ReceitasScreen> createState() => _ReceitasScreenState();
}

class _ReceitasScreenState extends State<ReceitasScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copiar receitas do mês anterior',
            onPressed: () => _showCopiarReceitasDialog(context),
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final receitas = provider.fontesRenda;

          if (receitas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma receita cadastrada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione suas fontes de renda',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: receitas.length,
            itemBuilder: (context, index) {
              final receita = receitas[index];
              return _buildReceitaCard(context, provider, receita);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReceitaDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }

  Widget _buildReceitaCard(
    BuildContext context,
    ExpenseProvider provider,
    FonteRenda receita,
  ) {
    return Dismissible(
      key: Key('receita_${receita.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe para direita = Editar
          _showEditReceitaDialog(context, receita);
          return false; // Não remove o item
        } else if (direction == DismissDirection.endToStart) {
          // Swipe para esquerda = Remover
          return await _showDeleteConfirmation(context, provider, receita);
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
      secondaryBackground: Container(
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
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.attach_money,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          title: Text(
            receita.nome,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            Formatters.formatCurrency(receita.valor),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swipe, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
              ],
            ),
          ),
          onTap: () => _showEditReceitaDialog(context, receita),
        ),
      ),
    );
  }

  Future<void> _showAddReceitaDialog(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final nomeController = TextEditingController();
    final valorController = TextEditingController();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Receita'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Fonte',
                  hintText: 'Ex: Salário, Freelance',
                ),
                textCapitalization: TextCapitalization.words,
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
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
              if (nomeController.text.isEmpty || valorController.text.isEmpty) {
                return;
              }

              final receita = FonteRenda(
                nome: nomeController.text,
                valor: double.parse(valorController.text),
                mes: provider.mesAtual.month,
                ano: provider.mesAtual.year,
              );

              provider.adicionarFonteRenda(receita);
              Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditReceitaDialog(
    BuildContext context,
    FonteRenda receita,
  ) async {
    final provider = context.read<ExpenseProvider>();
    final nomeController = TextEditingController(text: receita.nome);
    final valorController = TextEditingController(
      text: receita.valor.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Receita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome da Fonte'),
              textCapitalization: TextCapitalization.words,
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
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isEmpty || valorController.text.isEmpty) {
                return;
              }

              final receitaAtualizada = receita.copyWith(
                nome: nomeController.text,
                valor: double.parse(valorController.text),
              );

              provider.atualizarFonteRenda(receitaAtualizada);
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    ExpenseProvider provider,
    FonteRenda receita,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Receita'),
        content: Text('Deseja realmente excluir "${receita.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletarFonteRenda(receita.id!);
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

  Future<void> _showCopiarReceitasDialog(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();

    // Buscar receitas do mês anterior
    final mesAnterior = DateTime(
      provider.mesAtual.year,
      provider.mesAtual.month - 1,
    );

    final receitasMesAnterior = await provider.getFontesRendaMes(
      mesAnterior.month,
      mesAnterior.year,
    );

    if (!context.mounted) return;

    if (receitasMesAnterior.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não há receitas em ${Formatters.formatMonthShort(mesAnterior)} para copiar.',
          ),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Map para controlar quais receitas estão selecionadas
    final Map<int, bool> receitasSelecionadas = {};
    for (var receita in receitasMesAnterior) {
      receitasSelecionadas[receita.id!] =
          true; // Por padrão, todas selecionadas
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Copiar Receitas'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecione as receitas de ${Formatters.formatMonthShort(mesAnterior)} para copiar:',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Receitas encontradas:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...receitasMesAnterior.map((receita) {
                    return CheckboxListTile(
                      value: receitasSelecionadas[receita.id!] ?? false,
                      onChanged: (value) {
                        setDialogState(() {
                          receitasSelecionadas[receita.id!] = value ?? false;
                        });
                      },
                      title: Text(receita.nome),
                      subtitle: Text(
                        Formatters.formatCurrency(receita.valor),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      activeColor: AppTheme.primaryColor,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
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
                  final receitasParaCopiar = receitasMesAnterior
                      .where(
                        (receita) => receitasSelecionadas[receita.id!] == true,
                      )
                      .toList();

                  if (receitasParaCopiar.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Selecione pelo menos uma receita para copiar.',
                        ),
                        backgroundColor: AppTheme.warningColor,
                      ),
                    );
                    return;
                  }

                  for (var receita in receitasParaCopiar) {
                    final novaReceita = FonteRenda(
                      nome: receita.nome,
                      valor: receita.valor,
                      mes: provider.mesAtual.month,
                      ano: provider.mesAtual.year,
                    );
                    provider.adicionarFonteRenda(novaReceita);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${receitasParaCopiar.length} receita(s) copiada(s) com sucesso!',
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
}
