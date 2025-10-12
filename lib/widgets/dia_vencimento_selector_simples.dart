import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DiaVencimentoSelectorSimples extends StatefulWidget {
  final int? initialValue;
  final Function(int?) onChanged;

  const DiaVencimentoSelectorSimples({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<DiaVencimentoSelectorSimples> createState() =>
      _DiaVencimentoSelectorSimplesState();
}

class _DiaVencimentoSelectorSimplesState
    extends State<DiaVencimentoSelectorSimples> {
  int? diaSelecionado;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    diaSelecionado = widget.initialValue;

    // Inicializar o controller com a posição correta
    _scrollController = FixedExtentScrollController(
      initialItem: diaSelecionado != null ? diaSelecionado! : 0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Método para sincronizar a roleta com o valor atual
  void _syncPickerWithValue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final targetIndex = diaSelecionado != null ? diaSelecionado! : 0;
        _scrollController.animateToItem(
          targetIndex,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dia do Vencimento (Opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),

        // Container com roleta de dias
        Container(
          height: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[700]!.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header com dia selecionado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        diaSelecionado == null
                            ? Icons.calendar_today_outlined
                            : Icons.calendar_today,
                        color: diaSelecionado == null
                            ? Colors.grey[400]
                            : Colors.blue[300],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        diaSelecionado == null
                            ? 'Nenhum dia selecionado'
                            : 'Dia $diaSelecionado',
                        style: TextStyle(
                          color: diaSelecionado == null
                              ? Colors.grey[400]
                              : Colors.blue[300],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (diaSelecionado != null)
                    GestureDetector(
                      onTap: () => _removerSelecao(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.red[600],
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Roleta CupertinoPicker
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: _scrollController,
                    onSelectedItemChanged: (index) {
                      if (index == 0) {
                        _selecionarDia(null);
                      } else {
                        _selecionarDia(index);
                      }
                    },
                    children: [
                      // Opção "Sem vencimento"
                      Center(
                        child: Text(
                          'Sem vencimento',
                          style: TextStyle(
                            color: diaSelecionado == null
                                ? Colors.blue[300]
                                : Colors.grey[300],
                            fontWeight: diaSelecionado == null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Dias 1-31
                      ...List.generate(31, (index) {
                        final dia = index + 1;
                        final isSelected = dia == diaSelecionado;

                        return Center(
                          child: Text(
                            'Dia $dia',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.blue[300]
                                  : Colors.grey[300],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selecionarDia(int? dia) {
    setState(() {
      diaSelecionado = dia;
    });
    widget.onChanged(dia);
  }

  void _removerSelecao() {
    setState(() {
      diaSelecionado = null;
    });
    widget.onChanged(null);

    // Animar a roleta de volta para "Sem vencimento"
    _syncPickerWithValue();
  }
}
