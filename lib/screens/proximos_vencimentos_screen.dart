import 'dart:ui';
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

          // Filtrar apenas despesas que vencem após hoje (excluindo hoje)
          final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);
          final proximasDespesas =
              despesasComVencimento.where((despesa) {
                  final vencimento = DateTime(
                    despesa.ano,
                    despesa.mes,
                    despesa.diaVencimento!,
                  );
                  return vencimento.isAfter(hojeNormalizado);
                }).toList()
                ..sort((a, b) => a.diaVencimento!.compareTo(b.diaVencimento!));

          // Agrupar despesas por data de vencimento
          final Map<DateTime, List<dynamic>> despesasAgrupadas = {};
          for (var despesa in proximasDespesas) {
            final vencimento = DateTime(
              despesa.ano,
              despesa.mes,
              despesa.diaVencimento!,
            );
            if (!despesasAgrupadas.containsKey(vencimento)) {
              despesasAgrupadas[vencimento] = [];
            }
            despesasAgrupadas[vencimento]!.add(despesa);
          }

          // Converter para lista ordenada por data
          final gruposOrdenados = despesasAgrupadas.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          if (gruposOrdenados.isEmpty) {
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
            itemCount: gruposOrdenados.length,
            itemBuilder: (context, index) {
              final grupo = gruposOrdenados[index];
              final dataVencimento = grupo.key;
              final despesasDoGrupo = grupo.value;

              // Calcular diferença em dias corretamente (ignorando horas)
              final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);
              final vencimentoNormalizado = DateTime(
                dataVencimento.year,
                dataVencimento.month,
                dataVencimento.day,
              );
              final diasParaVencer = vencimentoNormalizado
                  .difference(hojeNormalizado)
                  .inDays;

              // Cores baseadas na proximidade do vencimento
              Color urgencyColor;
              Color urgencyBackgroundColor;
              String urgencyText;
              IconData urgencyIcon;

              if (diasParaVencer == 0) {
                urgencyColor = const Color(0xFFFF6B35); // Laranja vibrante
                urgencyBackgroundColor = const Color(
                  0xFFFF6B35,
                ).withOpacity(0.15);
                urgencyText = 'Vence hoje!';
                urgencyIcon = Icons.warning_rounded;
              } else if (diasParaVencer <= 3) {
                urgencyColor = const Color(0xFFE74C3C); // Vermelho
                urgencyBackgroundColor = const Color(
                  0xFFE74C3C,
                ).withOpacity(0.15);
                urgencyText = diasParaVencer == 1
                    ? 'Vence amanhã'
                    : 'Vence em $diasParaVencer dias';
                urgencyIcon = Icons.schedule_rounded;
              } else if (diasParaVencer <= 7) {
                urgencyColor = const Color(0xFFF39C12); // Amarelo
                urgencyBackgroundColor = const Color(
                  0xFFF39C12,
                ).withOpacity(0.15);
                urgencyText = 'Vence em $diasParaVencer dias';
                urgencyIcon = Icons.access_time_rounded;
              } else {
                urgencyColor = const Color(0xFF3498DB); // Azul
                urgencyBackgroundColor = const Color(
                  0xFF3498DB,
                ).withOpacity(0.15);
                urgencyText = 'Vence em $diasParaVencer dias';
                urgencyIcon = Icons.calendar_today_rounded;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        urgencyBackgroundColor,
                        urgencyBackgroundColor.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: urgencyColor.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: urgencyColor.withOpacity(0.2),
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
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            children: despesasDoGrupo.asMap().entries.map((
                              entry,
                            ) {
                              final despesaIndex = entry.key;
                              final despesa = entry.value;
                              final categoria = provider.categorias.firstWhere(
                                (cat) => cat.id == despesa.categoriaId,
                              );

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      despesaIndex < despesasDoGrupo.length - 1
                                      ? 12
                                      : 0,
                                ),
                                child: DespesaItem(
                                  despesa: despesa,
                                  categoria: categoria,
                                  showSwipeIcon: false,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                urgencyColor.withOpacity(0.2),
                                urgencyColor.withOpacity(0.1),
                              ],
                            ),
                            border: Border(
                              top: BorderSide(
                                color: urgencyColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(urgencyIcon, color: urgencyColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                urgencyText,
                                style: TextStyle(
                                  color: urgencyColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
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
          );
        },
      ),
    );
  }
}
