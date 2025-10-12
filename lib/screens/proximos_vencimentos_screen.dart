import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/despesa_item.dart';

class ProximosVencimentosScreen extends StatelessWidget {
  const ProximosVencimentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Próximos Vencimentos do Mês')),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final hoje = DateTime.now();

          // Buscar todas as despesas com vencimento do mês atual ou futuros
          final despesasComVencimento = provider.despesas
              .where((despesa) => despesa.diaVencimento != null)
              .toList();

          // Filtrar despesas que ainda não venceram ou vencem hoje
          final proximasDespesas =
              despesasComVencimento.where((despesa) {
                  final vencimento = DateTime(
                    despesa.ano,
                    despesa.mes,
                    despesa.diaVencimento!,
                  );
                  return vencimento.isAfter(hoje) ||
                      (vencimento.year == hoje.year &&
                          vencimento.month == hoje.month &&
                          vencimento.day == hoje.day);
                }).toList()
                ..sort((a, b) => a.diaVencimento!.compareTo(b.diaVencimento!));

          if (proximasDespesas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 80,
                    color: Colors.blue[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma despesa a vencer este mês',
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
            itemCount: proximasDespesas.length,
            itemBuilder: (context, index) {
              final despesa = proximasDespesas[index];
              final categoria = provider.categorias.firstWhere(
                (cat) => cat.id == despesa.categoriaId,
              );

              final vencimento = DateTime(
                despesa.ano,
                despesa.mes,
                despesa.diaVencimento!,
              );
              final diasParaVencer = vencimento.difference(hoje).inDays;

              // Cor do card baseada na proximidade do vencimento
              Color? cardColor;
              if (diasParaVencer == 0) {
                cardColor = Colors.orange[50]; // Vence hoje
              } else if (diasParaVencer <= 3) {
                cardColor = Colors.red[50]; // Vence em até 3 dias
              } else if (diasParaVencer <= 7) {
                cardColor = Colors.yellow[50]; // Vence em até 7 dias
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
                  color: cardColor,
                  child: Column(
                    children: [
                      DespesaItem(despesa: despesa, categoria: categoria),
                      if (diasParaVencer <= 7)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: diasParaVencer == 0
                                ? Colors.orange
                                : diasParaVencer <= 3
                                ? Colors.red
                                : Colors.amber,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            diasParaVencer == 0
                                ? '⚠️ Vence hoje!'
                                : diasParaVencer == 1
                                ? '⏰ Vence amanhã'
                                : '⏰ Vence em $diasParaVencer dias',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
