import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fonte_renda.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class CopiarReceitasScreen extends StatefulWidget {
  const CopiarReceitasScreen({super.key});

  @override
  State<CopiarReceitasScreen> createState() => _CopiarReceitasScreenState();
}

class _CopiarReceitasScreenState extends State<CopiarReceitasScreen> {
  bool isLoading = true;
  List<FonteRenda> receitasAnteriores = [];
  final Map<int, bool> receitasSelecionadas = {};

  @override
  void initState() {
    super.initState();
    _carregarReceitas();
  }

  Future<void> _carregarReceitas() async {
    final provider = context.read<ExpenseProvider>();
    final mesAnterior = DateTime(
      provider.mesAtual.year,
      provider.mesAtual.month - 1,
    );

    final receitas = await provider.getFontesRendaMes(
      mesAnterior.month,
      mesAnterior.year,
    );

    setState(() {
      receitasAnteriores = receitas;
      for (var receita in receitasAnteriores) {
        if (receita.id != null) {
          receitasSelecionadas[receita.id!] = true;
        }
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
      appBar: AppBar(
        title: const Text('Copiar Receitas'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : receitasAnteriores.isEmpty
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
                        'Não há receitas em\n${Formatters.formatMonthShort(mesAnterior)} para copiar.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      'Receitas de ${Formatters.formatMonthShort(mesAnterior)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Selecione as receitas que deseja copiar para ${Formatters.formatMonthShort(provider.mesAtual)}.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${receitasAnteriores.length} receita(s) encontrada(s)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    final marcarTodas = receitasSelecionadas.values
                                            .any((value) => !value) ||
                                        receitasSelecionadas.values.isEmpty;
                                    setState(() {
                                      for (var key in receitasSelecionadas.keys) {
                                        receitasSelecionadas[key] = marcarTodas;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.primaryColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            AppTheme.primaryColor.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          receitasSelecionadas.values.isNotEmpty &&
                                                  receitasSelecionadas.values
                                                      .every((value) => value)
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          color: AppTheme.primaryColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          receitasSelecionadas.values.isNotEmpty &&
                                                  receitasSelecionadas.values
                                                      .every((value) => value)
                                              ? 'Desmarcar todas'
                                              : 'Marcar todas',
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
                        ],
                      ),
                    ),
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
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        itemCount: receitasAnteriores.length,
                        itemBuilder: (context, index) {
                          final receita = receitasAnteriores[index];
                          final isSelected =
                              receitasSelecionadas[receita.id!] ?? false;

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
                                  ? AppTheme.primaryColor.withOpacity(0.06)
                                  : AppTheme.cardDark,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  receitasSelecionadas[receita.id!] = !isSelected;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
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
                                        borderRadius: BorderRadius.circular(6),
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
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.monetization_on_outlined,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            receita.nome,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            Formatters.formatCurrency(
                                              receita.valor,
                                            ),
                                            style: const TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
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
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: ElevatedButton.icon(
                          onPressed: () => _copiarReceitas(context),
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar Selecionadas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _copiarReceitas(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final selecionadas = receitasAnteriores
        .where((receita) => receitasSelecionadas[receita.id!] == true)
        .toList();

    if (selecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos uma receita para copiar.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (var receita in selecionadas) {
        final novaReceita = FonteRenda(
          nome: receita.nome,
          valor: receita.valor,
          mes: provider.mesAtual.month,
          ano: provider.mesAtual.year,
        );
        await provider.adicionarFonteRenda(novaReceita);
      }

      if (!mounted) return;

      Navigator.pop(context); // fecha loading
      Navigator.pop(context); // volta para tela anterior

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selecionadas.length} receita(s) copiada(s) com sucesso!',
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao copiar receitas: $e'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  }
}

