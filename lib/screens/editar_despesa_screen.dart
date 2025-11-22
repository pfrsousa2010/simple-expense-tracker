import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/despesa.dart';
import '../models/categoria.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dia_vencimento_selector_simples.dart';

class EditarDespesaScreen extends StatefulWidget {
  final Despesa despesa;

  const EditarDespesaScreen({super.key, required this.despesa});

  @override
  State<EditarDespesaScreen> createState() => _EditarDespesaScreenState();
}

class _EditarDespesaScreenState extends State<EditarDespesaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricaoController;
  late final TextEditingController _valorController;
  late Categoria _categoriaSelecionada;
  int? _diaVencimento;
  late StatusPagamento _statusSelecionado;
  late bool _isFixa;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExpenseProvider>();
    _descricaoController = TextEditingController(
      text: widget.despesa.descricao,
    );
    _valorController = TextEditingController(
      text: widget.despesa.valor.toString(),
    );
    _categoriaSelecionada = provider.categorias.firstWhere(
      (cat) => cat.id == widget.despesa.categoriaId,
    );
    _diaVencimento = widget.despesa.diaVencimento;
    _statusSelecionado = widget.despesa.status;
    _isFixa = widget.despesa.isFixa;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
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

    if (_categoriaSelecionada.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma categoria'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final despesaAtualizada = widget.despesa.copyWith(
      descricao: _descricaoController.text,
      valor: double.parse(_valorController.text),
      categoriaId: _categoriaSelecionada.id!,
      diaVencimento: _diaVencimento,
      status: _statusSelecionado,
      isFixa: _isFixa,
    );

    final provider = context.read<ExpenseProvider>();
    provider.atualizarDespesa(despesaAtualizada);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Despesa'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Cancelar',
          ),
          IconButton(
            onPressed: _salvarDespesa,
            icon: const Icon(Icons.check),
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
              DiaVencimentoSelectorSimples(
                initialValue: _diaVencimento,
                onChanged: (value) {
                  setState(() {
                    _diaVencimento = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: CheckboxListTile(
                  value: _isFixa,
                  onChanged: (value) {
                    setState(() {
                      _isFixa = value ?? false;
                    });
                  },
                  title: const Text('Despesa Fixa'),
                  subtitle: const Text('Pode ser reaproveitada mensalmente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
