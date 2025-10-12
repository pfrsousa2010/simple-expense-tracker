import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DiaVencimentoSelector extends StatefulWidget {
  final int? initialValue;
  final Function(int?) onChanged;
  final TipoSeletor tipoSeletor;

  const DiaVencimentoSelector({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.tipoSeletor = TipoSeletor.grid,
  });

  @override
  State<DiaVencimentoSelector> createState() => _DiaVencimentoSelectorState();
}

enum TipoSeletor { grid, roleta, botoes }

class _DiaVencimentoSelectorState extends State<DiaVencimentoSelector> {
  int? diaSelecionado;
  TipoSeletor _tipoAtual = TipoSeletor.grid;

  @override
  void initState() {
    super.initState();
    diaSelecionado = widget.initialValue;
    _tipoAtual = widget.tipoSeletor;
  }

  void _alternarTipoSeletor() {
    setState(() {
      _tipoAtual = _tipoAtual == TipoSeletor.grid
          ? TipoSeletor.roleta
          : _tipoAtual == TipoSeletor.roleta
          ? TipoSeletor.botoes
          : TipoSeletor.grid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dia do Vencimento (Opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            // Botão para alternar tipo de seletor
            GestureDetector(
              onTap: _alternarTipoSeletor,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _tipoAtual == TipoSeletor.grid
                          ? Icons.grid_view
                          : _tipoAtual == TipoSeletor.roleta
                          ? Icons.view_carousel
                          : Icons.view_list,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _tipoAtual == TipoSeletor.grid
                          ? 'Grid'
                          : _tipoAtual == TipoSeletor.roleta
                          ? 'Roleta'
                          : 'Lista',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Botão "Sem vencimento"
        if (diaSelecionado == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sem vencimento',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _mostrarSeletorDia(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Escolher dia',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          // Seletor com dia selecionado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[700]!.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Header com dia selecionado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dia $diaSelecionado selecionado',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            diaSelecionado = null;
                          });
                          widget.onChanged(null);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
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
                ),
                const SizedBox(height: 16),

                // Conteúdo do seletor baseado no tipo
                _buildSeletor(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSeletor() {
    switch (_tipoAtual) {
      case TipoSeletor.grid:
        return _buildGridSeletor();
      case TipoSeletor.roleta:
        return _buildRoletaSeletor();
      case TipoSeletor.botoes:
        return _buildBotoesSeletor();
    }
  }

  Widget _buildGridSeletor() {
    return Container(
      height: 200, // Altura fixa para evitar problemas de layout
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemCount: 31,
        itemBuilder: (context, index) {
          final dia = index + 1;
          final isSelected = dia == diaSelecionado;

          return GestureDetector(
            onTap: () => _selecionarDia(dia),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.grey[800]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.6)
                      : Colors.grey[700]!.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  dia.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.blue[300] : Colors.grey[300],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoletaSeletor() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoPicker(
        itemExtent: 40,
        onSelectedItemChanged: (index) {
          _selecionarDia(index + 1);
        },
        children: List.generate(31, (index) {
          final dia = index + 1;
          return Center(
            child: Text(
              'Dia $dia',
              style: TextStyle(
                color: dia == diaSelecionado
                    ? Colors.blue[300]
                    : Colors.grey[300],
                fontWeight: dia == diaSelecionado
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 18,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBotoesSeletor() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(31, (index) {
        final dia = index + 1;
        final isSelected = dia == diaSelecionado;

        return GestureDetector(
          onTap: () => _selecionarDia(dia),
          child: Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.grey[800]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Colors.blue.withOpacity(0.6)
                    : Colors.grey[700]!.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                dia.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.blue[300] : Colors.grey[300],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _selecionarDia(int dia) {
    setState(() {
      diaSelecionado = dia;
    });
    widget.onChanged(dia);
  }

  void _mostrarSeletorDia() {
    // Manter o estado atual mas permitir seleção
    // O usuário pode clicar em qualquer dia para selecionar
  }
}
