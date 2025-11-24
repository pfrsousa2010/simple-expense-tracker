import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/cartao_credito.dart';
import '../utils/app_theme.dart';
import 'adicionar_editar_cartao_screen.dart';

class CartoesCreditoScreen extends StatelessWidget {
  const CartoesCreditoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final cartoes = provider.cartoesCredito;

        return Stack(
          children: [
            cartoes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 80,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum cartão cadastrado',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adicione seus cartões de crédito',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartoes.length,
                    itemBuilder: (context, index) {
                      final cartao = cartoes[index];
                      return _buildCartaoCard(context, provider, cartao);
                    },
                  ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdicionarEditarCartaoScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Novo Cartão'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartaoCard(
    BuildContext context,
    ExpenseProvider provider,
    CartaoCredito cartao,
  ) {
    return Dismissible(
      key: Key('cartao_${cartao.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe para direita = Editar
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdicionarEditarCartaoScreen(cartao: cartao),
            ),
          );
          return false; // Não remove o item
        } else if (direction == DismissDirection.endToStart) {
          // Swipe para esquerda = Remover
          return await _showDeleteConfirmation(context, provider, cartao);
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cartao.color, cartao.color.withOpacity(0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: cartao.color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Padrão de fundo
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Conteúdo do cartão
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.credit_card, color: Colors.white, size: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swipe, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartao.numeroFormatado,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cartao.nome.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cartao.banco,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
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
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    ExpenseProvider provider,
    CartaoCredito cartao,
  ) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Cartão'),
        content: Text('Deseja realmente excluir "${cartao.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletarCartaoCredito(cartao.id!);
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
}
