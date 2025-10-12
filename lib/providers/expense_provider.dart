import 'package:flutter/foundation.dart';
import '../models/categoria.dart';
import '../models/fonte_renda.dart';
import '../models/despesa.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notification = NotificationService.instance;

  DateTime _mesAtual = DateTime.now();
  List<Categoria> _categorias = [];
  List<FonteRenda> _fontesRenda = [];
  List<Despesa> _despesas = [];
  bool _isLoading = false;

  DateTime get mesAtual => _mesAtual;
  List<Categoria> get categorias => _categorias;
  List<FonteRenda> get fontesRenda => _fontesRenda;
  List<Despesa> get despesas => _despesas;
  bool get isLoading => _isLoading;

  double get totalReceitas {
    return _fontesRenda.fold(0.0, (sum, fonte) => sum + fonte.valor);
  }

  double get totalDespesas {
    return _despesas.fold(0.0, (sum, despesa) => sum + despesa.valor);
  }

  double get saldo {
    return totalReceitas - totalDespesas;
  }

  // Inicialização
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _notification.initialize();
    await _notification.requestPermissions();
    await carregarDados();

    _isLoading = false;
    notifyListeners();
  }

  // Carregar dados do mês atual
  Future<void> carregarDados() async {
    _categorias = await _db.getCategorias();
    _fontesRenda = await _db.getFontesRenda(_mesAtual.month, _mesAtual.year);
    _despesas = await _db.getDespesas(_mesAtual.month, _mesAtual.year);
    notifyListeners();
  }

  // Mudar mês
  void mudarMes(int mes, int ano) {
    _mesAtual = DateTime(ano, mes);
    carregarDados();
  }

  void proximoMes() {
    final novoMes = DateTime(_mesAtual.year, _mesAtual.month + 1);
    mudarMes(novoMes.month, novoMes.year);
  }

  void mesAnterior() {
    final novoMes = DateTime(_mesAtual.year, _mesAtual.month - 1);
    mudarMes(novoMes.month, novoMes.year);
  }

  // Categorias
  Future<void> adicionarCategoria(Categoria categoria) async {
    await _db.createCategoria(categoria);
    await carregarDados();
  }

  Future<void> atualizarCategoria(Categoria categoria) async {
    await _db.updateCategoria(categoria);
    await carregarDados();
  }

  Future<void> deletarCategoria(int id) async {
    await _db.deleteCategoria(id);
    await carregarDados();
  }

  double getGastosPorCategoria(int categoriaId) {
    return _despesas
        .where((d) => d.categoriaId == categoriaId)
        .fold(0.0, (sum, despesa) => sum + despesa.valor);
  }

  // Fontes de Renda
  Future<void> adicionarFonteRenda(FonteRenda fonte) async {
    await _db.createFonteRenda(fonte);
    await carregarDados();
  }

  Future<void> atualizarFonteRenda(FonteRenda fonte) async {
    await _db.updateFonteRenda(fonte);
    await carregarDados();
  }

  Future<void> deletarFonteRenda(int id) async {
    await _db.deleteFonteRenda(id);
    await carregarDados();
  }

  Future<List<String>> getNomesFontesRenda() async {
    return await _db.getNomesFontesRenda();
  }

  Future<List<FonteRenda>> getFontesRendaMes(int mes, int ano) async {
    return await _db.getFontesRenda(mes, ano);
  }

  Future<List<Despesa>> getDespesasMes(int mes, int ano) async {
    return await _db.getDespesas(mes, ano);
  }

  // Despesas
  Future<void> adicionarDespesa(Despesa despesa) async {
    final novaDespesa = await _db.createDespesa(despesa);

    // Agendar notificação se tiver data de vencimento
    if (novaDespesa.diaVencimento != null) {
      try {
        await _notification.agendarNotificacaoVencimento(novaDespesa);
      } catch (e) {
        print('Erro ao agendar notificação: $e');
        // Continua mesmo se a notificação falhar
      }
    }

    await carregarDados();
  }

  Future<void> atualizarDespesa(Despesa despesa) async {
    await _db.updateDespesa(despesa);

    // Reagendar notificação (apenas se tiver permissões)
    if (despesa.id != null) {
      try {
        await _notification.cancelarNotificacao(despesa.id!);
        if (despesa.diaVencimento != null) {
          await _notification.agendarNotificacaoVencimento(despesa);
        }
      } catch (e) {
        // Silenciosamente ignora erros de notificação para não interromper o fluxo
        if (kDebugMode) {
          print(
            'Notificação não foi reagendada (pode ser falta de permissão): $e',
          );
        }
      }
    }

    await carregarDados();
  }

  Future<void> deletarDespesa(int id) async {
    await _notification.cancelarNotificacao(id);
    await _db.deleteDespesa(id);
    await carregarDados();
  }

  Future<void> copiarDespesasFixas(int mesDestino, int anoDestino) async {
    await _db.copiarDespesasFixasParaMes(
      _mesAtual.month,
      _mesAtual.year,
      mesDestino,
      anoDestino,
    );

    // Reagendar notificações para as novas despesas
    final novasDespesas = await _db.getDespesas(mesDestino, anoDestino);
    for (var despesa in novasDespesas) {
      if (despesa.diaVencimento != null) {
        await _notification.agendarNotificacaoVencimento(despesa);
      }
    }

    if (mesDestino == _mesAtual.month && anoDestino == _mesAtual.year) {
      await carregarDados();
    }
  }

  Future<void> copiarDespesasSelecionadas(
    List<Despesa> despesas,
    int mesDestino,
    int anoDestino,
  ) async {
    print(
      'DEBUG: Copiando ${despesas.length} despesas para $mesDestino/$anoDestino',
    );
    print('DEBUG: Mês atual do provider: ${_mesAtual.month}/${_mesAtual.year}');
    print(
      'DEBUG: Despesas a copiar: ${despesas.map((d) => d.descricao).join(", ")}',
    );

    for (var despesa in despesas) {
      final novaDespesa = despesa.copyWith(
        mes: mesDestino,
        ano: anoDestino,
        status: StatusPagamento.aPagar,
        dataCriacao: DateTime.now(),
        clearId: true,
      );

      print(
        'DEBUG: Criando despesa: ${novaDespesa.descricao} - Mês: ${novaDespesa.mes}/${novaDespesa.ano}',
      );
      final despesaCriada = await _db.createDespesa(novaDespesa);

      // Agendar notificação se tiver vencimento
      if (despesaCriada.diaVencimento != null) {
        try {
          await _notification.agendarNotificacaoVencimento(despesaCriada);
        } catch (e) {
          print('Erro ao agendar notificação: $e');
          // Continua mesmo se a notificação falhar
        }
      }
    }

    if (mesDestino == _mesAtual.month && anoDestino == _mesAtual.year) {
      await carregarDados();
    }
  }

  // Obter despesas agrupadas por categoria
  Map<Categoria, List<Despesa>> getDespesasPorCategoria() {
    final Map<Categoria, List<Despesa>> mapa = {};

    for (var categoria in _categorias) {
      final despesasCategoria = _despesas
          .where((d) => d.categoriaId == categoria.id)
          .toList();

      if (despesasCategoria.isNotEmpty) {
        mapa[categoria] = despesasCategoria;
      }
    }

    return mapa;
  }
}
