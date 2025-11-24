import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/cartao_credito.dart';
import '../utils/app_theme.dart';

class AdicionarEditarCartaoScreen extends StatefulWidget {
  final CartaoCredito? cartao; // null para adicionar, não null para editar

  const AdicionarEditarCartaoScreen({super.key, this.cartao});

  @override
  State<AdicionarEditarCartaoScreen> createState() =>
      _AdicionarEditarCartaoScreenState();
}

class _AdicionarEditarCartaoScreenState
    extends State<AdicionarEditarCartaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _bancoController = TextEditingController();
  final _numeroController = TextEditingController();
  int _corSelecionada = 0xFF2196F3; // Azul padrão

  final List<int> _coresDisponiveis = [
    0xFF2196F3, // Azul
    0xFF4CAF50, // Verde
    0xFFFF9800, // Laranja
    0xFF9C27B0, // Roxo
    0xFFE91E63, // Rosa
    0xFF00BCD4, // Ciano
    0xFFFF5722, // Vermelho
    0xFF795548, // Marrom
    0xFF607D8B, // Azul acinzentado
    0xFF3F51B5, // Índigo
  ];

  @override
  void initState() {
    super.initState();
    if (widget.cartao != null) {
      _nomeController.text = widget.cartao!.nome;
      _bancoController.text = widget.cartao!.banco;
      _numeroController.text = widget.cartao!.numero;
      _corSelecionada = widget.cartao!.cor;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _bancoController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  void _salvarCartao() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<ExpenseProvider>();

      if (widget.cartao == null) {
        // Adicionar novo cartão
        final novoCartao = CartaoCredito(
          nome: _nomeController.text,
          banco: _bancoController.text,
          numero: _numeroController.text,
          cor: _corSelecionada,
        );
        provider.adicionarCartaoCredito(novoCartao);
      } else {
        // Editar cartão existente
        final cartaoAtualizado = widget.cartao!.copyWith(
          nome: _nomeController.text,
          banco: _bancoController.text,
          numero: _numeroController.text,
          cor: _corSelecionada,
        );
        provider.atualizarCartaoCredito(cartaoAtualizado);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cartao == null ? 'Novo Cartão' : 'Editar Cartão'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Cancelar',
            color: Colors.red,
          ),
          IconButton(
            onPressed: _salvarCartao,
            icon: const Icon(Icons.check),
            tooltip: 'Salvar',
            color: Colors.green,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview do cartão
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(_corSelecionada),
                      Color(_corSelecionada).withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(_corSelecionada).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: RadialGradient(
                            center: Alignment.topRight,
                            radius: 1.5,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(
                                Icons.credit_card,
                                color: Colors.white,
                                size: 32,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _numeroController.text.isEmpty
                                    ? '**** **** **** ****'
                                    : _numeroController.text.length <= 4
                                    ? '**** **** **** ${_numeroController.text}'
                                    : '**** **** **** ${_numeroController.text.substring(_numeroController.text.length - 4)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _nomeController.text.isEmpty
                                    ? 'NOME DO CARTÃO'
                                    : _nomeController.text.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _bancoController.text.isEmpty
                                    ? 'BANCO'
                                    : _bancoController.text,
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

              // Seletor de cor
              Text(
                'Cor do Cartão',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _coresDisponiveis.map((cor) {
                  final isSelected = _corSelecionada == cor;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _corSelecionada = cor;
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(cor),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(cor).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Campos de formulário
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Cartão',
                  hintText: 'Ex: Cartão Principal',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do cartão';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bancoController,
                decoration: const InputDecoration(
                  labelText: 'Banco',
                  hintText: 'Ex: Banco do Brasil',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do banco';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número do Cartão',
                  hintText: 'Últimos 4 dígitos ou número completo',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o número do cartão';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
