import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/despesa.dart';
import '../models/categoria.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dia_vencimento_selector_simples.dart';

class AdicionarDespesaScreen extends StatefulWidget {
  const AdicionarDespesaScreen({super.key});

  @override
  State<AdicionarDespesaScreen> createState() => _AdicionarDespesaScreenState();
}

class _AdicionarDespesaScreenState extends State<AdicionarDespesaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _estabelecimentoController = TextEditingController();
  Categoria? _categoriaSelecionada;
  int? _diaVencimento;
  StatusPagamento _statusSelecionado =
      StatusPagamento.pago; // Padrão: Pago (despesa não fixa)
  bool _isFixa = false;
  DateTime? _dataCompra;

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _estabelecimentoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataCompra() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataCompra ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _dataCompra) {
      setState(() {
        _dataCompra = picked;
      });
    }
  }

  Map<String, dynamic> _getStatusInfo(StatusPagamento status) {
    switch (status) {
      case StatusPagamento.pago:
        return {'color': AppTheme.primaryColor, 'icon': Icons.check_circle};
      case StatusPagamento.agendado:
        return {'color': AppTheme.warningColor, 'icon': Icons.schedule};
      case StatusPagamento.debitoAutomatico:
        return {'color': AppTheme.accentColor, 'icon': Icons.autorenew};
      case StatusPagamento.aPagar:
        return {'color': AppTheme.secondaryColor, 'icon': Icons.pending};
    }
  }

  String _getStatusText(StatusPagamento status) {
    switch (status) {
      case StatusPagamento.debitoAutomatico:
        return 'Débito Automático';
      default:
        return Formatters.getStatusText(status.index);
    }
  }

  Widget _buildStatusButton(StatusPagamento status, {bool fullWidth = false}) {
    final isSelected = _statusSelecionado == status;
    final statusInfo = _getStatusInfo(status);
    final statusColor = statusInfo['color'] as Color;
    final statusText = _getStatusText(status);

    return InkWell(
      onTap: () {
        setState(() {
          _statusSelecionado = status;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? statusColor : statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? statusColor : statusColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(
              statusInfo['icon'] as IconData,
              size: 16,
              color: isSelected ? Colors.white : statusColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                statusText,
                style: TextStyle(
                  color: isSelected ? Colors.white : statusColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _salvarDespesa() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma categoria'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final provider = context.read<ExpenseProvider>();

    final despesa = Despesa(
      descricao: _descricaoController.text,
      valor: double.parse(_valorController.text),
      categoriaId: _categoriaSelecionada!.id!,
      mes: provider.mesAtual.month,
      ano: provider.mesAtual.year,
      diaVencimento: _isFixa ? _diaVencimento : null,
      status: _statusSelecionado,
      isFixa: _isFixa,
      dataCompra: _isFixa ? null : _dataCompra,
      estabelecimento: _isFixa
          ? null
          : (_estabelecimentoController.text.isEmpty
                ? null
                : _estabelecimentoController.text),
    );

    provider.adicionarDespesa(despesa);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Despesa'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Cancelar',
          ),
          IconButton(
            onPressed: _salvarDespesa,
            icon: const Icon(Icons.check, color: Colors.green),
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex: Conta de luz',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<Categoria>(
                value: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: provider.categorias.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Text(cat.icone, style: const TextStyle(fontSize: 20)),
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
              const Text(
                'Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  // Primeira linha: A pagar, Agendado, Débito Automático
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusButton(StatusPagamento.aPagar),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusButton(StatusPagamento.agendado),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusButton(
                          StatusPagamento.debitoAutomatico,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Segunda linha: Pago (preenche toda a linha)
                  _buildStatusButton(StatusPagamento.pago, fullWidth: true),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: CheckboxListTile(
                  value: _isFixa,
                  onChanged: (value) {
                    setState(() {
                      _isFixa = value ?? false;
                      if (_isFixa) {
                        // Limpar campos de despesa não fixa
                        _estabelecimentoController.clear();
                        _dataCompra = null;
                        // Status padrão para despesa fixa: A Pagar
                        _statusSelecionado = StatusPagamento.aPagar;
                      } else {
                        // Limpar campo de dia de vencimento
                        _diaVencimento = null;
                        // Status padrão para despesa não fixa: Pago
                        _statusSelecionado = StatusPagamento.pago;
                      }
                    });
                  },
                  title: const Text('Despesa Fixa'),
                  subtitle: const Text('Pode ser reaproveitada mensalmente'),
                ),
              ),
              if (_isFixa) ...[
                const SizedBox(height: 16),
                DiaVencimentoSelectorSimples(
                  initialValue: _diaVencimento,
                  onChanged: (value) {
                    setState(() {
                      _diaVencimento = value;
                    });
                  },
                ),
              ] else ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _estabelecimentoController,
                  decoration: const InputDecoration(
                    labelText: 'Estabelecimento',
                    hintText: 'Ex: Supermercado XYZ',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selecionarDataCompra,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data da Compra',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dataCompra != null
                          ? DateFormat(
                              'dd/MM/yyyy',
                              'pt_BR',
                            ).format(_dataCompra!)
                          : 'Selecione a data',
                      style: TextStyle(
                        color: _dataCompra != null
                            ? null
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
