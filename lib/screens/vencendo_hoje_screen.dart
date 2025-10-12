import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/despesa_item.dart';

class VencendoHojeScreen extends StatelessWidget {
  const VencendoHojeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vencendo Hoje')),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final hoje = DateTime.now();

          // Buscar despesas vencendo hoje (incluindo fixas, débito automático, etc)
          final despesasHoje =
              provider.despesas.where((despesa) {
                  if (despesa.diaVencimento == null) return false;

                  final vencimento = DateTime(
                    despesa.ano,
                    despesa.mes,
                    despesa.diaVencimento!,
                  );

                  // Verifica se vence hoje (mesmo dia, mês e ano)
                  return vencimento.year == hoje.year &&
                      vencimento.month == hoje.month &&
                      vencimento.day == hoje.day;
                }).toList()
                ..sort((a, b) => a.diaVencimento!.compareTo(b.diaVencimento!));

          if (despesasHoje.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma despesa vence hoje',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: despesasHoje.length,
            itemBuilder: (context, index) {
              final despesa = despesasHoje[index];
              final categoria = provider.categorias.firstWhere(
                (cat) => cat.id == despesa.categoriaId,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 3,
                  child: DespesaItem(despesa: despesa, categoria: categoria),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
