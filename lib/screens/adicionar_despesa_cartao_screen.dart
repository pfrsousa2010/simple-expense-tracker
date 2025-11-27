import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/despesa.dart';
import '../models/categoria.dart';
import '../models/cartao_credito.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dia_vencimento_selector_simples.dart';

class AdicionarDespesaCartaoScreen extends StatefulWidget {
  const AdicionarDespesaCartaoScreen({super.key});

  @override
  State<AdicionarDespesaCartaoScreen> createState() =>
      _AdicionarDespesaCartaoScreenState();
}

class _AdicionarDespesaCartaoScreenState
    extends State<AdicionarDespesaCartaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _estabelecimentoController = TextEditingController();
  final _numeroParcelasController = TextEditingController(text: '1');

  CartaoCredito? _cartaoSelecionado;
  Categoria? _categoriaSelecionada;
  TipoPagamentoCartao _tipoPagamento = TipoPagamentoCartao.vista;
  int _numeroParcelas = 1;
  int? _diaCompra;
  bool _isCompraOnline = false;

  @override
  void initState() {
    super.initState();
    // Inicializar com o dia de hoje
    _diaCompra = DateTime.now().day;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _estabelecimentoController.dispose();
    _numeroParcelasController.dispose();
    super.dispose();
  }

  // Calcular o mês/ano em que a despesa deve aparecer baseado no fechamento e dia da compra
  DateTime _calcularMesDespesa(CartaoCredito cartao) {
    final hoje = DateTime.now();
    final mesAtual = DateTime(hoje.year, hoje.month);

    // Se não tem diaFechamento definido, usar o mês atual
    if (cartao.diaFechamento == null) {
      return mesAtual;
    }

    // Se não tem dia da compra definido, usar o dia de hoje
    final diaCompra = _diaCompra ?? hoje.day;
    final diaFechamento = cartao.diaFechamento!;

    // Se o dia da compra é igual ou depois do fechamento, a despesa aparece no próximo mês
    if (diaCompra >= diaFechamento) {
      // Próximo mês
      if (hoje.month == 12) {
        return DateTime(hoje.year + 1, 1);
      } else {
        return DateTime(hoje.year, hoje.month + 1);
      }
    } else {
      // Mês atual
      return mesAtual;
    }
  }

  // Obter texto informativo sobre o mês da despesa
  String _obterTextoMesDespesa(CartaoCredito? cartao) {
    if (cartao == null || cartao.diaFechamento == null || _diaCompra == null) {
      return '';
    }

    final mesDespesa = _calcularMesDespesa(cartao);
    final hoje = DateTime.now();
    final mesAtual = DateTime(hoje.year, hoje.month);

    if (mesDespesa.year == mesAtual.year &&
        mesDespesa.month == mesAtual.month) {
      return 'Esta despesa aparecerá na fatura deste mês';
    } else {
      final nomeMes = Formatters.formatMonth(mesDespesa);
      return 'Esta despesa aparecerá na fatura de $nomeMes (após o fechamento no dia ${cartao.diaFechamento})';
    }
  }

  String _getTipoPagamentoText(TipoPagamentoCartao tipo) {
    switch (tipo) {
      case TipoPagamentoCartao.vista:
        return 'À Vista';
      case TipoPagamentoCartao.parcelado:
        return 'Parcelado';
      case TipoPagamentoCartao.recorrente:
        return 'Recorrente';
    }
  }

  void _salvarDespesa() {
    if (_formKey.currentState!.validate()) {
      if (_cartaoSelecionado == null ||
          _categoriaSelecionada == null ||
          _diaCompra == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, preencha todos os campos obrigatórios'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        return;
      }

      final provider = context.read<ExpenseProvider>();
      final valor = double.parse(_valorController.text);
      final parcelaId = DateTime.now().millisecondsSinceEpoch.toString();

      // Para cartão de crédito, o status sempre será "aPagar" pois o pagamento só acontece quando paga a fatura
      final status = StatusPagamento.aPagar;

      // Calcular o mês base da despesa considerando o fechamento
      final mesBase = _calcularMesDespesa(_cartaoSelecionado!);

      // Criar data de compra com o dia selecionado e o mês/ano da despesa
      // _diaCompra é obrigatório, então sempre terá valor
      DateTime dataCompra;
      try {
        dataCompra = DateTime(mesBase.year, mesBase.month, _diaCompra!);
      } catch (e) {
        // Se o dia não for válido para o mês (ex: dia 31 em fevereiro), usar o último dia do mês
        final ultimoDia = DateTime(mesBase.year, mesBase.month + 1, 0).day;
        dataCompra = DateTime(
          mesBase.year,
          mesBase.month,
          _diaCompra! > ultimoDia ? ultimoDia : _diaCompra!,
        );
      }

      if (_tipoPagamento == TipoPagamentoCartao.parcelado) {
        // Criar despesas para cada parcela
        final valorParcela = valor / _numeroParcelas;
        for (int i = 0; i < _numeroParcelas; i++) {
          final dataParcela = DateTime(mesBase.year, mesBase.month + i);
          // Para parcelas futuras, usar o mesmo dia do mês ou o último dia válido
          DateTime dataCompraParcela;
          try {
            dataCompraParcela = DateTime(
              dataParcela.year,
              dataParcela.month,
              _diaCompra!,
            );
          } catch (e) {
            final ultimoDia = DateTime(
              dataParcela.year,
              dataParcela.month + 1,
              0,
            ).day;
            dataCompraParcela = DateTime(
              dataParcela.year,
              dataParcela.month,
              _diaCompra! > ultimoDia ? ultimoDia : _diaCompra!,
            );
          }
          final despesa = Despesa(
            descricao: _descricaoController.text,
            valor: valorParcela,
            categoriaId: _categoriaSelecionada!.id!,
            mes: dataParcela.month,
            ano: dataParcela.year,
            status: status,
            cartaoCreditoId: _cartaoSelecionado!.id,
            estabelecimento: _estabelecimentoController.text,
            isCompraOnline: _isCompraOnline,
            tipoPagamento: _tipoPagamento,
            numeroParcela: i + 1,
            totalParcelas: _numeroParcelas,
            parcelaId: parcelaId,
            dataCompra: dataCompraParcela,
          );
          provider.adicionarDespesa(despesa);
        }
      } else if (_tipoPagamento == TipoPagamentoCartao.recorrente) {
        // Criar despesas recorrentes para os próximos 12 meses
        for (int i = 0; i < 12; i++) {
          // Calcular mês corretamente, tratando mudança de ano
          final dataRecorrente = DateTime(mesBase.year, mesBase.month + i);
          // Para despesas recorrentes futuras, usar o mesmo dia do mês ou o último dia válido
          DateTime dataCompraRecorrente;
          try {
            dataCompraRecorrente = DateTime(
              dataRecorrente.year,
              dataRecorrente.month,
              _diaCompra!,
            );
          } catch (e) {
            final ultimoDia = DateTime(
              dataRecorrente.year,
              dataRecorrente.month + 1,
              0,
            ).day;
            dataCompraRecorrente = DateTime(
              dataRecorrente.year,
              dataRecorrente.month,
              _diaCompra! > ultimoDia ? ultimoDia : _diaCompra!,
            );
          }
          final despesa = Despesa(
            descricao: _descricaoController.text,
            valor: valor,
            categoriaId: _categoriaSelecionada!.id!,
            mes: dataRecorrente.month,
            ano: dataRecorrente.year,
            status: status,
            cartaoCreditoId: _cartaoSelecionado!.id,
            estabelecimento: _estabelecimentoController.text,
            isCompraOnline: _isCompraOnline,
            tipoPagamento: _tipoPagamento,
            parcelaId:
                parcelaId, // Usar parcelaId para agrupar despesas recorrentes
            dataCompra: dataCompraRecorrente,
          );
          provider.adicionarDespesa(despesa);
        }
      } else {
        // Criar uma única despesa (à vista)
        final despesa = Despesa(
          descricao: _descricaoController.text,
          valor: valor,
          categoriaId: _categoriaSelecionada!.id!,
          mes: mesBase.month,
          ano: mesBase.year,
          status: status,
          cartaoCreditoId: _cartaoSelecionado!.id,
          estabelecimento: _estabelecimentoController.text,
          isCompraOnline: _isCompraOnline,
          tipoPagamento: _tipoPagamento,
          dataCompra: dataCompra,
        );
        provider.adicionarDespesa(despesa);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Despesa - Cartão de Crédito'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Cancelar',
            color: Colors.red,
          ),
          IconButton(
            onPressed: _salvarDespesa,
            icon: const Icon(Icons.check),
            tooltip: 'Salvar',
            color: Colors.green,
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final cartoes = provider.cartoesCredito;

          if (cartoes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 80,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum cartão cadastrado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cadastre um cartão antes de adicionar despesas',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<CartaoCredito>(
                    value: _cartaoSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Cartão de Crédito *',
                      border: OutlineInputBorder(),
                    ),
                    items: cartoes.map((cartao) {
                      return DropdownMenuItem(
                        value: cartao,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: cartao.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(cartao.nome),
                            const SizedBox(width: 8),
                            Text(
                              cartao.banco,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _cartaoSelecionado = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, selecione um cartão';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição *',
                      hintText: 'Ex: Compra no supermercado',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira uma descrição';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Categoria>(
                    value: _categoriaSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Categoria *',
                      border: OutlineInputBorder(),
                    ),
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
                      setState(() {
                        _categoriaSelecionada = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, selecione uma categoria';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _estabelecimentoController,
                    decoration: const InputDecoration(
                      labelText: 'Estabelecimento *',
                      hintText: 'Ex: Supermercado XYZ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o nome do estabelecimento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Valor e Compra Online na mesma linha
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _valorController,
                          decoration: const InputDecoration(
                            labelText: 'Valor *',
                            prefixText: 'R\$ ',
                            hintText: '0.00',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira um valor';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Por favor, insira um valor válido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildCompraOnlineButton()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tipo de Pagamento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTipoPagamentoButton(
                          TipoPagamentoCartao.vista,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTipoPagamentoButton(
                          TipoPagamentoCartao.parcelado,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTipoPagamentoButton(
                          TipoPagamentoCartao.recorrente,
                        ),
                      ),
                    ],
                  ),
                  if (_tipoPagamento == TipoPagamentoCartao.parcelado) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Número de Parcelas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _numeroParcelas > 1
                              ? () {
                                  setState(() {
                                    _numeroParcelas--;
                                    _numeroParcelasController.text =
                                        _numeroParcelas.toString();
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.textTertiary.withOpacity(
                              0.1,
                            ),
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _numeroParcelasController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              setState(() {
                                final num = int.tryParse(value);
                                if (num != null && num >= 1) {
                                  _numeroParcelas = num;
                                } else if (value.isEmpty) {
                                  _numeroParcelas = 1;
                                  _numeroParcelasController.text = '1';
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira o número de parcelas';
                              }
                              final num = int.tryParse(value);
                              if (num == null || num < 1) {
                                return 'Número de parcelas inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _numeroParcelas++;
                              _numeroParcelasController.text = _numeroParcelas
                                  .toString();
                            });
                          },
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.textTertiary.withOpacity(
                              0.1,
                            ),
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (_numeroParcelas > 1 && _valorController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Valor por parcela: ${Formatters.formatCurrency(double.parse(_valorController.text) / _numeroParcelas)}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  DiaVencimentoSelectorSimples(
                    title: 'Dia da Compra *',
                    initialValue: _diaCompra,
                    onChanged: (value) {
                      setState(() {
                        _diaCompra = value;
                      });
                    },
                  ),
                  if (_diaCompra == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Por favor, selecione o dia da compra',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  // Informação sobre o mês da despesa
                  if (_cartaoSelecionado != null &&
                      _obterTextoMesDespesa(_cartaoSelecionado).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _obterTextoMesDespesa(_cartaoSelecionado),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipoPagamentoButton(TipoPagamentoCartao tipo) {
    final isSelected = _tipoPagamento == tipo;

    return InkWell(
      onTap: () {
        setState(() {
          _tipoPagamento = tipo;
          if (tipo != TipoPagamentoCartao.parcelado) {
            _numeroParcelas = 1;
            _numeroParcelasController.text = '1';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textTertiary.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _getTipoPagamentoText(tipo),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCompraOnlineButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _isCompraOnline = !_isCompraOnline;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _isCompraOnline
              ? Colors.blue.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: _isCompraOnline
                ? Colors.blue
                : AppTheme.textTertiary.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Compra Online',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _isCompraOnline ? Colors.blue : AppTheme.textSecondary,
            fontWeight: _isCompraOnline ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
