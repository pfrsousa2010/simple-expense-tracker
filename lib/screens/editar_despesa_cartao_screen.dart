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

class EditarDespesaCartaoScreen extends StatefulWidget {
  final Despesa despesa;
  final bool editarTodasParcelas;

  const EditarDespesaCartaoScreen({
    super.key,
    required this.despesa,
    this.editarTodasParcelas = false,
  });

  @override
  State<EditarDespesaCartaoScreen> createState() =>
      _EditarDespesaCartaoScreenState();
}

class _EditarDespesaCartaoScreenState
    extends State<EditarDespesaCartaoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricaoController;
  late final TextEditingController _valorController;
  late final TextEditingController _estabelecimentoController;

  late CartaoCredito _cartaoSelecionado;
  late Categoria _categoriaSelecionada;
  late TipoPagamentoCartao _tipoPagamento;
  int? _diaCompra;
  bool _isCompraOnline = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExpenseProvider>();
    
    _descricaoController = TextEditingController(text: widget.despesa.descricao);
    _valorController = TextEditingController(text: widget.despesa.valor.toString());
    _estabelecimentoController = TextEditingController(
      text: widget.despesa.estabelecimento ?? '',
    );

    _cartaoSelecionado = provider.cartoesCredito.firstWhere(
      (c) => c.id == widget.despesa.cartaoCreditoId,
    );
    _categoriaSelecionada = provider.categorias.firstWhere(
      (c) => c.id == widget.despesa.categoriaId,
    );
    _tipoPagamento = widget.despesa.tipoPagamento ?? TipoPagamentoCartao.vista;
    _diaCompra = widget.despesa.dataCompra?.day ?? DateTime.now().day;
    _isCompraOnline = widget.despesa.isCompraOnline;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _estabelecimentoController.dispose();
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

  void _salvarDespesa() async {
    if (_formKey.currentState!.validate()) {
      if (_diaCompra == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione o dia da compra'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        return;
      }
      final provider = context.read<ExpenseProvider>();
      final valor = double.parse(_valorController.text);

      // Calcular o mês/ano correto baseado no dia da compra e fechamento do cartão
      final mesDespesa = _calcularMesDespesa(_cartaoSelecionado);
      
      // Criar data de compra com o dia selecionado e o mês/ano calculado
      // _diaCompra é obrigatório, então sempre terá valor
      DateTime dataCompra;
      try {
        dataCompra = DateTime(mesDespesa.year, mesDespesa.month, _diaCompra!);
      } catch (e) {
        // Se o dia não for válido para o mês (ex: dia 31 em fevereiro), usar o último dia do mês
        final ultimoDia = DateTime(mesDespesa.year, mesDespesa.month + 1, 0).day;
        dataCompra = DateTime(mesDespesa.year, mesDespesa.month, _diaCompra! > ultimoDia ? ultimoDia : _diaCompra!);
      }

      final despesaAtualizada = widget.despesa.copyWith(
        descricao: _descricaoController.text,
        valor: valor,
        categoriaId: _categoriaSelecionada.id!,
        cartaoCreditoId: _cartaoSelecionado.id,
        estabelecimento: _estabelecimentoController.text,
        isCompraOnline: _isCompraOnline,
        tipoPagamento: _tipoPagamento,
        mes: mesDespesa.month,
        ano: mesDespesa.year,
        dataCompra: dataCompra,
      );

      // Se for para editar esta e as próximas parcelas/recorrentes
      if (widget.editarTodasParcelas &&
          widget.despesa.parcelaId != null &&
          (widget.despesa.tipoPagamento == TipoPagamentoCartao.parcelado ||
              widget.despesa.tipoPagamento == TipoPagamentoCartao.recorrente)) {
        await provider.atualizarParcelasFuturas(
          widget.despesa.parcelaId!,
          despesaAtualizada,
          widget.despesa.tipoPagamento == TipoPagamentoCartao.parcelado,
          widget.despesa.numeroParcela,
          widget.despesa.mes,
          widget.despesa.ano,
        );
      } else {
        provider.atualizarDespesa(despesaAtualizada);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Despesa - Cartão de Crédito'),
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

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.editarTodasParcelas &&
                      widget.despesa.parcelaId != null &&
                      (widget.despesa.tipoPagamento == TipoPagamentoCartao.parcelado ||
                          widget.despesa.tipoPagamento == TipoPagamentoCartao.recorrente))
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.despesa.tipoPagamento == TipoPagamentoCartao.parcelado
                                  ? 'As alterações serão aplicadas a esta parcela e às próximas.'
                                  : 'As alterações serão aplicadas a esta despesa e às próximas.',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        _cartaoSelecionado = value!;
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
                      Expanded(
                        flex: 1,
                        child: CheckboxListTile(
                          title: const Text('Compra Online'),
                          value: _isCompraOnline,
                          onChanged: (value) {
                            setState(() {
                              _isCompraOnline = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
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
                        _categoriaSelecionada = value!;
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
                  if (_obterTextoMesDespesa(_cartaoSelecionado).isNotEmpty)
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
                  if (widget.despesa.tipoPagamento == TipoPagamentoCartao.parcelado &&
                      widget.despesa.numeroParcela != null &&
                      widget.despesa.totalParcelas != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
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
                                'Parcela ${widget.despesa.numeroParcela}/${widget.despesa.totalParcelas} - Não é possível alterar parcelas em despesas já criadas',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
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
}

